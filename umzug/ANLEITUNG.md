# Umzug in ein anderes Supabase-Projekt

Diese Anleitung zieht das Kita-Orgatool mit allen Daten von einem Supabase-Projekt in
ein anderes um, etwa vom privaten Konto eines Vorstands in das Konto des Vereins.
Die Skripte in diesem Ordner erledigen die Arbeit; die Anleitung sagt, was vorher und
nachher von Hand zu tun ist.

| Datei | Zweck |
| --- | --- |
| `umzug.sh` | Skript für Linux und macOS |
| `umzug.ps1`, `umzug-windows.cmd` | Skript für Windows (die `.cmd` startet die `.ps1`) |
| `umzug.env.example` | Vorlage für die Zugangsdaten |
| `sql/` | Abfragen, die beide Skripte benutzen |
| `arbeit/` | entsteht beim Umzug, enthält die Sicherung – nie committen, danach löschen |

Zeitbedarf: eine Stunde Vorbereitung, der eigentliche Umzug dauert wenige Minuten.

## 1. Was umzieht und was nicht

**Umgezogen wird alles im Datenbankschema `public`:**

- alle Tabellen mit allen Daten: Veranstaltungen, Anmeldungen samt Token, Aufgaben,
  Fotos, Vorlagen, Planung, Meldungen, Rückmeldungen
- das Orga-Passwort aus `orga_keys` – es bleibt dasselbe
- Funktionen wie `is_orga()` und `daten_aufraeumen()`, Policies, Trigger
- die Rechte der Rolle `anon` genau so, wie sie im alten Projekt waren, einschließlich
  der gesperrten Spalte `signups.token`
- aktive Aufträge aus `pg_cron`, z. B. das nächtliche Aufräumen

Weil die Token mitziehen, funktionieren die persönlichen Links der Eltern weiter.

**Nicht umgezogen wird:**

- das alte Projekt selbst – es wird nur gelesen und bleibt unverändert stehen
- Einstellungen des Supabase-Projekts (Region, Tarif, Mitglieder, Backups)
- Supabase Auth und Storage – das Tool benutzt beides nicht
- die Dateien auf dem Webspace – dort ist nach dem Umzug nur `config.js` zu ändern

## 2. Werkzeuge installieren

Die Skripte brauchen die PostgreSQL-Kommandozeilenwerkzeuge `pg_dump`, `pg_restore`
und `psql`, **mindestens in der Hauptversion der Datenbank** (Supabase: derzeit 15
oder 17; im Dashboard unter Project Settings → Infrastructure). Die Skripte suchen die
Werkzeuge selbst und melden, wenn die Version nicht reicht. Ein PostgreSQL-Server
wird nicht gebraucht.

**Windows**

- Installationsprogramm von <https://www.postgresql.org/download/windows/> (EDB),
  Version 17. Bei der Auswahl der Bestandteile reicht **Command Line Tools**;
  Server, pgAdmin und Stack Builder abwählen.
- Oder in der Eingabeaufforderung: `winget install PostgreSQL.PostgreSQL.17`
- Das Skript findet die Werkzeuge unter `C:\Program Files\PostgreSQL\…\bin` auch
  ohne Eintrag im PATH.

