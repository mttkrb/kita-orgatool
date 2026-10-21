#!/usr/bin/env bash
# Umzug des Kita-Orgatools in ein anderes Supabase-Projekt – Linux und macOS.
# Ausführliche Anleitung: ANLEITUNG.md im selben Ordner.
#
#   ./umzug.sh pruefen               Werkzeuge, Verbindungen und Zielprojekt prüfen
#   ./umzug.sh sichern               Altes Projekt sichern (liest nur, ändert dort nichts)
#   ./umzug.sh einspielen            Letzte Sicherung ins neue Projekt einspielen
#   ./umzug.sh einspielen --ersetzen Dasselbe, vorhandene Tabellen im neuen Projekt ersetzen
#   ./umzug.sh cron                  Zeitgesteuerte Aufträge (pg_cron) übertragen
#   ./umzug.sh vergleichen           Zeilen, Struktur und Rechte alt/neu vergleichen
#   ./umzug.sh alles                 pruefen, sichern, einspielen, vergleichen
#   ./umzug.sh aufraeumen            Sicherungen im Ordner arbeit/ löschen
#
# Läuft auch mit der alten bash 3.2 von macOS.
set -euo pipefail
umask 077

HIER="$(cd "$(dirname "$0")" && pwd)"
ENV_DATEI="${UMZUG_ENV:-$HIER/umzug.env}"
ARBEIT="$HIER/arbeit"

if [ -t 1 ]; then ROT=$'\033[31m'; GRUEN=$'\033[32m'; GELB=$'\033[33m'; FETT=$'\033[1m'; AUS=$'\033[0m'
else ROT=""; GRUEN=""; GELB=""; FETT=""; AUS=""; fi

fehler()  { printf '\n%sFEHLER:%s %s\n' "$ROT" "$AUS" "$*" >&2; exit 1; }
hinweis() { printf '%sHinweis:%s %s\n' "$GELB" "$AUS" "$*"; }
ok()      { printf '%sOK:%s %s\n' "$GRUEN" "$AUS" "$*"; }
schritt() { printf '\n%s== %s ==%s\n' "$FETT" "$*" "$AUS"; }

frage() {  # frage "Text" – bricht ab, wenn nicht mit j beantwortet
  local antwort
  read -r -p "$1 [j/N] " antwort
  case "$antwort" in j|J|ja|Ja|JA) ;; *) fehler "Abgebrochen." ;; esac
}

# ---------- Zugangsdaten ----------

ALT_HOST=""; ALT_PORT=""; ALT_USER=""; ALT_PASSWORT=""
NEU_HOST=""; NEU_PORT=""; NEU_USER=""; NEU_PASSWORT=""
NEU_URL=""; NEU_ANON_KEY=""; PG_DOCKER_IMAGE=""

