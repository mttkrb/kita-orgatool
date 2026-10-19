#!/bin/sh
# Erzeugt die App-Symbole für den Startbildschirm aus dem Logo in config.js (SETTINGS.logo).
# Eltern: Logo auf hellem Grund, Orgateam: auf dunklem Grund.
# Nach jedem Logowechsel laufen lassen und icons/eltern-*.png, icons/orga-*.png hochladen.
# Braucht ImageMagick 7 (magick).
set -e
cd "$(dirname "$0")/.."
logo=$(sed -n 's/^ *logo: *"\([^"]*\)".*/\1/p' config.js)
[ -n "$logo" ] || logo=icons/logo.svg
[ -f "$logo" ] || { echo "Logo $logo nicht gefunden" >&2; exit 1; }
for rolle in eltern:#EFEAE0 orga:#3F5540; do
  name=${rolle%%:*}; grund=${rolle#*:}
  for px in 180 192 512; do
    innen=$((px * 3 / 4))
    magick -background none -density 600 "$logo" -resize "${innen}x${innen}" \
      -background "$grund" -gravity center -extent "${px}x${px}" \
      -strip "icons/$name-$px.png"
  done
done
echo "Symbole aus $logo erzeugt."
