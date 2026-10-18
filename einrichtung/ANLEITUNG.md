# Neuinstallation

Diese Anleitung richtet das Kita-Orgatool von Grund auf neu ein: neues Supabase-Projekt,
leere Datenbank, eigenes Orga-Passwort, Seiten auf dem Webspace. Für den Wechsel eines
bestehenden Tools samt Daten in ein anderes Projekt gibt es den [Umzug](../umzug/ANLEITUNG.md),
für spätere Updates die [Aktualisierung](../aktualisierung/ANLEITUNG.md).

Für die Einrichtung selbst braucht es **keine Programme**: Die Datenbank wird im
Browser über den SQL-Editor von Supabase angelegt, die Dateien kommen per SFTP auf den
Webspace.

| Datei | Zweck |
| --- | --- |
| `sql/neuinstallation.sql` | legt Tabellen, Funktionen, Policies, Rechte, Cron-Auftrag und Orga-Passwort an |
| `sql/pruefen.sql` | prüft danach, ob alles so ist wie in der Vorlage |
| `vorlage-erzeugen.sh` | erzeugt die beiden SQL-Dateien aus einem laufenden Projekt (nur für Betreuer, Abschnitt 10) |
| `vorlage.env.example` | Vorlage für die Zugangsdaten dazu |

> **Fehlt `sql/neuinstallation.sql`?** Dann wurde die Vorlage noch nicht erzeugt.
> Das macht einmalig jemand mit Zugang zum laufenden Projekt, siehe Abschnitt 10.
> Das SQL im Kommentar oben in `orga.html` reicht **nicht**: Es deckt nur einen Teil
> der Tabellen ab und enthält weder Aufgaben, Fotos, Meldungen und Rückmeldungen
> noch das automatische Aufräumen.

Zeitbedarf: etwa eine Stunde.

## 1. Vorher klären

- **Wem gehört das Supabase-Konto?** Dem Verein, nicht einer Privatperson. Am besten
  mit einer Vereins-Mailadresse anlegen, auf die mehrere Vorstandsmitglieder Zugriff
  haben. Sonst steht beim nächsten Vorstandswechsel ein Umzug an.
- **Webspace:** SFTP-Zugang und ein Unterordner, etwa `/orga/` neben der
  Vereins-Website.
- **Passwortsafe des Vereins:** Hier landen am Ende Datenbank-Passwort, Orga-Passwort,
  Projektadresse und der Zugang zum Supabase-Konto.
- **Datenschutz:** Auftragsverarbeitungsvertrag (DPA) mit Supabase auf den Verein
  abschließen (im Dashboard in den Einstellungen der Organisation). Das Tool in das
  Verzeichnis der Verarbeitungstätigkeiten aufnehmen.

## 2. Supabase-Projekt anlegen

1. Auf <https://supabase.com> anmelden, **New project**.
2. **Region:** Central EU (Frankfurt), damit die Daten in der EU liegen.
3. **Database Password:** über „Generate a password“ erzeugen und **sofort** in den
   Passwortsafe übernehmen. Es wird für Sicherungen und einen späteren Umzug gebraucht,
   nicht für den Alltag.
4. Unter **Security** bzw. **Data API** (je nach Stand des Dashboards):
   - Data API **eingeschaltet** lassen – die Seiten sprechen die Datenbank darüber an.
   - „Automatically expose new tables“ darf an oder aus sein; das Einrichtungsskript
     setzt die Rechte ohnehin selbst.
5. Warten, bis das Projekt bereit ist (ein, zwei Minuten).

## 3. Datenbank einrichten

1. Im Dashboard links **SQL Editor** → **New query**.
2. Den **gesamten Inhalt** von `sql/neuinstallation.sql` hineinkopieren (Datei in einem
   Texteditor öffnen, alles markieren, kopieren).
3. **Run** klicken. Supabase warnt eventuell vor einer „destructive operation“, weil das
   Skript Rechte entzieht – bestätigen.
