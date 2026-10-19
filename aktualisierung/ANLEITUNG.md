# Update auf eine neue Version

Diese Anleitung bringt ein laufendes Kita-Orgatool auf einen neueren Stand aus dem Repo.
Für die erste Einrichtung gibt es die [Neuinstallation](../einrichtung/ANLEITUNG.md), für
den Wechsel in ein anderes Supabase-Projekt den [Umzug](../umzug/ANLEITUNG.md).

Ein Update hat zwei Teile:

| Teil | Wo | Womit |
| --- | --- | --- |
| Datenbank | Supabase | neue `sql/migration-N.sql` im SQL-Editor ausführen |
| Seiten | Webspace, Ordner `/orga/` | geänderte Dateien per SFTP hochladen |

Die Reihenfolge ist verbindlich: **erst SQL, dann Dateien.** Neue Seiten fragen Spalten
ab, die erst die Migration anlegt. Umgekehrt ist es harmlos: Die alten Seiten
kommen mit einer neueren Datenbank in aller Regel zurecht, weil Migrationen Spalten und
Funktionen ergänzen statt sie wegzunehmen.

Programme braucht es dafür nicht, nur den Zugang zum Supabase-Dashboard, den
SFTP-Zugang und einen Browser. Zeitbedarf: eine halbe Stunde.

## 1. Welcher Stand läuft gerade?

Die Datenbank führt keine Versionsnummer. Deshalb:

- **Im Passwortsafe oder in den Vereinsunterlagen notieren**, welcher Stand eingespielt
  ist: Datum, Commit (die ersten sieben Zeichen reichen, etwa `3e1068e`) und die
  Nummer der letzten ausgeführten Migration. Das ist der wichtigste Handgriff dieser
  Anleitung. Ohne ihn muss man beim nächsten Update raten.
- Fehlt die Notiz, hilft `einrichtung/sql/pruefen.sql` aus dem Commit, mit dem
  eingerichtet oder zuletzt aktualisiert wurde: Meldet sie nur OK, ist das genau dieser
  Stand. Meldet sie FEHLT, ist die Datenbank älter; meldet sie ZUVIEL, ist sie neuer.
- Der Orga-Bereich prüft beim Anmelden, ob alle Spalten da sind, die seine Version
  braucht. Ein roter Hinweis „Die Datenbank ist nicht auf dem Stand dieser Version“
  nennt die fehlenden Spalten beim Namen.

## 2. Was ist neu?

Im Repo die Commits seit dem notierten Stand ansehen, auf GitHub unter **Commits** oder
im Terminal:

```bash
git log --oneline 3e1068e..HEAD
```

Daran sieht man:

- **Neue Dateien in `sql/`**: Das sind die Migrationen, die eingespielt werden müssen,
  in aufsteigender Nummer. Gibt es keine, besteht das Update nur aus Dateien; weiter mit
  Abschnitt 5.
- **Geänderte Seiten und gemeinsame Dateien**: Die kommen in Abschnitt 5 auf den
  Webspace.
- **Änderungen an `config.js`**: Neue Einträge von Hand in die eigene `config.js`
  übernehmen, siehe Abschnitt 5.
- **Änderungen an Aufbewahrung oder Sichtbarkeit**: Die ändern den Einwilligungstext auf
  der Anmeldeseite und damit, was der Verein den Eltern zusagt. Vorher im Vorstand
  absprechen.

## 3. Vorbereiten

- **Zeitpunkt:** abends oder zwischen zwei Veranstaltungen, nicht während eine
  Anmeldung läuft. Das Update dauert Minuten; Eltern, die genau dann eine Seite offen
  haben, sehen im schlimmsten Fall eine Fehlermeldung und laden neu.
- **Sicherung der Datenbank**, wenn eine Migration dabei ist. Migrationen lassen sich
  nicht rückgängig machen. Die Sicherung geht mit `pg_dump` über den Session Pooler
  (siehe [Neuinstallation](../einrichtung/ANLEITUNG.md), Abschnitt 8). Sie enthält
  Elterndaten: verschlüsselt ablegen und nach dem Update verwerfen, sobald alles läuft.
- **Kopie der Dateien vom Webspace**: den Ordner `/orga/` einmal per SFTP
  herunterladen. Damit lässt sich jede Seite in Sekunden zurückholen, und die eigene
  `config.js` samt Logo ist gesichert.
- **Projekt wach?** Im kostenlosen Tarif nachsehen, ob das Supabase-Projekt pausiert ist,
  und gegebenenfalls „Restore“ klicken.

