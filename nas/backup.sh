#!/bin/sh
# Sichert die Datenbank (Schemas public und intern) mit pg_dump und löscht Sicherungen,
# die älter als die Löschfrist sind. Die Sicherungen enthalten Elterndaten.
#
# Einrichtung auf einer Synology:
#   1. Diese Datei in einen Ordner auf einem verschlüsselten freigegebenen Ordner legen,
#      etwa /volume1/kita-backup/. Daneben eine Datei pgpass mit einer Zeile:
#        HOST:5432:postgres:BENUTZER:PASSWORT
#      Werte im Supabase-Dashboard unter Connect → Direct → Session pooler; das Passwort
#      ist das Datenbank-Passwort (Project Settings → Database). Rechte: chmod 600 pgpass
#   2. Systemsteuerung → Aufgabenplaner → Erstellen → Geplante Aufgabe →
#      Benutzerdefiniertes Skript. Benutzer: ein normaler Benutzer, nicht root, dem
#      pgpass gehört. Zeitplan: täglich nachts. Befehl: sh /volume1/kita-backup/backup.sh
#   3. Unter Einstellungen "Ausführungsdetails per E-Mail senden" und
#      "nur wenn das Skript abnormal beendet wurde" ankreuzen.
#   4. Einmal von Hand ausführen; im Ordner sicherungen/ liegt dann eine .dump-Datei.
#
# pg_dump muss mindestens die Postgres-Version des Projekts haben (Dashboard →
# Project Settings → Infrastructure). Wiederherstellen mit wiederherstellen.sh im
# selben Ordner.
#
# Ohne Datei auf dem NAS: In Schritt 2 statt des Befehls diese Zeilen in das Feld
# "Benutzerdefiniertes Skript" eintragen. Das Passwort steht dann im Klartext in der
# Aufgabe und ist für alle Administratoren des NAS lesbar.
#
#   export PGPASSWORD='PASSWORT'
#   D=/volume1/kita-backup/sicherungen; umask 077; mkdir -p "$D"
#   pg_dump "host=HOST port=5432 user=BENUTZER dbname=postgres sslmode=require" --format=custom --schema=public --schema=intern --no-publications --no-subscriptions --no-security-labels --file="$D/supabase-$(date +%Y%m%d-%H%M%S).dump" && find "$D" -name 'supabase-*.dump' -mtime +14 -delete
set -eu
umask 077

HIER="$(cd "$(dirname "$0")" && pwd)"
ZIEL="$HIER/sicherungen"
TAGE=14   # wie die Standard-Löschfrist der Anmeldungen

export PGPASSFILE="$HIER/pgpass"
IFS=: read -r HOST PORT DB BENUTZER REST < "$PGPASSFILE"

mkdir -p "$ZIEL"
DATEI="$ZIEL/supabase-$(date +%Y%m%d-%H%M%S).dump"
trap 'rm -f "$DATEI.teil"' EXIT

pg_dump "host=$HOST port=$PORT user=$BENUTZER dbname=$DB sslmode=require connect_timeout=30" \
  --format=custom --schema=public --schema=intern \
  --no-publications --no-subscriptions --no-security-labels \
  --file="$DATEI.teil"
mv "$DATEI.teil" "$DATEI"

find "$ZIEL" -name 'supabase-*.dump' -mtime +$TAGE -delete