# Liest umzug.env selbst ein statt sie mit "source" auszuführen, damit Passwörter mit
# $, Leerzeichen oder Anführungszeichen unverändert ankommen.
lade_env() {
  [ -f "$ENV_DATEI" ] || fehler "$ENV_DATEI fehlt. Vorlage kopieren (cp umzug.env.example umzug.env) und ausfüllen."
  local zeile name wert v
  while IFS= read -r zeile || [ -n "$zeile" ]; do
    zeile="${zeile%$'\r'}"
    case "$zeile" in ''|'#'*) continue ;; esac
    case "$zeile" in *=*) ;; *) continue ;; esac
    name="$(printf '%s' "${zeile%%=*}" | tr -d ' \t')"
    wert="${zeile#*=}"
    wert="${wert#"${wert%%[![:space:]]*}"}"
    wert="${wert%"${wert##*[![:space:]]}"}"
    if [ "${#wert}" -ge 2 ]; then
      case "$wert" in \"*\"|\'*\') wert="${wert:1:${#wert}-2}" ;; esac
    fi
    case "$name" in
      ALT_HOST|ALT_PORT|ALT_USER|ALT_PASSWORT|NEU_HOST|NEU_PORT|NEU_USER|NEU_PASSWORT|NEU_URL|NEU_ANON_KEY|PG_DOCKER_IMAGE)
        printf -v "$name" '%s' "$wert" ;;
    esac
  done < "$ENV_DATEI"
  [ -n "$ALT_PORT" ] || ALT_PORT=5432
  [ -n "$NEU_PORT" ] || NEU_PORT=5432
  for v in ALT_HOST ALT_USER ALT_PASSWORT NEU_HOST NEU_USER NEU_PASSWORT; do
    [ -n "${!v}" ] || fehler "$v ist in $(basename "$ENV_DATEI") nicht ausgefüllt."
  done
  [ "$ALT_HOST|$ALT_USER" != "$NEU_HOST|$NEU_USER" ] || fehler "ALT und NEU zeigen auf dasselbe Projekt."
}

# ---------- PostgreSQL-Werkzeuge ----------

MODUS=""        # lokal oder docker
PG_BIN=""       # Ordner mit pg_dump, pg_restore und psql
PG_MAJOR=0      # Hauptversion der lokalen Werkzeuge
DOCKER_IMAGE=""

major_von() { "$1/pg_dump" --version 2>/dev/null | sed -E 's/[^0-9]*([0-9]+).*/\1/'; }

# Sucht die neueste lokale Installation, auch dort, wo Homebrew und Debian sie
# ablegen, ohne dass sie im PATH steht.
finde_werkzeuge() {
  local kandidaten=() d m
  if command -v pg_dump >/dev/null 2>&1; then kandidaten+=("$(dirname "$(command -v pg_dump)")"); fi
  for d in /opt/homebrew/opt/libpq/bin /usr/local/opt/libpq/bin \
           /opt/homebrew/opt/postgresql@*/bin /usr/local/opt/postgresql@*/bin \
           /Applications/Postgres.app/Contents/Versions/*/bin \
           /usr/lib/postgresql/*/bin /usr/pgsql-*/bin; do
    if [ -x "$d/pg_dump" ]; then kandidaten+=("$d"); fi
  done
  for d in ${kandidaten[@]+"${kandidaten[@]}"}; do
    [ -x "$d/psql" ] && [ -x "$d/pg_restore" ] || continue
    m="$(major_von "$d")"
    if [ -n "$m" ] && [ "$m" -gt "$PG_MAJOR" ]; then PG_MAJOR=$m; PG_BIN=$d; fi
  done
}

docker_bereit() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

# pg alt|neu programm [argumente…]
# Führt ein PostgreSQL-Programm mit den Zugangsdaten des alten oder neuen Projekts aus.
# Arbeitsordner ist arbeit/, Dateiangaben also relativ dazu (SQL-Dateien: ../sql/…).
pg() {
  local ziel=$1 prog=$2 host port user pw
  shift 2
  if [ "$ziel" = alt ]; then host=$ALT_HOST; port=$ALT_PORT; user=$ALT_USER; pw=$ALT_PASSWORT
  else host=$NEU_HOST; port=$NEU_PORT; user=$NEU_USER; pw=$NEU_PASSWORT; fi
  if [ "$MODUS" = lokal ]; then
    ( cd "$ARBEIT" && PGHOST=$host PGPORT=$port PGUSER=$user PGPASSWORD=$pw PGDATABASE=postgres \
        PGSSLMODE=require PGCONNECT_TIMEOUT=20 PGAPPNAME=kita-umzug PGCLIENTENCODING=UTF8 \
        "$PG_BIN/$prog" "$@" )
  else
    PGHOST=$host PGPORT=$port PGUSER=$user PGPASSWORD=$pw PGDATABASE=postgres \
      PGSSLMODE=require PGCONNECT_TIMEOUT=20 PGAPPNAME=kita-umzug PGCLIENTENCODING=UTF8 \
      docker run --rm --user "$(id -u):$(id -g)" -v "$HIER:/umzug" -w /umzug/arbeit \
        -e PGHOST -e PGPORT -e PGUSER -e PGPASSWORD -e PGDATABASE -e PGSSLMODE \
        -e PGCONNECT_TIMEOUT -e PGAPPNAME -e PGCLIENTENCODING \
        "$DOCKER_IMAGE" "$prog" "$@"
  fi
}

abfrage()   { pg "$1" psql -X -q -At -v ON_ERROR_STOP=1 -c "$2"; }
sql_datei() { pg "$1" psql -X -q -At -v ON_ERROR_STOP=1 -f "$2"; }

ALT_MAJOR=0; NEU_MAJOR=0

# Wählt die Werkzeuge und fragt die Serverversionen ab. pg_dump muss mindestens die
# Hauptversion des Servers haben; sonst bricht es ab. Fehlt eine passende lokale
# Installation, wird Docker genommen.
bereite_vor() {
  mkdir -p "$ARBEIT"; chmod 700 "$ARBEIT"
  finde_werkzeuge
  if [ -n "$PG_BIN" ]; then MODUS=lokal
  elif docker_bereit; then MODUS=docker; DOCKER_IMAGE="${PG_DOCKER_IMAGE:-postgres:17-alpine}"
  else fehler "Weder PostgreSQL-Werkzeuge (pg_dump, pg_restore, psql) noch Docker gefunden. Siehe ANLEITUNG.md, Abschnitt 2."
  fi

  local v
  v="$(abfrage alt "show server_version_num")" \
    || fehler "Keine Verbindung zum alten Projekt. ALT_HOST, ALT_USER und ALT_PASSWORT prüfen, und ob das Projekt pausiert ist."
  ALT_MAJOR=$(( v / 10000 ))
  v="$(abfrage neu "show server_version_num")" \
    || fehler "Keine Verbindung zum neuen Projekt. NEU_HOST, NEU_USER und NEU_PASSWORT prüfen."
  NEU_MAJOR=$(( v / 10000 ))

  local noetig=$ALT_MAJOR
  if [ "$NEU_MAJOR" -gt "$noetig" ]; then noetig=$NEU_MAJOR; fi
  if [ "$MODUS" = lokal ] && [ "$PG_MAJOR" -lt "$noetig" ]; then
    if docker_bereit; then
      hinweis "Lokale PostgreSQL-Werkzeuge sind Version $PG_MAJOR, gebraucht wird $noetig. Nehme Docker."
      MODUS=docker
    else
      fehler "Die PostgreSQL-Werkzeuge in $PG_BIN sind Version $PG_MAJOR, gebraucht wird mindestens $noetig. Neuere Version installieren (ANLEITUNG.md, Abschnitt 2)."
    fi
  fi
  if [ "$MODUS" = docker ]; then
    if [ "$noetig" -lt 17 ]; then noetig=17; fi
    DOCKER_IMAGE="${PG_DOCKER_IMAGE:-postgres:$noetig-alpine}"
  fi
}

beschreibe_werkzeuge() {
  if [ "$MODUS" = lokal ]; then ok "PostgreSQL-Werkzeuge Version $PG_MAJOR in $PG_BIN"
  else ok "PostgreSQL-Werkzeuge aus Docker ($DOCKER_IMAGE)"; fi
  ok "Altes Projekt erreichbar, Postgres $ALT_MAJOR"
  ok "Neues Projekt erreichbar, Postgres $NEU_MAJOR"
  if [ "$NEU_MAJOR" -lt "$ALT_MAJOR" ]; then
    hinweis "Das neue Projekt hat eine ältere Postgres-Version als das alte. Das Einspielen kann scheitern."
    hinweis "Besser ein neues Projekt mit Version $ALT_MAJOR oder neuer anlegen."
  fi
}

# Tabellen im Schema public, ohne solche, die zu Erweiterungen gehören.
tabellen_neu() {
  abfrage neu "select coalesce(string_agg(c.relname, ', ' order by c.relname), '')
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r','p','v','m')
      and not exists (select 1 from pg_depend d where d.classid = 'pg_class'::regclass
                      and d.objid = c.oid and d.deptype = 'e')"
}

erweiterungen() {
  abfrage "$1" "select coalesce(string_agg(extname, ' ' order by extname), '') from pg_extension"
}

hat_cron() {  # hat_cron alt|neu – gibt t oder f aus
  abfrage "$1" "select to_regclass('cron.job') is not null"
}

letzte_sicherung() {
  [ -f "$ARBEIT/letzte-sicherung" ] || fehler "Noch keine Sicherung vorhanden. Erst ./umzug.sh sichern ausführen."
  BASIS="$(cat "$ARBEIT/letzte-sicherung")"
  [ -f "$ARBEIT/$BASIS.dump" ] || fehler "Sicherung $ARBEIT/$BASIS.dump fehlt."
}

# ---------- Schritte ----------

cmd_pruefen() {
  schritt "Prüfen"
  beschreibe_werkzeuge

  local tabellen
  tabellen="$(tabellen_neu)"
  if [ -n "$tabellen" ]; then
    hinweis "Im neuen Projekt gibt es schon Tabellen: $tabellen"
    hinweis "Einspielen geht dann nur mit: ./umzug.sh einspielen --ersetzen"
  else
    ok "Neues Projekt ist leer"
  fi

  local alt_ext neu_ext e fehlend=""
  alt_ext="$(erweiterungen alt)"; neu_ext="$(erweiterungen neu)"
  for e in $alt_ext; do
    case " $neu_ext " in *" $e "*) ;; *) fehlend="$fehlend $e" ;; esac
  done
  if [ -n "$fehlend" ]; then
    hinweis "Diese Erweiterungen sind im alten, aber nicht im neuen Projekt aktiv:$fehlend"
    hinweis "Im neuen Projekt unter Database → Extensions einschalten (pg_cron übernimmt ./umzug.sh cron)."
  else
    ok "Alle Erweiterungen des alten Projekts sind auch im neuen aktiv"
  fi

  if [ "$(hat_cron alt)" = t ]; then
    local n
    n="$(abfrage alt "select count(*) from cron.job where active and database = current_database()")"
    ok "Altes Projekt hat $n aktive(n) Cron-Auftrag/Aufträge; sie werden mit übertragen"
  fi

  echo
  echo "Zeilen im alten Projekt:"
  sql_datei alt ../sql/zeilen.sql | sed 's/|/: /; s/^/  /'
}

