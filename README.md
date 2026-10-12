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
- Sehen, was die Anmeldung kostet, auch mit Bestellungen wie einem zusätzlichen Weckmann,
  dazu Zahlungshinweis und ein PayPal-Link mit dem richtigen Betrag
- Nach der Veranstaltung eine Rückmeldung geben

**Für das Orgateam**

- Veranstaltungen anlegen, aus Vorlagen für wiederkehrende Feste
- Kategorien, Aufgaben, Zusatzfragen und Sichtbarkeit je Veranstaltung einstellen
- To-dos über alle Veranstaltungen, Checkliste mit Fristen, Einkaufsliste
- Anmeldungen einsehen, von Hand eintragen oder bearbeiten
- Gemeldete Aufgaben übernehmen oder ablehnen
- Rückblick mit Zahlen und Bewertung, die als Vorschlag ins nächste Mal einfließen
- Preise je Person und Bestellartikel festlegen, erwartete Einnahmen und Bestellmengen sehen,
  Ausgaben in der Einkaufsliste erfassen, Saldo im Rückblick

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

Die Schritt-für-Schritt-[Anleitung](einrichtung/ANLEITUNG.md) im Ordner
[`einrichtung/`](einrichtung/) führt durch die Neuinstallation. Programme braucht es
dafür nicht, nur ein Supabase-Konto, den SFTP-Zugang zum Webspace und einen Browser.

1. **Supabase-Projekt anlegen**, Region Frankfurt, Konto auf den Verein.
2. **Datenbank einrichten:** `einrichtung/sql/neuinstallation.sql` im SQL-Editor von
   Supabase ausführen. Das legt alle Tabellen, Rechte und das nächtliche Aufräumen an
   und zeigt einmalig ein neu erzeugtes Orga-Passwort für den Passwortsafe.
   Danach `einrichtung/sql/pruefen.sql` ausführen; jede Zeile muss mit OK beginnen.
3. **Zugangsdaten eintragen:** In `config.js` unter `SUPABASE` die Projekt-URL und den
   `anonKey` eintragen. Das gilt für alle Seiten. Darunter unter `SETTINGS` optional
   Kitaname, Logo, Favicon und zwei Farben; leer lassen heißt Standardaussehen.
4. **Hochladen:** Die HTML-Dateien zusammen mit `config.js`, `common.js`, `common.css`,
   `eltern.css` und den Ordnern `fonts/` und `icons/` per SFTP in einen Unterordner des
   Webspace laden, zum Beispiel `/orga/`.

Die beiden SQL-Dateien werden mit `einrichtung/vorlage-erzeugen.sh` aus dem laufenden
Projekt erzeugt, nur Struktur, keine Daten, und nach jeder Migration neu mitgeliefert
(Anleitung, Abschnitt 10).

Bei Updates gilt: **erst SQL, dann HTML.** Sonst sucht die Seite nach Spalten, die es
in der Datenbank noch nicht gibt.

> **Hinweis:** Die echten Zugangsdaten werden nie committet. Im Repo bleiben die Felder
> in `config.js` leer. Lokal kann man die Werte in einer `supabase.env` ablegen,
> die über `.gitignore` ausgeschlossen ist.

## Umzug in ein anderes Supabase-Projekt

Soll das Tool samt Daten in ein anderes Supabase-Projekt oder Konto wechseln, etwa vom
privaten Konto eines Vorstands in das des Vereins, liegen dafür im Ordner
[`umzug/`](umzug/) Skripte für Windows, macOS und Linux und eine Schritt-für-Schritt-
[Anleitung](umzug/ANLEITUNG.md).

- Umgezogen werden alle Tabellen im Schema `public` mit Daten, Funktionen, Policies,
  Rechten und Cron-Aufträgen. Die persönlichen Links der Eltern und das Orga-Passwort
  bleiben gültig.
- Das alte Projekt wird nur gelesen. Ein Probelauf ist deshalb gefahrlos.
- Am Ende vergleicht das Skript Zeilenzahlen, Struktur und Rechte zwischen alt und neu
  und prüft über die Schnittstelle, dass die Token der Anmeldungen gesperrt sind.
- Gebraucht werden die PostgreSQL-Kommandozeilenwerkzeuge (`pg_dump`, `pg_restore`,
  `psql`) oder Docker.

Kurzfassung:

```bash
cd umzug
cp umzug.env.example umzug.env   # Zugangsdaten beider Projekte eintragen
./umzug.sh pruefen
./umzug.sh alles                 # Windows: umzug-windows.cmd alles
```

Danach in `config.js` URL und anonKey des neuen Projekts eintragen und hochladen.
Der Ordner `umzug/arbeit/` enthält dann eine vollständige Sicherung mit Elterndaten
und wird nach dem Umzug mit `./umzug.sh aufraeumen` gelöscht.

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