**macOS** (mit [Homebrew](https://brew.sh))

```bash
brew install libpq
```

Das Skript findet `libpq` auch ohne `brew link`. Alternativ geht Postgres.app.

**Linux** (Debian, Ubuntu)

```bash
sudo apt install postgresql-client
```

Ist die Version der Distribution zu alt, das Paket `postgresql-client-17` aus dem
Paketarchiv von postgresql.org nehmen (<https://www.postgresql.org/download/linux/>).

**Ohne Installation, mit Docker**

Ist Docker (oder Docker Desktop) installiert und gestartet, holen die Skripte die
Werkzeuge selbst aus dem offiziellen Abbild `postgres:17-alpine`, wenn keine passende
lokale Installation da ist.

## 3. Neues Projekt vorbereiten

1. Im Zielkonto ein neues Projekt anlegen. Region wie bisher, für den Verein in der
   Regel **Frankfurt (eu-central-1)**. Die Postgres-Version des neuen Projekts muss
   gleich oder neuer sein als die des alten.
2. Das **Datenbank-Passwort** beim Anlegen notieren und im Passwortsafe des Vereins
   ablegen. Vergessen? Project Settings → Database → Reset database password.
3. Nichts im SQL-Editor ausführen, keine Tabellen anlegen – das neue Projekt soll leer
   sein. Die Skripte prüfen das.
4. Unter Database → Extensions nachsehen, ob `pgcrypto` an ist (Standard). Die
   Skripte melden im Schritt `pruefen`, falls Erweiterungen des alten Projekts fehlen.

Das **alte Projekt** darf nicht pausiert sein. Im kostenlosen Tarif pausiert Supabase
Projekte nach einer Woche ohne Zugriff; dann im Dashboard auf „Restore“ klicken und
warten, bis es wieder läuft.

## 4. Zugangsdaten eintragen

Im Ordner `umzug/` die Vorlage kopieren:

- Linux/macOS: `cp umzug.env.example umzug.env`
- Windows: `umzug.env.example` kopieren und die Kopie in `umzug.env` umbenennen
  (im Explorer Dateiendungen einblenden, sonst entsteht `umzug.env.txt`)

Dann `umzug.env` in einem Texteditor ausfüllen. Die Werte stehen im Dashboard des
jeweiligen Projekts oben unter **Connect** → Reiter „Direct“ → **Session pooler**:

| Eintrag | Wo im Dashboard | Beispiel |
| --- | --- | --- |
| `…_HOST` | host | `aws-0-eu-central-1.pooler.supabase.com` |
| `…_PORT` | port | `5432` |
| `…_USER` | user | `postgres.abcdefghijklmnopqrst` |
| `…_PASSWORT` | das Datenbank-Passwort aus Abschnitt 3 | |

Den **Session pooler** nehmen, nicht „Direct connection“ (geht nur über IPv6, was
viele Heimnetze nicht können) und nicht „Transaction pooler“ (Port 6543, bricht
`pg_dump` ab).

Empfohlen sind außerdem `NEU_URL` und `NEU_ANON_KEY` aus dem **neuen** Projekt
(Project Settings → API bzw. API Keys). Damit prüft das Skript am Ende über die
Schnittstelle, ob die Rechte so sind, wie die Seiten sie erwarten – vor allem, dass
niemand die Token der Anmeldungen lesen kann. Als Schlüssel den **anon-Schlüssel**
nehmen (beginnt mit `eyJ`, bei neueren Projekten unter „Legacy API Keys“). Die neuen
Schlüssel `sb_publishable_…` sind mit dem Tool nicht erprobt; der Test zeigt, ob sie
gehen.

`umzug.env` enthält Datenbank-Passwörter. Sie ist über `.gitignore` ausgeschlossen,
gehört nicht in Mails oder Chats und wird nach dem Umzug gelöscht.

## 5. Umzug durchführen

### Terminal öffnen

- **Windows:** Im Explorer den Ordner `umzug` öffnen, in die Adresszeile `cmd`
  tippen, Enter. Befehle beginnen mit `umzug-windows.cmd`.
- **macOS:** Terminal öffnen, `cd ` tippen (mit Leerzeichen), den Ordner `umzug` ins
  Fenster ziehen, Enter. Befehle beginnen mit `./umzug.sh`.
- **Linux:** Terminal im Ordner `umzug` öffnen. Befehle beginnen mit `./umzug.sh`.

Im Folgenden steht `./umzug.sh`; unter Windows jeweils `umzug-windows.cmd`
schreiben.

### Probelauf

Der Umzug lässt sich gefahrlos vorab ausprobieren, weil das alte Projekt nur gelesen
wird:

```bash
./umzug.sh pruefen
```

Das zeigt Werkzeuge, Versionen, fehlende Erweiterungen, Cron-Aufträge und die
Zeilenzahl je Tabelle. Wenn hier alles grün ist, einmal komplett durchspielen:

```bash
./umzug.sh sichern
./umzug.sh einspielen
```

`einspielen` endet mit einem Vergleich (Abschnitt 5, „Was der Vergleich prüft“). Stimmt
alles, ist das Verfahren erprobt. Die Seiten zeigen weiter auf das alte Projekt; es
ist nichts passiert, außer dass im neuen Projekt eine Kopie liegt.

### Der eigentliche Umzug

1. **Zeitfenster wählen**, in dem sich niemand anmeldet, am besten abends. Keine
   Anmeldelinks verteilen, laufende Anmeldungen vorher abschließen. Was nach der
   Sicherung noch im alten Projekt eingetragen wird, geht verloren; der Vergleich
   würde es aber bemerken.
2. Umzug starten. Nach einem Probelauf liegen im neuen Projekt schon Tabellen, dann
   mit `--ersetzen`:

   ```bash
   ./umzug.sh alles --ersetzen
   ```

   Ohne Probelauf reicht `./umzug.sh alles`. Das Skript fragt einmal nach, ob die
   Anmeldungen gestoppt sind, und läuft dann durch: prüfen, sichern, einspielen,
   Rechte setzen, Cron-Aufträge übertragen, vergleichen.
3. Die letzte Zeile muss lauten: **„Umzug vollständig.“** Sonst Abschnitt 8.

Die Schritte lassen sich auch einzeln aufrufen: `pruefen`, `sichern`, `einspielen`,
`cron`, `vergleichen`. `einspielen` nimmt immer die jüngste Sicherung aus `arbeit/`.

### Was der Vergleich prüft

- **Zeilen:** Jede Tabelle hat im neuen Projekt so viele Zeilen wie in der Sicherung.
- **Struktur und Rechte:** Tabellen, Spalten, Standardwerte, Policies, Schlüssel,
  Indizes, Trigger, Funktionen und die Rechte von `anon`, `authenticated` und
  `service_role` stimmen mit dem alten Projekt überein. Verglichen werden nur Namen
  und Prüfsummen, keine Inhalte.
- **Altes Projekt:** Ist dort seit der Sicherung etwas dazugekommen, meldet das
  Skript das.
- **Schnittstelle** (nur mit `NEU_URL` und `NEU_ANON_KEY`): Veranstaltungen und
  Anmeldungen sind lesbar, `signups.token` ist gesperrt, `orga_keys`, Vorlagen,
  Planung und Rückmeldungen geben ohne Orga-Passwort nichts heraus, ein falsches
  Orga-Passwort wird abgelehnt.

## 6. Seiten umstellen

Erst wenn der Vergleich „Umzug vollständig“ meldet:

1. In `config.js` auf dem Webspace unter `SUPABASE` die URL und den anonKey des
   **neuen** Projekts eintragen (Project Settings → API). Das gilt für alle Seiten.
   Im Repo bleiben die Felder leer (siehe `CLAUDE.md`, „Nicht ins Repo“).
2. `config.js` per SFTP in den Ordner `/orga/` hochladen. Die übrigen Dateien bleiben,
   wie sie sind.
3. Falls auf dem Webspace eine `.htaccess` mit Content-Security-Policy liegt, dort in
   `connect-src` die alte Supabase-Adresse durch die neue ersetzen, sonst blockiert
   der Browser jede Abfrage.
4. Im Browser mit neu geladener Seite (Strg+F5 bzw. Cmd+Shift+R) prüfen:
   - Übersicht zeigt die Veranstaltungen.
   - Testanmeldung anlegen, über den persönlichen Link ändern, wieder löschen.
   - Einen alten persönlichen Link aus der Zeit vor dem Umzug öffnen.
   - Orga-Bereich mit dem bisherigen Orga-Passwort öffnen; oben erscheint kein roter
     Hinweis „Die Datenbank ist nicht auf dem Stand dieser Version“.
   - Auf dem Handy die installierte App (Startbildschirm) einmal schließen und
     neu öffnen, damit sie die neue `config.js` lädt.

## 7. Abschließen

- **Sicherungen löschen.** `arbeit/` enthält alle Anmeldungen und das Orga-Passwort:

  ```bash
  ./umzug.sh aufraeumen
  ```

  Danach auch `umzug.env` löschen.
- **Cron-Auftrag kontrollieren**, am Tag nach dem Umzug im SQL-Editor des neuen
  Projekts: `select * from cron.job_run_details order by start_time desc limit 5;`
- **Automatische Sicherung umstellen**, falls es eine gibt (z. B. auf dem Vereins-NAS):
  Host, Benutzer und Passwort auf das neue Projekt ändern und einmal von Hand laufen
  lassen. Dasselbe für einen Keep-alive-Aufruf, der das Pausieren verhindert.
- **Zugangsdaten ablegen:** Datenbank-Passwort, Projekt-URL und Zugang zum
  Supabase-Konto in den Passwortsafe des Vereins.
- **Auftragsverarbeitung:** Prüfen, dass der Auftragsverarbeitungsvertrag (DPA) mit
  Supabase für das neue Konto abgeschlossen ist und auf den Verein lautet.
- **Altes Projekt** zwei bis vier Wochen stehen lassen, falls doch etwas fehlt. Dann
  im Dashboard löschen (Project Settings → General → Delete project) und das im
  Löschprotokoll des Vereins vermerken – dort lagen personenbezogene Daten.

## 8. Wenn etwas nicht passt

**„Keine Verbindung zum … Projekt“** – Host, Benutzer und Passwort in `umzug.env`
prüfen. Der Benutzer hat die Form `postgres.<projekt-id>`, nicht nur `postgres`.
Ist das Projekt pausiert? Firmennetze sperren manchmal Port 5432; dann von zu Hause
aus versuchen.

**„Werkzeuge sind Version 15, gebraucht wird 17“** – neuere Version installieren
(Abschnitt 2) oder Docker starten.

**„Im neuen Projekt gibt es schon Tabellen“** – Wenn die von einem früheren Versuch
stammen: `./umzug.sh einspielen --ersetzen`. Wenn jemand im neuen Projekt schon etwas
angelegt hat, erst klären, ob das weg darf.

**„Einspielen gescheitert“** – Das Einspielen läuft in einer einzigen Transaktion;
bei einem Fehler bleibt das neue Projekt, wie es war. Die Meldung darüber nennt das
Objekt. Häufigste Ursache ist eine fehlende Erweiterung (Database → Extensions),
danach erneut `./umzug.sh einspielen`.

**Abweichung bei den Zeilen** – Meist hat sich jemand während des Umzugs angemeldet.
`./umzug.sh sichern` und dann `./umzug.sh einspielen --ersetzen` wiederholen.

**Abweichung bei Struktur oder Rechten** – Zeilen mit `-` gibt es nur im alten, Zeilen
mit `+` nur im neuen Projekt. Eine Zeile `recht|signups|anon|SELECT` mit `+` heißt zum
Beispiel: `anon` darf im neuen Projekt die ganze Tabelle samt Token lesen. **Dann die
Seiten nicht umstellen**, sondern `./umzug.sh einspielen --ersetzen` wiederholen und,
falls es bleibt, jemanden mit SQL-Kenntnis draufschauen lassen. Abweichungen bei
`service_role` sind für das Tool ohne Belang, aber ein Hinweis, dass etwas anders
gelaufen ist als gedacht.

**„pg_cron ließ sich nicht einschalten“** – Im neuen Projekt unter Database →
Extensions `pg_cron` einschalten, dann `./umzug.sh cron`.

**Schnittstellentest schlägt fehl, Datenbankvergleich ist aber sauber** – Unter
Project Settings → API prüfen, ob die Data API an ist und `public` unter „Exposed
schemas“ steht. Mit einem `sb_publishable_…`-Schlüssel stattdessen den anon-Schlüssel
(Legacy API Keys) nehmen.

**Windows: „Die Ausführung von Skripts ist auf diesem System deaktiviert“** – Immer
über `umzug-windows.cmd` starten, nicht die `.ps1` direkt; die `.cmd` umgeht die
Richtlinie nur für diesen Aufruf.

**macOS/Linux: „Permission denied“** – `chmod +x umzug.sh` oder `bash umzug.sh …`.

## Anhang: Was die Skripte technisch tun

1. `pg_dump --format=custom --schema=public --schema=intern` sichert Schema und Daten
   des alten Projekts, dazu die Hilfsfunktionen im Schema `intern`, nach `arbeit/alt_<zeitpunkt>.dump`. Dazu kommen die Zeilenzahlen, ein
   Fingerabdruck von Struktur und Rechten (`sql/struktur.sql`) und die Cron-Aufträge
   (`sql/cron-export.sql`).
2. Das Inhaltsverzeichnis der Sicherung wird geteilt. Weggelassen werden das Schema
   `public` selbst, Erweiterungen und Standardrechte (`DEFAULT ACL`), die Supabase
   im neuen Projekt schon mitbringt.
3. `pg_restore --no-owner --single-transaction` spielt Tabellen, Daten, Funktionen,
   Policies und Trigger ein. Eigentümer ist danach die Rolle `postgres` des neuen
   Projekts.
4. Supabase gibt neu angelegten Tabellen automatisch alle Rechte für `anon`,
   `authenticated` und `service_role`. Deshalb nimmt `sql/rechte-leeren.sql` diesen
   Rollen zuerst alle Rechte in `public`, danach spielt `pg_restore` genau die Rechte
   aus der Sicherung ein. Ohne diesen Schritt könnte jeder über die Schnittstelle die
   Token der Anmeldungen lesen.
5. `notify pgrst, 'reload schema'` macht die Tabellen der Schnittstelle bekannt.
6. Die Cron-Aufträge werden mit `cron.schedule` angelegt; gleichnamige Aufträge werden
   dabei ersetzt.
7. Zeilenzahlen und Fingerabdruck werden im neuen Projekt erneut ermittelt und mit der
   Sicherung verglichen, anschließend folgt der Test über die Schnittstelle.

Die Verbindung läuft mit `sslmode=require`. Passwörter werden über Umgebungsvariablen
an die PostgreSQL-Werkzeuge gegeben, nicht auf der Kommandozeile.