cmd_sichern() {
  schritt "Altes Projekt sichern"
  local stamp basis vorher nachher
  stamp="$(date +%Y%m%d-%H%M%S)"
  basis="alt_$stamp"

  vorher="$(sql_datei alt ../sql/zeilen.sql)" || fehler "Zeilen im alten Projekt nicht lesbar."
  pg alt pg_dump --format=custom --schema=public --schema=intern \
      --no-publications --no-subscriptions --no-security-labels \
      --file="$basis.dump" \
    || fehler "pg_dump ist gescheitert, siehe Meldung oben."
  sql_datei alt ../sql/struktur.sql > "$ARBEIT/$basis.struktur.txt" || fehler "Struktur nicht lesbar."
  nachher="$(sql_datei alt ../sql/zeilen.sql)" || fehler "Zeilen im alten Projekt nicht lesbar."
  printf '%s\n' "$nachher" > "$ARBEIT/$basis.zeilen.txt"

  if [ "$(hat_cron alt)" = t ]; then
    sql_datei alt ../sql/cron-export.sql > "$ARBEIT/$basis.cron.sql" || fehler "Cron-Aufträge nicht lesbar."
  fi
  printf '%s\n' "$basis" > "$ARBEIT/letzte-sicherung"

  if [ "$vorher" != "$nachher" ]; then
    hinweis "Während der Sicherung hat sich im alten Projekt etwas geändert."
    hinweis "Sind die Anmeldungen wirklich gestoppt? Sonst ./umzug.sh sichern noch einmal ausführen."
  fi
  ok "Gesichert nach arbeit/$basis.dump"
  printf '%s\n' "$nachher" | sed 's/|/: /; s/^/  /'
}

