# Kita-Orgatool

Anmeldungen, Planung und Auswertung für die Veranstaltungen einer Elterninitiative.
Betrieben von ehrenamtlichen Eltern, weitergegeben an nachfolgende Vorstände.

Aufbau, Rechte und Betrieb für Menschen erklärt `anleitungen/technik.md`.
Diese Datei ist die Kurzfassung für die Arbeit am Code.

## Grundregeln

Diese Regeln sind bewusst gewählt. Nicht ohne Rückfrage davon abweichen.

1. **Kein Build, kein Framework, kein npm im Auslieferungsstand.** Fünf HTML-Dateien
   mit eingebettetem CSS und JavaScript, dazu wenige gemeinsame Dateien:
   `config.js` (Supabase-Zugang, Aussehen), `common.js` (Hilfsfunktionen), `common.css`
   (Farben, Schrift, Fokus, `.hidden` für alle Seiten) und `eltern.css` (Formulare und
   Kopf der vier Elternseiten). Eingebunden als einfache `<script src>` und
   `<link rel="stylesheet">`, ohne Module und ohne Bündeln. Nur was in mehreren Seiten
   gleich ist, gehört in die gemeinsamen Dateien; alles andere bleibt in der Seite. Wer sie lesen kann, soll sie ändern können.
   Node wird nur für die Tests benutzt.
2. **Keine Fremdquellen.** Einzige Verbindung nach außen ist die eigene
   Supabase-Instanz. Schriften liegen in `fonts/`. Keine CDNs, keine Bibliotheken,
   keine Tracker, keine Webfont-Dienste.
3. **Rechte gehören in die Datenbank.** Wer was darf, entscheiden RLS-Policies in
   Postgres, nicht das Frontend. Prüfungen im JavaScript sind Komfort, keine Sicherheit.
4. **Erst SQL, dann HTML.** Migration einspielen, danach die Seiten hochladen.
   Umgekehrt sucht die Seite Spalten, die es noch nicht gibt.
5. **Datensparsamkeit.** Keine neuen personenbezogenen Felder ohne Not. Was gespeichert
   wird, muss zur Löschfrist und zum Einwilligungstext passen.
6. **Deutsch.** Oberfläche, Kommentare und Commit-Nachrichten auf Deutsch.
   Bezeichner im Code englisch, wie im Bestand.

## Repo-Aufbau

```
index.html              Übersicht offener Veranstaltungen (Eltern)
fest-anmeldung.html     Anmeldung, Mitbringsel, Aufgaben (Eltern)
orga.html               To-dos, Veranstaltungen, Vorlagen, Planung, Auswertung (Orgateam)
vorschlag.html          Aufgaben melden (Leitung, Vorstand, Teams)
feedback.html           Rückmeldung nach der Veranstaltung (Eltern)
config.js               Supabase-Zugang und Aussehen (Kitaname, Logo, Farben, Favicon)
common.js               Gemeinsame Hilfsfunktionen (esc, fmtDate, groups, vis, …)
common.css              Grundlage aller Seiten: Farben, Schrift, Fokus, .hidden
eltern.css              Kopf und Formulare der Elternseiten (nicht orga.html)
manifest-eltern.json    Installation Startbildschirm, helles Symbol
manifest-orga.json      Installation Startbildschirm, dunkles Symbol
icons/                  App-Symbole (aus dem Logo, einrichtung/symbole-erzeugen.sh), Standard-Logo und -Favicon
fonts/                  Fraunces und Work Sans als woff2, Lizenztexte OFL-*.txt
sql/                    schema.sql, migration-2.sql … migration-N.sql (keine Daten)
tests/                  Node mit jsdom gegen Nachbau der Schnittstelle; sql/: Rechte in temporärem Postgres
deploy/.htaccess        Für den Zielordner /orga/ auf dem Webspace
nas/                    Backup- und Keep-alive-Skripte für das Vereins-NAS
aufgaben.md             Offene Aufgaben
umzug/                  Umzug in ein anderes Supabase-Projekt: Skripte (sh, ps1) und Anleitung
einrichtung/            Neuinstallation: Anleitung, SQL-Vorlage und Skript, das sie erzeugt
aktualisierung/         Update einer laufenden Installation: Anleitung
anleitungen/            Bedienungsanleitungen je Rolle: Eltern, Orgateam, Melden, Technik
```