4. Unten erscheint eine Zeile **„Orga-Passwort – jetzt in den Passwortsafe
   übernehmen“**. Das Passwort genau so kopieren und in den Passwortsafe legen.
   **Es wird nur dieses eine Mal angezeigt.** Die Datenbank hat es selbst erzeugt; es
   steht deshalb nirgends im Verlauf des SQL-Editors.
5. Eine neue Query öffnen, den Inhalt von `sql/pruefen.sql` hineinkopieren, **Run**.
   Jede Ergebniszeile muss mit **OK** beginnen:

   ```
   OK: Tabellen, Spalten, Policies, Funktionen und Rechte wie in der Vorlage
   OK: signups.token ist gesperrt
   OK: orga_keys ist gesperrt
   OK: Orga-Passwort angelegt
   OK: 1 Cron-Auftrag/Aufträge aktiv
   ```

   Bei **GEFAHR** oder **FEHLT** nicht weitermachen, sondern Abschnitt 9 lesen.

Das Skript läuft in einer einzigen Transaktion. Bricht es mit einer Fehlermeldung ab,
ist nichts angelegt worden, und es kann nach Behebung der Ursache einfach noch einmal
laufen.

**Ist das Orga-Passwort verloren** oder soll es nach einem Vorstandswechsel neu sein,
im SQL-Editor ein neues erzeugen lassen. Das alte gilt danach nicht mehr:

```sql
with alt as (delete from orga_keys),
     neu as (select translate(encode(extensions.gen_random_bytes(24), 'base64'), '+/', '-_') as p)
insert into orga_keys (secret, label)
select p, 'Orgateam' from neu
returning secret as "Neues Orga-Passwort";
```

Speichert die Datenbank das Passwort inzwischen als Hash (Spalte `key_hash`), steht die
passende Anweisung in der zugehörigen Migrationsdatei.

## 4. Zugangsdaten in `config.js`

Im Dashboard unter **Project Settings → API** (bzw. **API Keys**):

- **Project URL**, z. B. `https://abcdefghijklmnopqrst.supabase.co`
- **anon public key**, beginnt mit `eyJ`. Bei neueren Projekten steht er unter
  **Legacy API Keys**. Die neuen Schlüssel `sb_publishable_…` sind mit dem Tool nicht
  erprobt.

Beide in eine **Kopie** von `config.js` eintragen, die nur für den Webspace bestimmt ist:

```js
const SUPABASE = { url:"https://abcdefghijklmnopqrst.supabase.co", anonKey:"eyJ…" };
```

Der anonKey darf öffentlich sein – er steht ohnehin in jeder ausgelieferten Seite; was
man damit darf, entscheidet die Datenbank. Der **`service_role`-Schlüssel** dagegen
gehört **nie** in eine Datei. In der `config.js` im Repo bleiben die Felder leer.

## 5. Aussehen einstellen

In derselben `config.js` unter `SETTINGS`:

| Eintrag | Wirkung |
| --- | --- |
| `name` | Name der Kita im Kopf aller Seiten und im Seitentitel |
| `logo` | eigenes Logo, quadratisch, etwa 80 px, PNG oder SVG; leer = kein Logo |
| `favicon` | Symbol im Browser-Tab, PNG 64 × 64 px |
| `colors.main` | Hauptfarbe für Knöpfe, Haken, Balken, z. B. `"#3F5540"` |
| `colors.accent` | Farbe für Warnungen, Absagen, Fehlendes, z. B. `"#8C4A5C"` |

Leere Werte bedeuten Standard. Eigene Bilder in den Ordner `icons/` legen und als
relativen Pfad eintragen (`"icons/logo.png"`). Adressen anderer Websites werden
ignoriert, weil die Seiten nichts von fremden Servern laden.

## 6. Hochladen

Per SFTP in den Zielordner, etwa `/orga/`:

```
index.html
fest-anmeldung.html
orga.html
vorschlag.html
feedback.html
config.js            ← die Kopie mit den echten Werten
common.js
common.css
eltern.css
fonts/               ← ganzer Ordner
icons/               ← ganzer Ordner, samt eigenem Logo
```

