#!/bin/sh
# Erzeugt die App-Symbole für den Startbildschirm aus dem Logo in config.js (SETTINGS.logo).
# Eltern: Logo auf hellem Grund, Orgateam: auf dunklem Grund.
# Nach jedem Logowechsel laufen lassen und icons/eltern-*.png, icons/orga-*.png hochladen.
# Liegt das Logo nicht im Repo, etwa im WordPress, Datei oder https-Adresse mitgeben:
#   einrichtung/symbole-erzeugen.sh https://example.org/wp-content/uploads/logo.png
# Braucht ImageMagick 7 (magick), für Adressen curl.
set -e
logo=$1
case "$logo" in
  ""|/*) ;;
  *://*) ;;
  *) logo=$(cd "$(dirname "$logo")" && pwd)/$(basename "$logo") ;;
esac
cd "$(dirname "$0")/.."
[ -n "$logo" ] || logo=$(sed -n 's/^ *logo: *"\([^"]*\)".*/\1/p' config.js)
[ -n "$logo" ] || logo=icons/logo.svg
case "$logo" in
  https://*)
    tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
    curl -sfL -o "$tmp" "$logo" || { echo "Logo $logo nicht ladbar" >&2; exit 1; }
    logo=$tmp ;;
esac
[ -f "$logo" ] || { echo "Logo $logo nicht gefunden. Datei oder https-Adresse als Argument mitgeben." >&2; exit 1; }
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