Supabase-URL und anonKey stehen einmal in `config.js` (`SUPABASE`). Seitenspezifische
Einstellungen, etwa die Dateinamen der öffentlichen Seiten, stehen oben im Skript der
jeweiligen HTML-Datei (`CONFIG`, mit `supabase: SUPABASE`). Leere Supabase-URL schaltet
den Demo-Modus mit Beispieldaten ein.

Aussehen steht ebenfalls in `config.js` (`SETTINGS`): Kitaname, Logo, Favicon und zwei
Farben. Leere Werte bedeuten Standard. `common.js` setzt daraus Seitentitel, die Zeile
mit Logo und Name über dem Kopf, die Farbvariablen `--moss`/`--berry` samt hellen
Tönen und `theme-color`. Logo und Favicon nur von der eigenen Domain (Grundregel 2);
fremde Adressen werden stillschweigend ignoriert. Die Manifeste bleiben davon
unberührt. Eine ältere `config.js` ohne `SETTINGS` muss weiter funktionieren.

`config.js` und `common.js` stehen im `<head>`, damit die Farben vor dem ersten Zeichnen
gesetzt sind; das Skript der Seite steht am Ende von `<body>`. `common.js` fasst beim
Laden das DOM nicht an, außer über `DOMContentLoaded`. Seitentitel, die erst nach dem
Laden feststehen, über `titel(text)` setzen, nicht über `document.title`.
Namen aus `common.js` (`live`, `$`, `esc`, `bildUrl`, `SIGNUP_COLS`, `anonHead`,
`isoDatum`, `heute`, `fmtDate`, `vis`, `groups`, `verkleinern`, `EINSTELLUNG`,
`kitaName`, `eigeneAdresse`, `farbe`, `titel`, `euro`, `preisZahl`, `bestellArtikel`, `bestellMenge`,
`kostetEtwas`, `kosten`, `paypalName`, `paypalMail`, `paypalLink`, `zahlLink`, `zahlweg`, `textMitFormat`, `nurOrga`) in den Seiten nicht auf oberster Ebene
neu deklarieren — das ergibt einen SyntaxError und die ganze Seite bleibt stehen.

Im Repo bleibt `SUPABASE.url` in `config.js` leer (Demo-Modus). Die echte Projektadresse wird
erst beim Deployment eingetragen und nie committet.

## Datenmodell

Zwölf Tabellen. Veränderliche Strukturen liegen als JSON in Spalten, weil sich die
Felder je Veranstaltung unterscheiden.

| Tabelle | Inhalt | Wer liest |
| --- | --- | --- |
| `events` | Termin, Kategorien, Aufgaben, Zusatzfragen, Sichtbarkeit, Fristen | alle |
| `signups` | Anmeldungen und Absagen | Orga und eigener Eintrag (Token); Elternseiten nur über `anmeldungen_oeffentlich()` |
| `task_claims` | Aufgabenübernahmen am Tag, mit Erledigt-Haken | alle |
| `task_images` | Fotos zu Aufgaben, verkleinertes JPEG in der Zeile | alle |
| `templates` | Vorlagen für wiederkehrende Veranstaltungen | nur Orga |
| `planning` | Checkliste, Einkaufsliste, Rückblick | nur Orga |
| `proposals` | Gemeldete Aufgaben | Melder offene, Orga alles |
| `feedback` | Rückmeldungen der Eltern | nur Orga |
| `payments` | Zahlungseingang je Anmeldung (Haken, Betrag, Datum), Kaskade mit `signups` | nur Orga |
| `attendance` | Check-in: gekommen, gegangen, Stunden je Anmeldung, Kaskade mit `signups` | nur Orga |
| `checkin_codes` | Code vom Aushang je Veranstaltung | nur Orga |
| `orga_keys` | Orga-Passwort | niemand über die API |

JSON-Strukturen: `categories`, `tasks`, `fields`, `checklist`, `shopping`, `review`,
`people`, `visibility`, `payment` — Felder siehe Kommentare in `sql/` und der Code in `orga.html`.

Kosten (ab `migration-22.sql`): `events.payment` und `templates.payment` halten
`{ adults, kids, note, link }` — Preis je Person der beiden Gruppen, Zahlungshinweis und
Zahlweg: PayPal.me-Name, PayPal-Adresse (Freunde & Familie) oder ein beliebiger https-Link
(Wero, Bank). Ältere Einträge heißen `paypal`; `zahlweg()` liest beide, gespeichert wird `link`. Bestellartikel sind Zusatzfragen vom Typ `order` mit `price` und `max`;
die Menge steht wie jede Antwort in `signups.fields`. Ausgaben stehen als `preis` in
`planning.shopping`, festgehaltene Summen in `planning.review.geld`. Der Betrag einer
Anmeldung wird nie gespeichert, sondern immer mit `kosten(ev, signup)` aus `common.js`
gerechnet. Zahlwege sind nur Links, kein Skript und keine Fremdquelle.

