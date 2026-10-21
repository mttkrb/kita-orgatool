#!/usr/bin/env bash
# Erzeugt aus einem laufenden Supabase-Projekt die Vorlage für Neuinstallationen:
#
#   sql/neuinstallation.sql   Tabellen, Funktionen, Policies, Rechte, Cron, Orga-Passwort
#   sql/pruefen.sql           Prüft ein neu eingerichtetes Projekt gegen die Vorlage
#
# Gelesen wird nur die Struktur der Schemas public und intern, keine Daten: keine
# Anmeldungen, keine Veranstaltungen, kein Orga-Passwort. Das Quellprojekt wird nicht verändert.
# Ausführliche Anleitung: ANLEITUNG.md im selben Ordner, Abschnitt "Für Betreuer".
#
#   ./vorlage-erzeugen.sh            Vorlage erzeugen
#   ./vorlage-erzeugen.sh aufraeumen Arbeitsordner arbeit/ löschen
#
# Läuft auch mit der alten bash 3.2 von macOS. Unter Windows über WSL oder Git Bash.
set -euo pipefail
umask 077

HIER="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HIER/.." && pwd)"
ENV_DATEI="${VORLAGE_ENV:-$HIER/vorlage.env}"
ARBEIT="$HIER/arbeit"
ZIEL="$HIER/sql"
UMZUG_SQL="../../umzug/sql"   # relativ zu arbeit/
# Was Supabase in neuen Projekten selbst anlegt. Gehört nicht in die Vorlage, sonst
# scheitert dort "create function" und die ganze Neuinstallation wird zurückgerollt.
# pruefen.sql übergeht es ebenfalls, ob es im neuen Projekt vorhanden ist oder nicht.
SUPABASE_EIGENES='rls_auto_enable'

if [ -t 1 ]; then ROT=$'\033[31m'; GRUEN=$'\033[32m'; GELB=$'\033[33m'; FETT=$'\033[1m'; AUS=$'\033[0m'
else ROT=""; GRUEN=""; GELB=""; FETT=""; AUS=""; fi

fehler()  { printf '\n%sFEHLER:%s %s\n' "$ROT" "$AUS" "$*" >&2; exit 1; }
hinweis() { printf '%sHinweis:%s %s\n' "$GELB" "$AUS" "$*"; }
ok()      { printf '%sOK:%s %s\n' "$GRUEN" "$AUS" "$*"; }
schritt() { printf '\n%s== %s ==%s\n' "$FETT" "$*" "$AUS"; }

# ---------- Zugangsdaten ----------

QUELLE_HOST=""; QUELLE_PORT=""; QUELLE_USER=""; QUELLE_PASSWORT=""; PG_DOCKER_IMAGE=""

# Liest vorlage.env selbst ein statt sie mit "source" auszuführen, damit Passwörter mit
# $, Leerzeichen oder Anführungszeichen unverändert ankommen.
lade_env() {
  [ -f "$ENV_DATEI" ] || fehler "$ENV_DATEI fehlt. Vorlage kopieren (cp vorlage.env.example vorlage.env) und ausfüllen."
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
      QUELLE_HOST|QUELLE_PORT|QUELLE_USER|QUELLE_PASSWORT|PG_DOCKER_IMAGE)
        printf -v "$name" '%s' "$wert" ;;
    esac
  done < "$ENV_DATEI"
  [ -n "$QUELLE_PORT" ] || QUELLE_PORT=5432
  for v in QUELLE_HOST QUELLE_USER QUELLE_PASSWORT; do
    [ -n "${!v}" ] || fehler "$v ist in $(basename "$ENV_DATEI") nicht ausgefüllt."
  done
}

# ---------- PostgreSQL-Werkzeuge (wie umzug/umzug.sh) ----------

MODUS=""; PG_BIN=""; PG_MAJOR=0; DOCKER_IMAGE=""

major_von() { "$1/pg_dump" --version 2>/dev/null | sed -E 's/[^0-9]*([0-9]+).*/\1/'; }

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