Nicht hochladen: `aktualisierung/`, `einrichtung/`, `umzug/`, `README.md`, `CLAUDE.md`, `.git*`.

Liegt im Zielordner oder darüber eine `.htaccess` mit Content-Security-Policy, muss dort
unter `connect-src` die Project URL stehen, sonst blockiert der Browser jede Abfrage.

## 7. Ausprobieren

Im Browser, mit neu geladener Seite (Strg+F5 bzw. Cmd+Shift+R):

1. `…/orga/index.html` öffnen: Kopf mit Kitaname, noch keine Veranstaltungen.
2. `…/orga/orga.html` öffnen und mit dem Orga-Passwort anmelden. Oben darf **kein**
   roter Hinweis „Die Datenbank ist nicht auf dem Stand dieser Version“ stehen.
3. Testveranstaltung mit Datum anlegen, eine Aufgabe und eine Mitbringsel-Kategorie
   dazu.
4. Über den Link der Veranstaltung als „Elternteil“ anmelden, den persönlichen Link
   öffnen, die Anmeldung ändern und wieder löschen.
5. Testveranstaltung im Orga-Bereich löschen.
6. Den Link zu `index.html` an das Orgateam geben; die Seiten lassen sich auf dem Handy
   über „Zum Startbildschirm hinzufügen“ wie eine App ablegen.

## 8. Betrieb absichern

- **Aufräumen:** `daten_aufraeumen()` löscht Anmeldungen nach der Frist und
  anonymisiert alte Namen. Am Tag nach der Einrichtung im SQL-Editor nachsehen, ob der
  Auftrag gelaufen ist:

  ```sql
  select jobname, status, start_time from cron.job_run_details
   order by start_time desc limit 5;
  ```

- **Pausieren:** Im kostenlosen Tarif pausiert Supabase ein Projekt nach einer Woche
  ohne Zugriff. Zwischen den Festen ist das normal. Ein regelmäßiger Abruf (etwa von
  einem Vereins-NAS oder einem Cron-Dienst) verhindert es; sonst vor jeder Veranstaltung
  im Dashboard nachsehen und gegebenenfalls „Restore“ klicken.
- **Sicherungen:** Der kostenlose Tarif hat keine herunterladbaren Sicherungen. Eine
  eigene Sicherung geht mit `pg_dump` über den Session Pooler (wie in
  [umzug/ANLEITUNG.md](../umzug/ANLEITUNG.md), Abschnitt 4 beschrieben), täglich etwa
  mit [nas/backup.sh](../nas/backup.sh) auf dem Vereins-NAS. Sicherungen
  enthalten Elterndaten: verschlüsselt ablegen und nach der Löschfrist verwerfen.
- **Einwilligungstext:** Auf der Anmeldeseite prüfen, ob der automatisch erzeugte Text
  zu dem passt, was der Verein den Eltern zusagt (Löschfrist, wer die Anmeldungen
  sieht).
- **Passwortsafe**, vollständig: Zugang zum Supabase-Konto, Datenbank-Passwort,
  Orga-Passwort, Project URL, SFTP-Zugang zum Webspace.
- **Stand notieren:** Datum und Commit, mit dem eingerichtet wurde. Das nächste Update
  setzt dort an ([Aktualisierung](../aktualisierung/ANLEITUNG.md), Abschnitt 1).

## 9. Wenn etwas nicht passt

**„In diesem Projekt gibt es schon Tabellen des Orgatools“** – Das Projekt ist nicht
leer, vermutlich lief das Skript schon einmal erfolgreich. Mit `pruefen.sql`
nachsehen. Zum Neuanfang das Projekt im Dashboard löschen und neu anlegen.

**„extension … is not available“** – Die Erweiterung unter Database → Extensions
einschalten, dann das Skript erneut ausführen.

**„permission denied for schema cron“ oder Fehler bei `cron.schedule`** – Unter
Database → Extensions `pg_cron` einschalten, dann das Skript erneut ausführen.

