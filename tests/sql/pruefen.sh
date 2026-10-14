#!/bin/sh
# Spielt schema.sql und alle Migrationen in eine frische Datenbank, jede zweimal (sie
# müssen mehrfach ausführbar sein), und prüft danach die Rechte mit rechte.sql.
# Braucht einen lokalen PostgreSQL-Server; Verbindung über die üblichen PG*-Variablen,
# etwa PGHOST=/tmp PGPORT=5432 PGUSER=postgres. Nie gegen das echte Projekt laufen lassen.
set -e
cd "$(dirname "$0")"
DB=kita_rechtetest
SQL=../../sql
psql -q -d postgres -c "drop database if exists $DB" -c "create database $DB"
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
psql -q -d postgres -c "drop database $DB"
if echo "$ergebnis" | grep -q FEHLER; then exit 1; fi
echo "Alle Rechteprüfungen bestanden."