## 4. Datenbank aktualisieren

Für **jede** noch nicht eingespielte Migration, in aufsteigender Nummer:

1. Im Supabase-Dashboard links **SQL Editor** → **New query**.
2. Den gesamten Inhalt von `sql/migration-N.sql` hineinkopieren.
3. Oben in der Datei steht, was sie ändert und ob etwas zu beachten ist. Lesen.
4. **Run**. Eine Warnung vor einer „destructive operation“ erscheint, sobald eine
   Migration Rechte entzieht oder Policies ersetzt; das ist normal.
5. Erst wenn sie ohne Fehler durchgelaufen ist, die nächste.

Migrationen sind so geschrieben, dass sie mehrfach laufen dürfen. Wer nicht sicher ist,
ob eine schon eingespielt ist, führt sie einfach noch einmal aus. Eine **übersprungene**
Migration dagegen fällt oft erst später auf, weil spätere Dateien Funktionen aus
früheren ersetzen. Deshalb keine auslassen und die Reihenfolge einhalten.

Bricht eine Migration mit Fehler ab, **nicht weitermachen** und keine Seiten hochladen.
Die alten Seiten laufen weiter. Die Fehlermeldung aufheben und Abschnitt 8 lesen.

**Danach prüfen:** `einrichtung/sql/pruefen.sql` aus dem **neuen** Stand in einer
neuen Query ausführen. Jede Zeile muss mit OK beginnen. Die Datei beschreibt die
Datenbank so, wie sie nach allen Migrationen aussehen soll, und findet deshalb auch
eine vergessene Migration oder fehlende Rechte.

## 5. Dateien hochladen

Per SFTP in den Zielordner, meist `/orga/`. Hochgeladen wird, was sich geändert hat;
im Zweifel alle Dateien aus dieser Liste, das schadet nicht:

```
index.html
fest-anmeldung.html
orga.html
vorschlag.html
feedback.html
common.js
common.css
eltern.css
manifest-eltern.json
manifest-orga.json
fonts/               ← ganzer Ordner
icons/               ← nur neue Standarddateien, siehe unten
```

**Nicht überschreiben:**

- **`config.js`** – Die Datei auf dem Webspace enthält die echte Projektadresse, den
  anonKey und das eigene Aussehen. Die `config.js` im Repo hat leere Felder; wer sie
  hochlädt, schaltet alle Seiten in den Demo-Modus. Hat sich `config.js` im Repo
  geändert, die neuen Einträge von Hand in die eigene Kopie übernehmen. Fehlende
  Einträge führen nicht zu Fehlern, die Seiten nehmen dann den Standard.
- **Eigene Bilder in `icons/`** – Eigenes Logo und Favicon bleiben liegen. Nur Dateien
  hochladen, die im Repo neu dazugekommen sind.
- **`.htaccess`** auf dem Webspace – nur anpassen, wenn das Update das ausdrücklich
  verlangt, etwa eine neue Quelle in der Content-Security-Policy.

Nicht hochladen: `aktualisierung/`, `einrichtung/`, `umzug/`, `README.md`,
`CLAUDE.md`, `.git*`.

## 6. Ausprobieren

Browser speichern Skripte und Stile zwischen. Deshalb jede Seite einmal **hart neu
laden** (Strg+F5, am Mac Cmd+Shift+R). Auf dem Handy, wo die Seiten als App auf dem
Startbildschirm liegen, die App ganz schließen und neu öffnen; hilft das nicht, im
Browser des Handys die Seite einmal direkt aufrufen und neu laden.

1. `orga.html` öffnen und anmelden. Oben darf **kein** roter Hinweis zur Datenbank
   stehen.
2. Eine bestehende Veranstaltung öffnen, etwas ändern, speichern, zurückändern.
3. `index.html` und die Anmeldeseite einer Veranstaltung öffnen. Stimmt der
   Einwilligungstext noch mit dem überein, was der Verein zusagt?
4. Was das Update neu bringt, einmal ausprobieren.

Dem Orgateam kurz Bescheid geben, dass es neu laden soll, falls etwas seltsam aussieht.

## 7. Abschließen

- Den neuen Stand notieren: Datum, Commit, Nummer der letzten Migration (Abschnitt 1).
- Die Datenbanksicherung aus Abschnitt 3 löschen, wenn nach ein paar Tagen alles läuft.
  Sie enthält Elterndaten.

## 8. Wenn etwas nicht passt