# pg programm [argumente…] – Arbeitsordner ist arbeit/, Dateiangaben relativ dazu.
pg() {
  local prog=$1
  shift
  if [ "$MODUS" = lokal ]; then
    ( cd "$ARBEIT" && PGHOST=$QUELLE_HOST PGPORT=$QUELLE_PORT PGUSER=$QUELLE_USER \
        PGPASSWORD=$QUELLE_PASSWORT PGDATABASE=postgres PGSSLMODE=require PGCONNECT_TIMEOUT=20 \
        PGAPPNAME=kita-vorlage PGCLIENTENCODING=UTF8 "$PG_BIN/$prog" "$@" )
  else
    PGHOST=$QUELLE_HOST PGPORT=$QUELLE_PORT PGUSER=$QUELLE_USER PGPASSWORD=$QUELLE_PASSWORT \
      PGDATABASE=postgres PGSSLMODE=require PGCONNECT_TIMEOUT=20 PGAPPNAME=kita-vorlage \
      PGCLIENTENCODING=UTF8 \
      docker run --rm --user "$(id -u):$(id -g)" -v "$REPO:/repo" -w /repo/einrichtung/arbeit \
        -e PGHOST -e PGPORT -e PGUSER -e PGPASSWORD -e PGDATABASE -e PGSSLMODE \
        -e PGCONNECT_TIMEOUT -e PGAPPNAME -e PGCLIENTENCODING \
        "$DOCKER_IMAGE" "$prog" "$@"
  fi
}

abfrage()   { pg psql -X -q -At -v ON_ERROR_STOP=1 -c "$1"; }
sql_datei() { pg psql -X -q -At -v ON_ERROR_STOP=1 -f "$1"; }

bereite_vor() {
  mkdir -p "$ARBEIT"; chmod 700 "$ARBEIT"
  finde_werkzeuge
  if [ -n "$PG_BIN" ]; then MODUS=lokal
  elif docker_bereit; then MODUS=docker; DOCKER_IMAGE="${PG_DOCKER_IMAGE:-postgres:17-alpine}"
  else fehler "Weder PostgreSQL-Werkzeuge (pg_dump, pg_restore, psql) noch Docker gefunden. Siehe umzug/ANLEITUNG.md, Abschnitt 2."
  fi

  local v noetig
  v="$(abfrage "show server_version_num")" \
    || fehler "Keine Verbindung zum Quellprojekt. QUELLE_HOST, QUELLE_USER und QUELLE_PASSWORT prüfen, und ob das Projekt pausiert ist."
  noetig=$(( v / 10000 ))
  QUELLE_MAJOR=$noetig
  if [ "$MODUS" = lokal ] && [ "$PG_MAJOR" -lt "$noetig" ]; then
    if docker_bereit; then
      hinweis "Lokale PostgreSQL-Werkzeuge sind Version $PG_MAJOR, gebraucht wird $noetig. Nehme Docker."
      MODUS=docker
    else
      fehler "Die PostgreSQL-Werkzeuge in $PG_BIN sind Version $PG_MAJOR, gebraucht wird mindestens $noetig."
    fi
  fi
  if [ "$MODUS" = docker ]; then
    if [ "$noetig" -lt 17 ]; then noetig=17; fi
    DOCKER_IMAGE="${PG_DOCKER_IMAGE:-postgres:$noetig-alpine}"
    ok "PostgreSQL-Werkzeuge aus Docker ($DOCKER_IMAGE)"
  else
    ok "PostgreSQL-Werkzeuge Version $PG_MAJOR in $PG_BIN"
  fi
  ok "Quellprojekt erreichbar, Postgres $QUELLE_MAJOR"
}

# Entfernt aus Skripten von pg_dump/pg_restore, was der SQL-Editor von Supabase nicht
# versteht: psql-Befehle wie \restrict (ab pg_dump 17.6) und Einstellungen, die es erst
# in neueren Postgres-Versionen gibt.
fuer_sql_editor() {
  sed -E -e '/^\\/d' -e '/^SET transaction_timeout/d' "$1"
}

# ---------- Vorlage erzeugen ----------