cmd_einspielen() {
  local ersetzen=0
  if [ "${1:-}" = "--ersetzen" ]; then ersetzen=1; fi
  schritt "In das neue Projekt einspielen"
  letzte_sicherung
  echo "Sicherung: arbeit/$BASIS.dump"

  local tabellen
  tabellen="$(tabellen_neu)"
  if [ -n "$tabellen" ]; then
    [ "$ersetzen" = 1 ] || fehler "Im neuen Projekt gibt es schon Tabellen: $tabellen
Wenn das ein früherer Versuch war: ./umzug.sh einspielen --ersetzen"
    frage "Im NEUEN Projekt werden diese Tabellen samt Inhalt ersetzt: $tabellen. Weiter?"
  fi

  # Inhaltsverzeichnis der Sicherung in zwei Teile: alles außer Rechten, und die Rechte.
  # Weggelassen werden das Schema public selbst und Erweiterungen, die Supabase
  # im neuen Projekt schon mitbringt, sowie Standardrechte für künftige Tabellen.
  pg neu pg_restore --list --file=inhalt.list "$BASIS.dump" || fehler "Sicherung nicht lesbar."
  grep -v -E '^[0-9]+; [0-9]+ [0-9]+ (DEFAULT ACL|ACL) | SCHEMA - public |COMMENT - SCHEMA public| EXTENSION ' \
    "$ARBEIT/inhalt.list" > "$ARBEIT/haupt.list" || true
  grep -E '^[0-9]+; [0-9]+ [0-9]+ ACL ' "$ARBEIT/inhalt.list" \
    | grep -v -E 'SCHEMA public' > "$ARBEIT/rechte.list" || true

  local clean=()
  if [ "$ersetzen" = 1 ]; then clean=(--clean --if-exists); fi

  echo "Tabellen, Funktionen, Policies und Daten …"
  pg neu pg_restore --dbname=postgres --no-owner --single-transaction --exit-on-error \
      ${clean[@]+"${clean[@]}"} --use-list=haupt.list "$BASIS.dump" \
    || fehler "Einspielen gescheitert, im neuen Projekt wurde nichts geändert. Meldung oben lesen."
  ok "Tabellen, Funktionen, Policies und Daten eingespielt"

  echo "Rechte …"
  sql_datei neu ../sql/rechte-leeren.sql || fehler "Standardrechte ließen sich nicht entfernen."
  if pg neu pg_restore --dbname=postgres --no-owner --use-list=rechte.list "$BASIS.dump"; then
    ok "Rechte wie im alten Projekt gesetzt"
  else
    hinweis "Einige Rechte ließen sich nicht setzen (Meldungen oben). Der Vergleich zeigt, welche fehlen."
  fi

  # Supabase-API die neuen Tabellen sofort bekannt machen
  abfrage neu "notify pgrst, 'reload schema'" >/dev/null || true

  cmd_cron
  cmd_vergleichen
}

