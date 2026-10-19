#!/bin/sh
# Spielt schema.sql und alle Migrationen in eine frische Datenbank, jede zweimal (sie
# müssen mehrfach ausführbar sein), und prüft danach die Rechte mit rechte.sql.
# Startet dafür einen eigenen, temporären PostgreSQL-Server in einem Temp-Ordner, nur
# über einen Unix-Socket dort, ohne TCP-Port. Danach wird er gestoppt und gelöscht.
# PG*-Variablen aus der Umgebung werden ignoriert, damit der Test nie eine andere
# Datenbank erreicht, schon gar nicht das echte Projekt.
# Braucht die PostgreSQL-Programme (initdb, pg_ctl, psql), etwa aus dem Paket postgresql.
set -e
cd "$(dirname "$0")"
DB=kita_rechtetest
SQL=../../sql

PGBIN=$(dirname "$(command -v initdb || ls /usr/lib/postgresql/*/bin/initdb 2>/dev/null | sort -V | tail -1)")
[ -x "$PGBIN/initdb" ] || { echo "initdb nicht gefunden, PostgreSQL installieren" >&2; exit 1; }
TMP=$(mktemp -d)
for v in $(env | sed -n 's/^\(PG[A-Z]*\)=.*/\1/p'); do unset "$v"; done
export PGHOST="$TMP" PGUSER=postgres PGPORT=5432
"$PGBIN/initdb" -D "$TMP/daten" -U postgres --auth=trust -E UTF8 --locale=C >/dev/null
"$PGBIN/pg_ctl" -D "$TMP/daten" -l "$TMP/log" -w -o "-k $TMP -c listen_addresses=''" start >/dev/null
trap '"$PGBIN/pg_ctl" -D "$TMP/daten" -m immediate stop >/dev/null; rm -rf "$TMP"' EXIT

psql -q -d postgres -c "create database $DB"
psql -q -v ON_ERROR_STOP=1 -d $DB -f umgebung.sql
dateien="$SQL/schema.sql $(ls $SQL/migration-*.sql | sort -t- -k2 -n)"
for f in $dateien; do
  for runde in 1 2; do
    psql -q -v ON_ERROR_STOP=1 -d $DB -f "$f" >/dev/null 2>&1 \
      || { echo "FEHLER beim Einspielen von $f (Runde $runde)"; psql -q -v ON_ERROR_STOP=1 -d $DB -f "$f"; exit 1; }
  done
done
echo "Eingespielt, je zweimal: $(echo $dateien | wc -w) Dateien"
ergebnis=$(psql -q -v ON_ERROR_STOP=1 -d $DB -f rechte.sql 2>&1 | sed -n 's/.*NOTICE:  //p')
echo "$ergebnis"
if echo "$ergebnis" | grep -q FEHLER; then exit 1; fi
echo "Alle Rechteprüfungen bestanden."