cmd_erzeugen() {
  schritt "Struktur des Quellprojekts lesen"
  local stamp orga_spalten cron
  stamp="$(date '+%Y-%m-%d %H:%M')"

  pg pg_dump --format=custom --schema=public --schema=intern --schema-only \
      --no-publications --no-subscriptions --no-security-labels \
      --file=schema.dump \
    || fehler "pg_dump ist gescheitert, siehe Meldung oben."
  ok "Struktur gelesen (ohne Daten)"

  # Wie beim Umzug: Schema public und Erweiterungen bringt Supabase mit, Rechte kommen
  # getrennt, damit vorher die Standardrechte von Supabase entfernt werden können.
  pg pg_restore --list --file=inhalt.list schema.dump || fehler "Sicherung nicht lesbar."
  grep -v -E '^[0-9]+; [0-9]+ [0-9]+ (DEFAULT ACL|ACL) | SCHEMA - public |COMMENT - SCHEMA public| EXTENSION ' \
    "$ARBEIT/inhalt.list" | grep -v -E "$SUPABASE_EIGENES" > "$ARBEIT/haupt.list" || true
  grep -E '^[0-9]+; [0-9]+ [0-9]+ ACL ' "$ARBEIT/inhalt.list" \
    | grep -v -E "SCHEMA public|$SUPABASE_EIGENES" > "$ARBEIT/rechte.list" || true
  pg pg_restore --no-owner --use-list=haupt.list --file=haupt.sql schema.dump \
    || fehler "Struktur ließ sich nicht als SQL schreiben."
  pg pg_restore --no-owner --use-list=rechte.list --file=rechte.sql schema.dump \
    || fehler "Rechte ließen sich nicht als SQL schreiben."

  abfrage "select format('create extension if not exists %I with schema %I;', e.extname, n.nspname)
             from pg_extension e join pg_namespace n on n.oid = e.extnamespace
            where e.extname <> 'plpgsql' order by e.extname" > "$ARBEIT/erweiterungen.sql" \
    || fehler "Erweiterungen nicht lesbar."

  cron=f
  if [ "$(abfrage "select to_regclass('cron.job') is not null")" = t ]; then
    sql_datei "$UMZUG_SQL/cron-export.sql" > "$ARBEIT/cron.sql" || fehler "Cron-Aufträge nicht lesbar."
    [ -s "$ARBEIT/cron.sql" ] && cron=t
  fi
  if [ "$cron" = t ]; then ok "Cron-Aufträge gelesen"
  else hinweis "Im Quellprojekt gibt es keine aktiven Cron-Aufträge; daten_aufraeumen() läuft dann nicht von selbst."; fi

  sql_datei "$UMZUG_SQL/struktur.sql" | grep -v -E "$SUPABASE_EIGENES" > "$ARBEIT/struktur.txt" \
    || fehler "Struktur nicht lesbar."

  orga_spalten="$(abfrage "select string_agg(column_name, ' ' order by column_name)
      from information_schema.columns where table_schema = 'public' and table_name = 'orga_keys'")"
  [ -n "$orga_spalten" ] || fehler "Im Quellprojekt gibt es keine Tabelle orga_keys."

  schritt "Vorlage schreiben"
  mkdir -p "$ZIEL"
  schreibe_neuinstallation "$stamp" "$orga_spalten" "$cron" > "$ZIEL/neuinstallation.sql"
  ok "sql/neuinstallation.sql ($(wc -c < "$ZIEL/neuinstallation.sql" | tr -d ' ') Bytes)"
  schreibe_pruefen "$stamp" "$cron" > "$ZIEL/pruefen.sql"
  ok "sql/pruefen.sql"

  pruefe_auf_geheimnisse
  rm -f "$ARBEIT"/schema.dump "$ARBEIT"/*.list "$ARBEIT"/*.sql "$ARBEIT"/*.txt

  echo
  echo "Vor dem Commit mit git diff durchsehen, besonders die Cron-Aufträge am Ende von"
  echo "neuinstallation.sql. Dann committen, damit die nächste Neuinstallation diesen Stand hat."
}

# Legt das Orga-Passwort an, passend zu den Spalten, die orga_keys im Quellprojekt hat.
# Das Passwort erzeugt die Datenbank selbst; es steht damit nie im Verlauf des SQL-Editors.
orga_passwort_sql() {
  local spalten=" $1 " cols="" vals=""
  case "$spalten" in *" secret "*) cols="secret"; vals="passwort" ;; esac
  case "$spalten" in *" key_hash "*) cols="${cols:+$cols, }key_hash"; vals="${vals:+$vals, }extensions.digest(passwort, 'sha256')" ;; esac
  [ -n "$cols" ] || fehler "orga_keys hat weder secret noch key_hash (Spalten: $1). Skript anpassen."
  case "$spalten" in *" label "*) cols="$cols, label"; vals="$vals, 'Orgateam'" ;; esac
  cat <<EOF
create temporary table neues_orga_passwort as
  select translate(encode(extensions.gen_random_bytes(24), 'base64'), '+/', '-_') as passwort;
insert into public.orga_keys ($cols)
  select $vals from pg_temp.neues_orga_passwort;
EOF
}

schreibe_neuinstallation() {
  local stamp=$1 orga_spalten=$2 cron=$3
  cat <<EOF
-- =====================================================================
--  Kita-Orgatool – Neuinstallation
--
--  Einmal vollständig im SQL-Editor eines NEUEN, LEEREN Supabase-Projekts
--  ausführen (SQL Editor -> New query -> einfügen -> Run).
--  Anleitung: einrichtung/ANLEITUNG.md
--
--  Legt alle Tabellen, Funktionen, Policies, Rechte und Cron-Aufträge an und
--  erzeugt ein neues Orga-Passwort. Das Ergebnis unten zeigt das Passwort
--  genau einmal: sofort in den Passwortsafe des Vereins übernehmen.
--
--  Läuft in einer Transaktion: Bei einem Fehler wird nichts angelegt.
--  Enthält keine Daten.
--
--  Erzeugt am $stamp mit einrichtung/vorlage-erzeugen.sh
--  aus einem Projekt mit Postgres $QUELLE_MAJOR. Nicht von Hand ändern.
-- =====================================================================

begin;

do \$\$
begin
  if to_regclass('public.events') is not null then
    raise exception 'In diesem Projekt gibt es schon Tabellen des Orgatools. Die Neuinstallation ist nur für leere Projekte. Für Updates die migration-Dateien nehmen.';
  end if;
end \$\$;

-- ---------------------------------------------------------------------
-- 1. Erweiterungen (die meisten bringt Supabase schon mit)
-- ---------------------------------------------------------------------
EOF
  if [ "$cron" != t ]; then grep -v ' pg_cron ' "$ARBEIT/erweiterungen.sql" || true
  else cat "$ARBEIT/erweiterungen.sql"; fi
  cat <<'EOF'

-- ---------------------------------------------------------------------
-- 2. Tabellen, Funktionen, Policies, Trigger
-- ---------------------------------------------------------------------
EOF
  fuer_sql_editor "$ARBEIT/haupt.sql"
  cat <<'EOF'

-- ---------------------------------------------------------------------
-- 3. Rechte
--    Supabase gibt neuen Tabellen von sich aus alle Rechte für anon, damit
--    wäre unter anderem signups.token für jeden lesbar. Deshalb erst alle
--    Rechte entfernen, dann genau die Rechte der Vorlage setzen.
-- ---------------------------------------------------------------------
EOF
  sed -n '/^do \$\$/,$p' "$REPO/umzug/sql/rechte-leeren.sql"
  echo
  fuer_sql_editor "$ARBEIT/rechte.sql"
  if [ "$cron" = t ]; then
    cat <<'EOF'

-- ---------------------------------------------------------------------
-- 4. Zeitgesteuerte Aufträge (pg_cron), z. B. das nächtliche Aufräumen
-- ---------------------------------------------------------------------
EOF
    cat "$ARBEIT/cron.sql"
  fi
  cat <<'EOF'

-- ---------------------------------------------------------------------
-- 5. Orga-Passwort
-- ---------------------------------------------------------------------
EOF
  orga_passwort_sql "$orga_spalten"
  cat <<'EOF'

commit;

-- Schnittstelle die neuen Tabellen sofort bekannt machen
notify pgrst, 'reload schema';

-- Das neue Orga-Passwort. Erscheint nur hier und nur jetzt.
select passwort as "Orga-Passwort – jetzt in den Passwortsafe übernehmen"
from pg_temp.neues_orga_passwort;
EOF
}

schreibe_pruefen() {
  local stamp=$1 cron=$2
  cat <<EOF
-- =====================================================================
--  Kita-Orgatool – Neuinstallation prüfen
--
--  Nach neuinstallation.sql im SQL-Editor ausführen. Jede Zeile beginnt mit
--  OK, FEHLT, ZUVIEL oder GEFAHR. Bei GEFAHR die Seiten nicht freigeben.
--
--  Vergleicht Tabellen, Spalten, Policies, Funktionen und Rechte mit dem
--  Projekt, aus dem die Vorlage stammt (nur Namen und Prüfsummen).
--  Erzeugt am $stamp mit einrichtung/vorlage-erzeugen.sh. Nicht von Hand ändern.
-- =====================================================================

with soll(zeile) as (values
EOF
  sed -e "s/'/''/g" -e "s/^/  ('/" -e "s/\$/'),/" "$ARBEIT/struktur.txt" | sed '$ s/),$/))/'
  echo ", ist_alles(zeile) as ("
  sed -e '/^--/d' -e 's/;[[:space:]]*$//' "$REPO/umzug/sql/struktur.sql" | sed 's/^/  /'
  echo "), ist as ("
  echo "  select zeile from ist_alles where zeile !~ '$SUPABASE_EIGENES'"
  cat <<'EOF'
), fehlt as (
  select zeile from soll except select zeile from ist
), zuviel as (
  select zeile from ist except select zeile from soll
)
select ergebnis from (
  select 1 as nr, 'FEHLT: ' || zeile as ergebnis from fehlt
  union all
  select 2, 'ZUVIEL: ' || zeile from zuviel
  union all
  select 3, 'OK: Tabellen, Spalten, Policies, Funktionen und Rechte wie in der Vorlage'
  where not exists (select 1 from fehlt) and not exists (select 1 from zuviel)
  union all
  select 4, case when has_column_privilege('anon', 'public.signups', 'token', 'SELECT')
                 then 'GEFAHR: signups.token ist für jeden lesbar'
                 else 'OK: signups.token ist gesperrt' end
  union all
  select 5, case when has_table_privilege('anon', 'public.orga_keys', 'SELECT')
                 then 'GEFAHR: orga_keys ist für jeden lesbar'
                 else 'OK: orga_keys ist gesperrt' end
  union all
  select 6, case when (select count(*) from public.orga_keys) > 0
                 then 'OK: Orga-Passwort angelegt'
                 else 'FEHLT: kein Orga-Passwort in orga_keys' end
EOF
  if [ "$cron" = t ]; then
    cat <<'EOF'
  union all
  select 7, case when (select count(*) from cron.job where active) > 0
                 then 'OK: ' || (select count(*) from cron.job where active) || ' Cron-Auftrag/Aufträge aktiv'
                 else 'FEHLT: kein aktiver Cron-Auftrag, daten_aufraeumen() läuft nicht' end
EOF
  fi
  cat <<'EOF'
) z
order by nr, ergebnis;
EOF
}

# Die Vorlage wird committet. Sie darf keine Schlüssel oder Adressen enthalten, etwa
# aus einem Cron-Auftrag, der eine URL mit Schlüssel aufruft.
pruefe_auf_geheimnisse() {
  local treffer
  treffer="$(grep -n -E 'eyJ[A-Za-z0-9_-]{10,}|sb_(secret|publishable)_|service_role_key|[a-z0-9]{20}\.supabase\.co|password|passwort *=' \
               "$ZIEL/neuinstallation.sql" | grep -v -E '^[0-9]+:--' || true)"
  if [ -n "$treffer" ]; then
    hinweis "Die Vorlage enthält Stellen, die nach Schlüsseln oder Adressen aussehen:"
    printf '%s\n' "$treffer" | cut -c1-160 | sed 's/^/  /'
    hinweis "Vor dem Commit prüfen und gegebenenfalls den Cron-Auftrag im Quellprojekt ändern."
  else
    ok "Keine Schlüssel oder Projektadressen in der Vorlage gefunden"
  fi
}

cmd_aufraeumen() {
  rm -rf "$ARBEIT"
  ok "Arbeitsordner gelöscht"
}

hilfe() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-erzeugen}" in
  erzeugen) lade_env; bereite_vor; cmd_erzeugen ;;
  aufraeumen) cmd_aufraeumen ;;
  hilfe|-h|--help) hilfe ;;
  *) hilfe; exit 1 ;;
esac
