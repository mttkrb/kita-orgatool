# Kita-Orgatool

Anmeldungen, Planung und Auswertung für die Veranstaltungen einer Elterninitiative:
Sommerfest, Laternenfest, Arbeitseinsatz und alles, was sonst ansteht.

Das Tool wird von ehrenamtlichen Eltern betrieben und an nachfolgende Vorstände
weitergegeben. Deshalb ist es bewusst einfach gehalten: ein paar HTML-Dateien mit wenigen
gemeinsamen Skript- und Stildateien, kein Build, kein Framework. Wer HTML lesen kann, soll es ändern können.

## Was es kann

**Für Eltern**

- Offene Veranstaltungen auf einen Blick
- Anmelden oder begründet absagen, auch nachträglich über einen persönlichen Link ändern
- Eintragen, was man mitbringt, mit Anzeige, was noch fehlt
- Aufgaben übernehmen, vorab oder am Tag selbst
- Nach der Veranstaltung eine Rückmeldung geben

**Für das Orgateam**

- Veranstaltungen anlegen, aus Vorlagen für wiederkehrende Feste
- Kategorien, Aufgaben, Zusatzfragen und Sichtbarkeit je Veranstaltung einstellen
- To-dos über alle Veranstaltungen, Checkliste mit Fristen, Einkaufsliste
- Anmeldungen einsehen, von Hand eintragen oder bearbeiten
- Gemeldete Aufgaben übernehmen oder ablehnen
- Rückblick mit Zahlen und Bewertung, die als Vorschlag ins nächste Mal einfließen

## Die Seiten

| Datei | Für wen | Zweck |
| --- | --- | --- |
| `index.html` | Eltern | Übersicht offener Veranstaltungen |
| `fest-anmeldung.html` | Eltern | Anmeldung, Mitbringsel, Aufgaben |
| `feedback.html` | Eltern | Rückmeldung nach der Veranstaltung |
| `vorschlag.html` | Leitung, Vorstand, Teams | Aufgaben melden |
| `orga.html` | Orgateam | To-dos, Veranstaltungen, Vorlagen, Planung, Auswertung |

## Ausprobieren

Eine der HTML-Dateien im Browser öffnen. Solange in `config.js` keine Adresse
eingetragen ist, laufen die Seiten im **Demo-Modus** mit Beispieldaten. Im Orga-Bereich
reicht dann ein beliebiges Passwort.

## Technik

- Reines HTML mit eingebettetem CSS und JavaScript, keine Abhängigkeiten;
  gemeinsame Hilfsfunktionen in `common.js`, Zugangsdaten in `config.js`,
  gemeinsames Aussehen in `common.css` und `eltern.css`
- Datenbank: [Supabase](https://supabase.com) (Postgres), angesprochen über die REST-API
- Schriften Fraunces und Work Sans lokal in `fonts/` (SIL Open Font License),
  keine fremden Quellen außer der eigenen Supabase-Instanz
- Keine Benutzerkonten, keine Cookies, kein Tracking

### Sicherheitsmodell

Alle Seiten nutzen den öffentlichen `anonKey` von Supabase. Er steht absichtlich im
Klartext in den Dateien und identifiziert nur das Projekt. **Wer was darf, entscheiden
die Row-Level-Security-Policies in der Datenbank**, nicht das Frontend.

1. **Anonym:** Veranstaltungen lesen, sich anmelden, Aufgaben melden, Rückmeldung geben
2. **Eigener Eintrag:** Jede Anmeldung hat ein Zufallstoken, das nur im persönlichen
   Link steht. Damit lässt sich die eigene Anmeldung ändern oder löschen.
3. **Orgateam:** gemeinsames Passwort aus der Tabelle `orga_keys`, geprüft von der
   Datenbankfunktion `is_orga()`

Der `service_role`-Schlüssel von Supabase gehört **nie** in eine der Dateien.

### Datenschutz

- Anmeldungen und Aufgabenübernahmen werden nach der Veranstaltung gelöscht,
  standardmäßig nach 14 Tagen, je Veranstaltung einstellbar.
- Namen unter Rückmeldungen und Meldungen werden nach 60 Tagen anonymisiert.
- Vor dem Löschen bleibt eine Zusammenfassung ohne Personenbezug erhalten, damit die
  Planung fürs nächste Mal auf Zahlen zurückgreifen kann.
- Der Einwilligungstext auf der Anmeldeseite wird aus den Einstellungen der
  Veranstaltung erzeugt und passt so immer zum tatsächlichen Verhalten.

## Einrichten

1. **Supabase-Projekt anlegen.**
2. **Datenbank einrichten:** Das Grundschema steht als Kommentar im Kopf von
   `orga.html` und wird im SQL-Editor von Supabase ausgeführt. Dabei den Platzhalter
   `HIER-EIN-LANGES-ZUFALLS-PASSWORT` durch ein langes Zufallspasswort ersetzen
   (mindestens 24 Zeichen) und dieses im Passwortsafe des Vereins ablegen.
   Das Grundschema deckt nur `events`, `signups`, `templates`, `planning` und
   `orga_keys` ab. Die übrigen Tabellen (`task_claims`, `task_images`, `proposals`,
   `feedback`) und die Aufräumfunktion `daten_aufraeumen()` kommen aus den
   Migrationsdateien, die noch nicht im Repo liegen.
3. **Zugangsdaten eintragen:** In `config.js` unter `SUPABASE` die Projekt-URL und den
   `anonKey` eintragen. Das gilt für alle Seiten. Darunter unter `SETTINGS` optional
   Kitaname, Logo, Favicon und zwei Farben; leer lassen heißt Standardaussehen.
   Logo und Favicon als Pfad neben die HTML-Dateien legen (z. B. `icons/logo.png`).
4. **Hochladen:** Die HTML-Dateien zusammen mit `config.js`, `common.js`, `common.css` und
   `eltern.css` per SFTP in einen Unterordner des Webspace laden,
   zum Beispiel `/orga/`.

Bei Updates gilt: **erst SQL, dann HTML.** Sonst sucht die Seite nach Spalten, die es
in der Datenbank noch nicht gibt.

> **Hinweis:** Die echten Zugangsdaten werden nie committet. Im Repo bleiben die Felder
> in `config.js` leer. Lokal kann man die Werte in einer `supabase.env` ablegen,
> die über `.gitignore` ausgeschlossen ist.

## Mitarbeiten

Die Regeln für Änderungen am Code stehen in [`CLAUDE.md`](CLAUDE.md), unter anderem:

- Kein Build, kein Framework, keine neuen fremden Quellen
- Rechte gehören in die Datenbank, nicht ins JavaScript
- Fremde Eingaben nie ungeschützt über `innerHTML` ausgeben
- Oberfläche, Kommentare und Commit-Nachrichten auf Deutsch

## Entstehung

Das Tool wurde mithilfe eines KI-Programmierassistenten entwickelt. Die Vorgaben
dafür stehen in [`CLAUDE.md`](CLAUDE.md). Die KI steckt nur in der Entwicklung, nicht im
Tool selbst: Beim Betrieb werden keine Daten an einen KI-Dienst geschickt.

## Lizenz

[MIT](LICENSE) © 2026 janabyromi-del, mttkrb