cmd_cron() {
  schritt "Zeitgesteuerte Aufträge (pg_cron)"
  letzte_sicherung
  local datei="$BASIS.cron.sql"
  if [ ! -s "$ARBEIT/$datei" ]; then
    ok "Im alten Projekt gab es keine aktiven Cron-Aufträge"
    return 0
  fi
  if [ "$(hat_cron neu)" != t ]; then
    if ! abfrage neu "create extension if not exists pg_cron with schema pg_catalog" >/dev/null; then
      hinweis "pg_cron ließ sich im neuen Projekt nicht einschalten."
      hinweis "Im Supabase-Dashboard unter Database → Extensions pg_cron einschalten, dann ./umzug.sh cron"
      return 0
    fi
  fi
  sql_datei neu "$datei" >/dev/null || { hinweis "Cron-Aufträge ließen sich nicht anlegen, siehe Meldung oben."; return 0; }
  ok "Cron-Aufträge im neuen Projekt:"
  abfrage neu "select jobname || '  ' || schedule || '  ' || command from cron.job order by jobid" | sed 's/^/  /'
}

# Test über die REST-API mit dem anonKey, so wie die Seiten zugreifen.
api_test() {
  if [ -z "$NEU_URL" ] || [ -z "$NEU_ANON_KEY" ]; then
    hinweis "NEU_URL und NEU_ANON_KEY sind nicht gesetzt, Test über die Schnittstelle übersprungen."
    return 0
  fi
  command -v curl >/dev/null 2>&1 || { hinweis "curl fehlt, Test über die Schnittstelle übersprungen."; return 0; }
  local basis="${NEU_URL%/}/rest/v1" antwort="$ARBEIT/api-antwort.txt" code t fehlt=0
  holen() {
    curl -sS -o "$antwort" -w '%{http_code}' --max-time 20 \
      -H "apikey: $NEU_ANON_KEY" -H "Authorization: Bearer $NEU_ANON_KEY" "$@" || echo 000
  }

  code="$(holen "$basis/events?select=id&limit=1")"
  if [ "$code" = 200 ]; then ok "Veranstaltungen lesbar"
  else printf '%sFEHLT:%s Veranstaltungen nicht lesbar (HTTP %s)\n' "$ROT" "$AUS" "$code"; fehlt=1; fi

  code="$(holen "$basis/signups?select=id,name&limit=1")"
  if [ "$code" != 200 ] || [ "$(cat "$antwort")" = "[]" ]; then ok "Anmeldungen ohne Token nicht lesbar"
  else printf '%sGEFAHR:%s Anmeldungen sind für jeden lesbar! Rechte prüfen, Seiten NICHT umstellen.\n' "$ROT" "$AUS"; fehlt=1; fi

  code="$(holen "$basis/signups?select=token&limit=1")"
  if [ "$code" != 200 ]; then ok "Spalte signups.token ist gesperrt"
  else printf '%sGEFAHR:%s signups.token ist für jeden lesbar! Rechte prüfen, Seiten NICHT umstellen.\n' "$ROT" "$AUS"; fehlt=1; fi

  for t in orga_keys templates planning feedback payments receipts; do
    code="$(holen "$basis/$t?select=*&limit=1")"
    if [ "$code" != 200 ] || [ "$(cat "$antwort")" = "[]" ]; then ok "$t ohne Orga-Passwort nicht lesbar"
    else printf '%sGEFAHR:%s %s liefert ohne Orga-Passwort Daten!\n' "$ROT" "$AUS" "$t"; fehlt=1; fi
  done

  code="$(holen -X POST -H "Content-Type: application/json" -H "X-Orga-Key: falsches-passwort-zum-test" \
          -d '{}' "$basis/rpc/is_orga")"
  if [ "$code" = 200 ] && [ "$(cat "$antwort")" = "false" ]; then ok "Falsches Orga-Passwort wird abgelehnt"
  else printf '%sFEHLT:%s is_orga() antwortet nicht wie erwartet (HTTP %s)\n' "$ROT" "$AUS" "$code"; fehlt=1; fi

  rm -f "$antwort"
  return $fehlt
}

