# Kita-Orgatool

Anmeldungen, Planung und Auswertung für die Veranstaltungen einer Elterninitiative.
Betrieben von ehrenamtlichen Eltern, weitergegeben an nachfolgende Vorstände.

Ausführliche Begründungen stehen im Projekthandbuch (`docs/projekthandbuch.md`).
Diese Datei ist die Kurzfassung für die Arbeit am Code.

## Grundregeln

Diese Regeln sind bewusst gewählt. Nicht ohne Rückfrage davon abweichen.

1. **Kein Build, kein Framework, kein npm im Auslieferungsstand.** Fünf HTML-Dateien
   mit eingebettetem CSS und JavaScript. Wer sie lesen kann, soll sie ändern können.
   Node wird nur für die Tests benutzt.
2. **Keine neuen Fremdquellen.** Erlaubt sind die eigene Supabase-Instanz und
   Bunny Fonts. Keine CDNs, keine Bibliotheken, keine Tracker, keine Google Fonts.
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
manifest-eltern.json    Installation Startbildschirm, helles Symbol
manifest-orga.json      Installation Startbildschirm, dunkles Symbol
icons/                  App-Symbole
sql/                    schema.sql, migration-2.sql … migration-N.sql, Importe
tests/                  Node mit jsdom, Nachbau der Datenbank inkl. Rechteprüfung
deploy/.htaccess        Für den Zielordner /orga/ auf dem Webspace
nas/                    Backup- und Keep-alive-Skripte für das Vereins-NAS
docs/                   Projekthandbuch, Migrationsanleitung, Aufgabenliste
```

Konfiguration steht oben im Skript jeder HTML-Datei (`CONFIG`): Supabase-URL und
anonKey, dazu die Dateinamen der öffentlichen Seiten. Leere Supabase-URL schaltet den
Demo-Modus mit Beispieldaten ein.

Im Repo steht in `CONFIG.supabase.url` ein Platzhalter. Die echte Projektadresse wird
erst beim Deployment eingetragen und nie committet.

## Datenmodell

Neun Tabellen. Veränderliche Strukturen liegen als JSON in Spalten, weil sich die
Felder je Veranstaltung unterscheiden.

| Tabelle | Inhalt | Wer liest |
| --- | --- | --- |
| `events` | Termin, Kategorien, Aufgaben, Zusatzfragen, Sichtbarkeit, Fristen | alle |
| `signups` | Anmeldungen und Absagen | alle außer Spalte `token` |
| `task_claims` | Aufgabenübernahmen am Tag, mit Erledigt-Haken | alle |
| `task_images` | Fotos zu Aufgaben, verkleinertes JPEG in der Zeile | alle |
| `templates` | Vorlagen für wiederkehrende Veranstaltungen | nur Orga |
| `planning` | Checkliste, Einkaufsliste, Rückblick | nur Orga |
| `proposals` | Gemeldete Aufgaben | Melder offene, Orga alles |
| `feedback` | Rückmeldungen der Eltern | nur Orga |
| `orga_keys` | Orga-Passwort | niemand über die API |

JSON-Strukturen: `categories`, `tasks`, `fields`, `checklist`, `shopping`, `review`,
`people`, `visibility` — Felder siehe Projekthandbuch, Abschnitt 4.

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
  Personenbezug nach `planning.review.zahlen`. Die Historie überlebt die Namen.
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

**Änderungen am Frontend**

- Pfade immer relativ. Die Seiten liegen im Unterordner `/orga/` einer WordPress-Seite;
  alles mit führendem `/` zeigt ins WordPress.
- Links nicht aus `location.origin` zusammenbauen, sondern
  `new URL(CONFIG.publicPage, location.href)`.
- Fremde Eingaben nur über `textContent` ausgeben, nie über `innerHTML`.
- Listen, die aus Anmeldungen rechnen, nach dem Laden neu aufbauen, sonst zeigen sie Null.
- Keine Darstellungsangaben direkt im Element, wenn das Element über eine Klasse
  versteckt wird — die Angabe im Element schlägt die Klasse.
- Keine typografischen Anführungszeichen in JavaScript-Zeichenketten.

**Tests**

- `npm test` im Ordner `tests/`. Vor jedem Commit laufen lassen.
- Der Datenbank-Nachbau bildet auch die Fehler der echten Datenbank nach,
  insbesondere die gesperrte Token-Spalte. Tests, die freundlicher sind als die
  Wirklichkeit, nicht einbauen.
- Neue Policies brauchen einen Test, der den verbotenen Zugriff nachweist,
  nicht nur den erlaubten.

**Deployment**

Dateien per SFTP in den Ordner `/orga/` des Webspace. Kein Build, keine Pipeline.
`deploy/.htaccess` gehört dazu. Erst SQL, dann Dateien.

## Nicht ins Repo

`supabase.env`, `pgpass`, `*.dump`, echte Supabase-URL und anonKey, Einwilligungstexte
mit echten Namen, Exporte mit Elterndaten. Nur `.example`-Dateien committen.

## Bewusst nicht gebaut

E-Mail-Versand, Mitgliederliste, Papierkorb mit Wiederherstellen, KI-Assistent im Tool,
Offline-Modus, serverseitige Begrenzung von Helferplätzen, Einladungsgestaltung.
Begründungen im Projekthandbuch, Abschnitt 9. Diese Themen nicht unaufgefordert ergänzen.