**`pruefen.sql` meldet FEHLT oder ZUVIEL** – Die Zeile nennt Art und Namen, etwa
`FEHLT: recht|events|anon|SELECT`. Meist ist die Vorlage älter als das Projekt, aus
dem sie stammt, oder eine Migration wurde zusätzlich eingespielt. Vorlage neu erzeugen
lassen (Abschnitt 10) oder jemanden mit SQL-Kenntnis draufschauen lassen.

**`pruefen.sql` meldet GEFAHR** – Dann kann jeder über die Schnittstelle mehr lesen als
vorgesehen. Seiten nicht freigeben. Projekt löschen, neu anlegen, Skript erneut
ausführen; bleibt es, Vorlage prüfen lassen.

**Die Seiten zeigen nur Beispieldaten** – `config.js` auf dem Webspace hat noch leere
Werte, oder der Browser hat die alte Datei zwischengespeichert (Strg+F5).

**„Server nicht erreichbar“ beim Orga-Login** – Project URL in `config.js` prüfen, ob
das Projekt pausiert ist, und ob unter Project Settings → API die Data API an ist und
`public` unter „Exposed schemas“ steht.

**Orga-Passwort wird abgelehnt** – Leerzeichen am Anfang oder Ende mitkopiert? Sonst
ein neues setzen (Abschnitt 3).

## 10. Für Betreuer: Vorlage erzeugen und aktuell halten

`sql/neuinstallation.sql` und `sql/pruefen.sql` werden nicht von Hand geschrieben,
sondern aus einem laufenden, vollständig migrierten Projekt erzeugt. Damit entspricht
eine Neuinstallation genau dem Stand, der im Betrieb erprobt ist.

**Wann:** einmal zu Beginn und danach nach jeder neuen `migration-N.sql`, die im
laufenden Projekt eingespielt wurde. Die Vorlage im selben Commit wie die Migration
mitliefern, dann passt sie immer zu den Seiten im Repo.

**Was gelesen wird:** nur die Struktur im Schema `public` (Tabellen, Funktionen,
Policies, Trigger, Rechte), die Liste der Erweiterungen und die Cron-Aufträge. Keine
Anmeldungen, keine Veranstaltungen, kein Orga-Passwort. Das Projekt wird nicht
verändert.

**Werkzeuge:** PostgreSQL-Kommandozeilenwerkzeuge oder Docker, wie beim Umzug
([umzug/ANLEITUNG.md](../umzug/ANLEITUNG.md), Abschnitt 2). Das Skript läuft unter
Linux und macOS, unter Windows in WSL oder Git Bash.

```bash
cd einrichtung
cp vorlage.env.example vorlage.env   # Session-Pooler-Zugang des laufenden Projekts
./vorlage-erzeugen.sh
git diff sql/                        # durchsehen, vor allem die Cron-Aufträge am Ende
rm vorlage.env
```

Das Skript warnt, wenn in der Vorlage etwas nach Schlüssel oder Projektadresse
aussieht, etwa ein Cron-Auftrag, der eine URL mit Schlüssel aufruft. Solche Stellen
gehören nicht ins Repo. Die Vorlage enthält sonst nur, was ohnehin in den
Migrationsdateien steht.

**Wie das Skript arbeitet:** `pg_dump --schema-only` liest die Struktur, `pg_restore`
schreibt sie als SQL. Weggelassen werden das Schema `public` und Erweiterungen, die
Supabase mitbringt, sowie psql-Befehle, die der SQL-Editor nicht versteht. Wie beim
Umzug werden die Rechte getrennt geschrieben: Supabase gibt neuen Tabellen alle Rechte
für `anon`, deshalb entzieht `neuinstallation.sql` sie zuerst
(`umzug/sql/rechte-leeren.sql`) und setzt dann genau die Rechte des Quellprojekts. Für
`pruefen.sql` wird der Fingerabdruck aus `umzug/sql/struktur.sql` des Quellprojekts
eingebettet und im neuen Projekt verglichen.

**Testen**, bevor eine neue Vorlage committet wird: in einem Wegwerf-Projekt Abschnitt 3
durchspielen, `pruefen.sql` muss nur OK melden. Danach das Projekt löschen.
