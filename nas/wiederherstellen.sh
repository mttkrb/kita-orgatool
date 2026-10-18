#!/bin/sh
# Spielt eine Sicherung von backup.sh in ein Supabase-Projekt ein und ersetzt dort
# alle Tabellen, Funktionen und Daten in den Schemas public und intern.
#
#   sh wiederherstellen.sh sicherungen/supabase-20261018-030000.dump
#
# Ziel ist das Projekt aus der Datei pgpass neben diesem Skript (Aufbau wie bei
# backup.sh). Für ein anderes Projekt, etwa ein leeres Testprojekt oder ein neues
# nach Verlust des alten, eine eigene pgpass daneben legen oder PGPASSFILE setzen.
# Läuft auf einem Rechner mit dem Repo, weil es umzug/sql/rechte-leeren.sql braucht.
#
# Die Rechte werden wie im Umzugsskript gesetzt: erst alle Rechte von anon,
# authenticated und service_role leeren, dann genau die aus der Sicherung einspielen.
# Sonst bekämen die neu angelegten Tabellen die Standardrechte von Supabase, und
# signups.token wäre für jeden lesbar.
#
# Nicht in der Sicherung: Cron-Aufträge (pg_cron). Im selben Projekt bleiben sie
# erhalten; in einem neuen Projekt den Auftrag wie in einrichtung/ANLEITUNG.md anlegen.
set -eu
umask 077

DUMP="${1:-}"
[ -f "$DUMP" ] || { echo "Aufruf: sh $0 sicherungen/supabase-….dump" >&2; exit 2; }

HIER="$(cd "$(dirname "$0")" && pwd)"
export PGPASSFILE="${PGPASSFILE:-$HIER/pgpass}"
IFS=: read -r HOST PORT DB BENUTZER REST < "$PGPASSFILE"
export PGHOST="$HOST" PGPORT="$PORT" PGUSER="$BENUTZER" PGDATABASE="$DB" PGSSLMODE="${PGSSLMODE:-require}"

ARBEIT="$(mktemp -d)"
trap 'rm -rf "$ARBEIT"' EXIT

echo "Sicherung: $DUMP"
echo "Ziel:      $BENUTZER @ $HOST"
echo "Alle Tabellen und Daten des Kita-Orgatools im Ziel werden durch die Sicherung ersetzt."
printf 'Zum Fortfahren "ersetzen" eingeben: '
read -r antwort
[ "$antwort" = ersetzen ] || { echo "Abgebrochen."; exit 1; }

# Inhaltsverzeichnis in zwei Teile wie in umzug.sh: alles außer Rechten, und die Rechte.
pg_restore --list --file="$ARBEIT/inhalt.list" "$DUMP"
grep -v -E '^[0-9]+; [0-9]+ [0-9]+ (DEFAULT ACL|ACL) | SCHEMA - public |COMMENT - SCHEMA public| EXTENSION ' \
  "$ARBEIT/inhalt.list" > "$ARBEIT/haupt.list" || true
grep -E '^[0-9]+; [0-9]+ [0-9]+ ACL ' "$ARBEIT/inhalt.list" \
  | grep -v -E 'SCHEMA public' > "$ARBEIT/rechte.list" || true

echo "Tabellen, Funktionen, Policies und Daten …"
pg_restore --dbname="$DB" --no-owner --single-transaction --exit-on-error \
  --clean --if-exists --use-list="$ARBEIT/haupt.list" "$DUMP"

echo "Rechte …"
psql -X -q -v ON_ERROR_STOP=1 -f "$HIER/../umzug/sql/rechte-leeren.sql"
pg_restore --dbname="$DB" --no-owner --use-list="$ARBEIT/rechte.list" "$DUMP"
psql -X -q -c "notify pgrst, 'reload schema'"

if [ "$(psql -X -At -c "select has_column_privilege('anon', 'public.signups', 'token', 'select')")" != f ]; then
  echo "GEFAHR: signups.token ist für jeden lesbar. Seiten nicht freigeben, Rechte prüfen." >&2
  exit 1
fi
echo "OK: signups.token ist gesperrt."
psql -X -At -c "select 'Veranstaltungen: ' || count(*) from events union all select 'Anmeldungen: ' || count(*) from signups"
echo "Fertig."
