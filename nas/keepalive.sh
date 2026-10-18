#!/bin/sh
# Hält das Supabase-Projekt wach. Im kostenlosen Tarif pausiert Supabase ein Projekt
# nach einer Woche ohne Zugriff; ein Abruf am Tag verhindert das.
#
# Einrichtung auf einer Synology:
#   1. Diese Datei und eine Kopie von supabase.env (SUPABASE_URL, SUPABASE_ANON_KEY)
#      in denselben Ordner auf dem NAS legen, etwa /volume1/kita/keepalive/.
#   2. Systemsteuerung → Aufgabenplaner → Erstellen → Geplante Aufgabe →
#      Benutzerdefiniertes Skript. Benutzer: ein normaler Benutzer, nicht root.
#      Zeitplan: täglich. Befehl: sh /volume1/kita/keepalive/keepalive.sh
#   3. Unter Einstellungen "Ausführungsdetails per E-Mail senden" und
#      "nur wenn das Skript abnormal beendet wurde" ankreuzen.
#   4. Einmal von Hand ausführen (Aufgabe markieren → Ausführen).
#
# Ohne Datei auf dem NAS: In Schritt 2 statt des Befehls diese drei Zeilen in das Feld
# "Benutzerdefiniertes Skript" eintragen, URL und anonKey aus config.js bzw. supabase.env:
#
#   SUPABASE_URL="https://DEIN-PROJEKT.supabase.co"
#   SUPABASE_ANON_KEY="eyJ..."
#   curl -fsS --max-time 30 -o /dev/null -H "apikey: $SUPABASE_ANON_KEY" "$SUPABASE_URL/rest/v1/events?select=id&limit=1"
#
# Der anonKey ist ohnehin öffentlich; der service_role-Schlüssel gehört nicht hierher.
# Endet mit Fehler, wenn das Projekt nicht antwortet, etwa weil es schon pausiert ist.
# Dann im Supabase-Dashboard "Restore" klicken.
set -eu

. "$(dirname "$0")/supabase.env"

curl -fsS --max-time 30 -o /dev/null \
  -H "apikey: $SUPABASE_ANON_KEY" \
  "${SUPABASE_URL%/}/rest/v1/events?select=id&limit=1"
