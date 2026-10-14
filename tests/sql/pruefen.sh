#!/bin/sh
# Spielt basis.sql und die Migrationen 21 und 22 (je zweimal, sie müssen mehrfach
# ausführbar sein) in eine frische Datenbank und prüft die Rechte mit rechte.sql.
# Braucht einen lokalen PostgreSQL-Server; Verbindung über die üblichen PG*-Variablen,
# etwa PGHOST=/tmp PGPORT=5432 PGUSER=postgres. Nie gegen das echte Projekt laufen lassen.
set -e
cd "$(dirname "$0")"
DB=kita_rechtetest
psql -q -d postgres -c "drop database if exists $DB" -c "create database $DB"
psql -q -v ON_ERROR_STOP=1 -d $DB -f basis.sql
for m in 21 22; do
  for runde in 1 2; do
    psql -q -v ON_ERROR_STOP=1 -d $DB -f ../../sql/migration-$m.sql 2>/dev/null
  done
done
ergebnis=$(psql -q -v ON_ERROR_STOP=1 -d $DB -f rechte.sql 2>&1 | sed -n 's/.*NOTICE:  //p')
echo "$ergebnis"
psql -q -d postgres -c "drop database $DB"
if echo "$ergebnis" | grep -q FEHLER; then exit 1; fi
echo "Alle Rechteprüfungen bestanden."
