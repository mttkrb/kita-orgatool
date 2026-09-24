// Zugang zur Supabase-Instanz, gilt für alle Seiten.
// Leere URL = Demo-Modus mit Beispieldaten.
// Die echte Projektadresse wird erst beim Deployment eingetragen und nie committet.
const SUPABASE = { url:"", anonKey:"" };

// Aussehen, gilt für alle Seiten. Leere Werte = Standard.
// Logo und Favicon nur als Pfad relativ zu den Seiten (z. B. "icons/logo.png")
// oder auf derselben Domain — fremde Adressen werden ignoriert.
const SETTINGS = {
  name: "",            // Name der Kita, z. B. "Kita Sonnenschein"; erscheint im Kopf und im Seitentitel
  logo: "",            // Bild im Kopf aller Seiten, am besten PNG oder SVG, etwa 80 px hoch
  favicon: "",         // Symbol im Browser-Tab; leer = Symbol aus icons/
  colors: {
    main: "",          // Hauptfarbe für Knöpfe, Haken, Balken, z. B. "#3F5540"
    accent: ""         // Farbe für Warnungen, Absagen, Fehlendes, z. B. "#8C4A5C"
  }
};
