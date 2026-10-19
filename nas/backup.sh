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
#   2. Paketzentrum → Container Manager installieren, falls das pg_dump von DSM nicht
#      reicht (ältere DSM bringen eines ohne SSL oder in zu alter Version mit). Das
#      Skript versucht erst das pg_dump des NAS und nimmt sonst das aus dem Abbild
#      postgres:17-alpine, das es beim ersten Mal herunterlädt.
#   3. Systemsteuerung → Aufgabenplaner → Erstellen → Geplante Aufgabe →
#      Benutzerdefiniertes Skript. Benutzer: root (nur root darf Container starten;
#      ohne Container genügt ein normaler Benutzer, dem pgpass gehört).
#      Zeitplan: täglich nachts. Befehl: sh /volume1/kita-backup/backup.sh
#   4. Unter Einstellungen "Ausführungsdetails per E-Mail senden" und
#      "nur wenn das Skript abnormal beendet wurde" ankreuzen.
#   5. Einmal von Hand ausführen; im Ordner sicherungen/ liegt dann eine .dump-Datei.
#
# pg_dump muss mindestens die Postgres-Version des Projekts haben (Dashboard →
# Project Settings → Infrastructure). Bei einem neueren Projekt PGBILD unten anpassen.
# Wiederherstellen mit wiederherstellen.sh im selben Ordner.
#
# Ohne Datei auf dem NAS: In Schritt 3 statt des Befehls diese Zeilen in das Feld
# "Benutzerdefiniertes Skript" eintragen. Das Passwort steht dann im Klartext in der
# Aufgabe und ist für alle Administratoren des NAS lesbar.
#
#   export PGPASSWORD='PASSWORT'; PATH="$PATH:/usr/local/bin"
#   B=postgres:17-alpine; D=/volume1/kita-backup/sicherungen; umask 077; mkdir -p "$D"
#   F="$D/supabase-$(date +%Y%m%d-%H%M%S).dump"
#   A="host=HOST port=5432 user=BENUTZER dbname=postgres sslmode=require connect_timeout=30"
#   O="--format=custom --schema=public --schema=intern --no-publications --no-subscriptions --no-security-labels"
#   pg_dump "$A" $O --file="$F" 2>/dev/null || { docker image inspect $B >/dev/null 2>&1 || docker pull -q $B; docker run --rm -e PGPASSWORD -v "$D:$D" $B pg_dump "$A" $O --file="$F"; } || { rm -f "$F"; exit 1; }
#   find "$D" -name 'supabase-*.dump' -mtime +14 -delete
set -eu
umask 077

HIER="$(cd "$(dirname "$0")" && pwd)"
ZIEL="$HIER/sicherungen"
TAGE=14   # wie die Standard-Löschfrist der Anmeldungen

export PGPASSFILE="$HIER/pgpass"
IFS=: read -r HOST PORT DB BENUTZER REST < "$PGPASSFILE"

PGBILD=postgres:17-alpine   # Hauptversion mindestens wie im Supabase-Projekt

# Container Manager liegt unter /usr/local/bin, das fehlt im PATH des Aufgabenplaners.
PATH="$PATH:/usr/local/bin"

mkdir -p "$ZIEL"
DATEI="$ZIEL/supabase-$(date +%Y%m%d-%H%M%S).dump"
trap 'rm -f "$DATEI.teil"' EXIT

sichern() {
  pg_dump "host=$HOST port=$PORT user=$BENUTZER dbname=$DB sslmode=require connect_timeout=30" \
    --format=custom --schema=public --schema=intern \
    --no-publications --no-subscriptions --no-security-labels \
    --file="$DATEI.teil"
}

# Erst das pg_dump des NAS. Scheitert es (ohne SSL, zu alt, fehlt), das aus dem Container;
# das Abbild wird beim ersten Mal geladen. Ohne Container Manager zeigt der zweite Lauf
# den Fehler des NAS-pg_dump.
if ! sichern 2>/dev/null; then
  if command -v docker >/dev/null 2>&1; then
    docker image inspect "$PGBILD" >/dev/null 2>&1 || docker pull -q "$PGBILD"
    pg_dump() { docker run --rm -e PGPASSFILE -v "$HIER:$HIER" "$PGBILD" pg_dump "$@"; }
  fi
  sichern
fi
mv "$DATEI.teil" "$DATEI"

find "$ZIEL" -name 'supabase-*.dump' -mtime +$TAGE -delete