**Roter Hinweis „Die Datenbank ist nicht auf dem Stand dieser Version“** – Eine
Migration fehlt oder ist abgebrochen. Die genannten Spalten zeigen, welche. Migration
ausführen, Seite neu laden. Bis dahin nichts anlegen, sonst schlägt das Speichern fehl.

**„Der Datenbank fehlt eine Spalte“ beim Speichern** – Dasselbe. Das Fenster offen
lassen, dann sind die Eingaben nicht verloren; Migration einspielen und erneut
speichern.

**Die Seiten zeigen nur Beispieldaten** – Die `config.js` aus dem Repo wurde
hochgeladen. Die eigene Kopie aus Abschnitt 3 wieder hochladen.

**Eine Seite bleibt weiß oder reagiert nicht** – Meist passen Seite und `common.js`
nicht zusammen, weil eine von beiden noch aus dem Zwischenspeicher kommt oder nicht
hochgeladen wurde. Alle Dateien aus Abschnitt 5 hochladen, hart neu laden. Hilft das
nicht, die heruntergeladene Kopie wieder hochladen: Die alten Seiten laufen mit der
neuen Datenbank.

**Eine Migration bricht mit Fehler ab** – Nichts hochladen. Eine Migration ist entweder
ganz oder gar nicht durchgelaufen, wenn sie in `begin … commit` steht; sonst kann ein
Teil angelegt sein. Weil Migrationen mehrfach laufen dürfen, lässt sie sich nach
Behebung der Ursache erneut ausführen. Häufige Ursachen: eine frühere Migration fehlt,
oder eine Erweiterung ist nicht eingeschaltet (Database → Extensions). Sonst die
Fehlermeldung an jemanden mit SQL-Kenntnis geben.

**`pruefen.sql` meldet FEHLT oder ZUVIEL** – Die Zeile nennt Art und Namen. FEHLT heißt
meist: Migration vergessen. ZUVIEL heißt: Im Projekt steht etwas, das die Vorlage nicht
kennt, etwa von Hand angelegt. Das ist nicht gefährlich, sollte aber jemand ansehen.

**`pruefen.sql` meldet GEFAHR** – Über die Schnittstelle ist mehr lesbar als
vorgesehen. Dem sofort nachgehen, bei Elterndaten notfalls die Seiten vom Webspace
nehmen, bis es geklärt ist.

**Zurück zur alten Version** – Seiten: die Kopie aus Abschnitt 3 hochladen. Datenbank:
Migrationen lassen sich nicht zurücknehmen, sind aber so gebaut, dass alte Seiten
weiterlaufen. Die Sicherung nur einspielen, wenn Daten beschädigt sind; alles, was seit
der Sicherung eingetragen wurde, ginge dabei verloren.

## 9. Für Betreuer: ein Update bereitstellen

Wer am Code arbeitet, liefert Updates so, dass die Schritte oben reichen.

**Änderung am Datenmodell**

1. Neue Datei `sql/migration-N.sql` mit der nächsten freien Nummer. Bestehende
   Migrationen nie ändern, sie sind irgendwo schon eingespielt.
2. Mehrfach ausführbar schreiben: `if not exists`, `create or replace`,
   `drop policy if exists` vor `create policy`.
3. Oben in die Datei einen Kopf auf Deutsch: was sie ändert, welche Migration sie
   voraussetzt, ob danach etwas von Hand zu tun ist.
4. Spalten ergänzen, nicht umbenennen oder löschen, solange die vorige Version der
   Seiten sie noch liest. Aufräumen in einer späteren Migration.
5. In `orga.html` die Liste `NEEDED` um neue Spalten erweitern, damit die
   Versionsprüfung sie beim Namen nennt.
6. Migration im laufenden Projekt einspielen, dann `einrichtung/vorlage-erzeugen.sh`
   laufen lassen ([Neuinstallation](../einrichtung/ANLEITUNG.md), Abschnitt 10).

**Commit**

Migration, erneuerte Vorlage in `einrichtung/sql/` und geänderte Seiten gehören in
**einen** Commit. Dann passt jeder Stand im Repo in sich: Seiten, Migrationen und
`pruefen.sql` beschreiben dieselbe Datenbank. In der Commit-Nachricht erwähnen, dass
eine Migration dabei ist und ob `config.js` neue Einträge hat.

**Änderung an `config.js`**

Neue Einträge immer mit Standardwert im Code, sodass eine ältere `config.js` ohne den
Eintrag weiter funktioniert. Wer aktualisiert, überschreibt seine `config.js` nicht und
bekommt neue Einträge sonst nie.