cmd_vergleichen() {
  schritt "Vergleichen"
  letzte_sicherung
  local probleme=0 jetzt_alt

  sql_datei neu ../sql/zeilen.sql > "$ARBEIT/neu.zeilen.txt" || fehler "Zeilen im neuen Projekt nicht lesbar."
  sql_datei neu ../sql/struktur.sql > "$ARBEIT/neu.struktur.txt" || fehler "Struktur im neuen Projekt nicht lesbar."

  if diff -u "$ARBEIT/$BASIS.zeilen.txt" "$ARBEIT/neu.zeilen.txt" > "$ARBEIT/diff.txt"; then
    ok "Zeilenzahlen stimmen mit der Sicherung überein"
  else
    printf '%sABWEICHUNG%s bei den Zeilen (- Sicherung, + neues Projekt):\n' "$ROT" "$AUS"
    grep -E '^[-+][^-+]' "$ARBEIT/diff.txt" | sed 's/^/  /'
    probleme=1
  fi

  if diff -u "$ARBEIT/$BASIS.struktur.txt" "$ARBEIT/neu.struktur.txt" > "$ARBEIT/diff.txt"; then
    ok "Tabellen, Spalten, Policies, Funktionen und Rechte stimmen überein"
  else
    printf '%sABWEICHUNG%s bei Struktur oder Rechten (- altes Projekt, + neues Projekt):\n' "$ROT" "$AUS"
    grep -E '^[-+][^-+]' "$ARBEIT/diff.txt" | sed 's/^/  /'
    probleme=1
  fi
  rm -f "$ARBEIT/diff.txt"

  # Ist im alten Projekt seit der Sicherung noch etwas dazugekommen?
  if jetzt_alt="$(sql_datei alt ../sql/zeilen.sql 2>/dev/null)"; then
    if [ "$jetzt_alt" != "$(cat "$ARBEIT/$BASIS.zeilen.txt")" ]; then
      hinweis "Im alten Projekt hat sich seit der Sicherung etwas geändert."
      hinweis "Dann noch einmal: ./umzug.sh sichern und ./umzug.sh einspielen --ersetzen"
      probleme=1
    fi
  fi

  api_test || probleme=1

  echo
  if [ "$probleme" = 0 ]; then
    ok "Umzug vollständig. Weiter mit Abschnitt 6 der Anleitung (config.js umstellen)."
  else
    printf '%sEs gibt Abweichungen.%s Seiten erst umstellen, wenn sie geklärt sind (ANLEITUNG.md, Abschnitt 8).\n' "$ROT" "$AUS"
    return 1
  fi
}

cmd_aufraeumen() {
  schritt "Aufräumen"
  [ -d "$ARBEIT" ] || { ok "Nichts zu löschen"; return 0; }
  echo "Im Ordner arbeit/ liegen Sicherungen mit allen Anmeldungen und dem Orga-Passwort:"
  ls -1 "$ARBEIT" | sed 's/^/  /'
  frage "Ordner arbeit/ endgültig löschen?"
  rm -rf "$ARBEIT"
  ok "Gelöscht"
}

cmd_alles() {
  cmd_pruefen
  echo
  echo "Während des Umzugs dürfen sich keine Eltern anmelden, sonst gehen diese Einträge verloren."
  frage "Sind die Anmeldungen gestoppt und soll der Umzug jetzt laufen?"
  cmd_sichern
  cmd_einspielen "${1:-}"
}

hilfe() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; }

aufgabe="${1:-hilfe}"
if [ $# -gt 0 ]; then shift; fi
case "$aufgabe" in
  pruefen|sichern|einspielen|cron|vergleichen|alles)
    lade_env; bereite_vor
    [ "$aufgabe" = pruefen ] || beschreibe_werkzeuge
    "cmd_$aufgabe" "$@" ;;
  aufraeumen) cmd_aufraeumen ;;
  hilfe|-h|--help) hilfe ;;
  *) hilfe; exit 1 ;;
esac