Check-in (ab `migration-23.sql`): `events.checkin` schaltet ihn ein. Der Aushang führt auf
`fest-anmeldung.html?event=…&checkin=CODE`. Eltern checken über die Datenbankfunktionen
`checkin()` und `checkin_status()` ein und aus; sie prüfen Token, Code und Tag
(Europe/Berlin). Abgesagte Anmeldungen checken nicht ein (ab `migration-25.sql`). Direkt in `attendance` schreibt nur das Orgateam. Bei Veranstaltungen mit
Check-in merkt sich das Handy Kennung und Token unter `localStorage` `kita-anmeldung:<slug>`,
wiedererkannt wird nur beim Scan am Eingang. Der QR-Code entsteht ohne Bibliothek in
`orga.html` (`qrMatrix`, `qrSvg`).

Abmelden mit Zahlung (ab `migration-24.sql`): Ist für eine Anmeldung ein Zahlungseingang
eingetragen, löschen Eltern sie nicht mehr über den persönlichen Link; das Orgateam löscht
selbst und zahlt vorher zurück. Absagen über das Formular bleiben möglich. Hilfsfunktionen
für Policies liegen im Schema `intern`, das die Schnittstelle nicht erreicht.
`intern.anmeldung_betrag()` rechnet wie `kosten()` in `common.js` — wer eines ändert,
ändert beide.

## Sicherheitsmodell

Drei Stufen, alle ohne Benutzerkonten, alle über dieselbe Postgres-Rolle `anon`:

1. **Anonym** — der anonKey steht im Klartext in den HTML-Dateien, das ist vorgesehen.
   Er identifiziert nur das Projekt; die Policies entscheiden.
2. **Eigener Eintrag** — jede Anmeldung hat ein Zufallstoken, das nur im persönlichen
   Link steht und als Header `X-Entry-Token` mitgeschickt wird.
3. **Orgateam** — gemeinsames Passwort in `orga_keys`, Header `X-Orga-Key`,
   geprüft von `is_orga()`.

Daraus folgt:

- **Nie nach `token` filtern.** `?token=eq.…` scheitert mit 42501, weil Filtern
  Leserecht voraussetzt. Änderungen laufen über `?id=eq.…` plus Token im Header.
- **Anmeldungen liest anon nicht direkt** (ab `migration-26.sql`). Die Elternseiten holen
  Zahlen, Mitbringsel, Aufgaben und gekürzte Namen über `anmeldungen_oeffentlich()`;
  die eigene Zeile liest nur, wer `X-Entry-Token` mitschickt. `intern.kurzname()` kürzt
  wie `shortName()` in `fest-anmeldung.html` — wer eines ändert, ändert beide.
- **Spaltenrechte gelten auch fürs Orgateam**, weil es dieselbe Rolle nutzt. Interne
  Daten gehören in eigene Tabellen, nicht in versteckte Spalten.
- **Alles, was `anon` schreiben darf, kann jeder schreiben.** Neue Schreibpfade
  brauchen Längen- und Größengrenzen in der Datenbank.

## Aufbewahrung

- Anmeldungen und Aufgabenübernahmen: Löschung nach der Frist der Veranstaltung,
  Standard 14 Tage, je Veranstaltung über `retention_days` einstellbar.
- Namen unter Rückmeldungen und Meldungen: nach 60 Tagen anonymisiert, Texte bleiben.
- Planung, Rückblick, Fotos und Zahlen: bleiben dauerhaft.
- `daten_aufraeumen()` schreibt vor dem Löschen eine Zusammenfassung ohne
  Personenbezug nach `planning.review.zahlen` (dazu Anwesenheit und Stunden) und die
  Einnahmen nach `planning.review.geld`. Die Historie überlebt die Namen.
- Der Einwilligungstext auf der Anmeldeseite wird aus `visibility` und
  `retention_days` erzeugt. **Wer diese Felder ändert, ändert ein Versprechen an die
  Eltern** — Text und Verhalten müssen zusammenpassen.
