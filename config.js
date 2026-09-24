// Zugang zur Supabase-Instanz, gilt für alle Seiten.
// Leere URL = Demo-Modus mit Beispieldaten.
// Die echte Projektadresse wird erst beim Deployment eingetragen und nie committet.
const SUPABASE = { url:"", anonKey:"" };

// Aussehen, gilt für alle Seiten. Leere Werte = Standard.
// Logo und Favicon in icons/ sind die mitgelieferten Standardbilder; zum Austauschen
// eigene Dateien daneben legen und hier eintragen, oder leer lassen für kein Logo.
// Logo und Favicon nur als Pfad relativ zu den Seiten (z. B. "icons/logo.png")
// oder auf derselben Domain — fremde Adressen werden ignoriert.
const SETTINGS = {
  name: "",                     // Name der Kita, z. B. "Kita Sonnenschein"; erscheint im Kopf und im Seitentitel
  logo: "icons/logo.svg",       // Bild im Kopf aller Seiten, PNG oder SVG, quadratisch, etwa 80 px
  favicon: "icons/favicon.png", // Symbol im Browser-Tab, PNG 64 × 64 px
  colors: {
    main: "",                   // Hauptfarbe für Knöpfe, Haken, Balken, z. B. "#3F5540"
    accent: ""                  // Farbe für Warnungen, Absagen, Fehlendes, z. B. "#8C4A5C"
  }
};