- Veranstaltungen ohne Datum werden nie aufgeräumt; das Datum ist Grundlage aller Fristen.

## Arbeitsweise

**Änderungen am Datenmodell**

1. Neue Datei `sql/migration-N.sql` mit der nächsten freien Nummer anlegen.
   Bestehende Migrationen nie nachträglich ändern — sie sind bereits eingespielt.
2. Mehrfach ausführbar schreiben (`if not exists`, `create or replace`).
3. Reihenfolge ist verbindlich; spätere Migrationen ersetzen Funktionen aus früheren.
4. Die Versionsprüfung im Orga-Bereich erwartet neue Spalten — beim Erweitern
   mitpflegen, damit sie fehlende Spalten beim Namen nennt.
5. Nach dem Einspielen `einrichtung/vorlage-erzeugen.sh` laufen lassen und
   `einrichtung/sql/` mit committen. Die Vorlage für Neuinstallationen wird nur so
   erzeugt, nie von Hand geändert.

**Änderungen am Frontend**

- Pfade immer relativ. Die Seiten liegen im Unterordner `/orga/` einer WordPress-Seite;
  alles mit führendem `/` zeigt ins WordPress.
- Links nicht aus `location.origin` zusammenbauen, sondern
  `new URL(CONFIG.publicPage, location.href)`.
- Fremde Eingaben nur über `textContent` ausgeben, nie über `innerHTML`.
- Listen, die aus Anmeldungen rechnen, nach dem Laden neu aufbauen, sonst zeigen sie Null.
- Keine Darstellungsangaben direkt im Element, wenn das Element über eine Klasse
  versteckt wird. `.hidden` steht in `common.css` mit `!important` und gewinnt
  deshalb immer; eine Angabe im Element wirkt erst, wenn die Klasse weg ist.
- Stylesheets in der Reihenfolge `common.css`, `eltern.css`, dann `<style>` der Seite.
  Die Seite überschreibt, was sie anders braucht. `orga.html` lädt `eltern.css` nicht.
- Keine typografischen Anführungszeichen in JavaScript-Zeichenketten.
- Tagesdatum immer über `heute()` bzw. `isoDatum(d)` aus `common.js`, nie über
  `toISOString().slice(0,10)` — das ist UTC und liefert nach Mitternacht den Vortag.

- Wer Bedienung, Knopftexte oder Verhalten ändert, passt die Anleitung der betroffenen
  Rolle in `anleitungen/` mit an.

**Tests**

- `npm test` im Ordner `tests/` (einmalig `npm install`). Vor jedem Commit laufen lassen.
  Die Seitentests laufen in jsdom gegen den Nachbau `tests/fake-db.js`, ohne Netz.
  Die Rechteprüfung `tests/sql/pruefen.sh` startet einen eigenen temporären Postgres
  (braucht `initdb`), nie gegen Supabase oder einen vorhandenen Server.
- Der Datenbank-Nachbau bildet auch die Fehler der echten Datenbank nach,
  insbesondere die gesperrte Token-Spalte. Tests, die freundlicher sind als die
  Wirklichkeit, nicht einbauen.
- Neue Policies brauchen einen Test, der den verbotenen Zugriff nachweist,
  nicht nur den erlaubten: in `tests/sql/rechte.sql`, und `fake-db.js` angleichen.

**Deployment**

Dateien per SFTP in den Ordner `/orga/` des Webspace. Kein Build, keine Pipeline.
`config.js`, `common.js`, `common.css`, `eltern.css`, der Ordner `fonts/` und
`deploy/.htaccess` gehören dazu. Erst SQL, dann Dateien.
Ablauf für bestehende Installationen in `aktualisierung/ANLEITUNG.md`. Wer dort
aktualisiert, überschreibt seine `config.js` nicht: Neue Einträge in `config.js`
brauchen einen Standardwert im Code. Migration, erneuerte Vorlage und geänderte Seiten
in einen Commit.

## Nicht ins Repo

`supabase.env`, `pgpass`, `*.dump`, echte Supabase-URL und anonKey, Einwilligungstexte
mit echten Namen, Exporte mit Elterndaten. Nur `.example`-Dateien committen.

## Bewusst nicht gebaut

E-Mail-Versand, Mitgliederliste, Papierkorb mit Wiederherstellen, KI-Assistent im Tool,
Offline-Modus, serverseitige Begrenzung von Helferplätzen, Einladungsgestaltung.
Diese Themen nicht unaufgefordert ergänzen.
