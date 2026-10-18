# Technik betreuen

Für die Person, die das Kita-Orgatool betreut, meist jemand aus dem Vorstand. Diese
Seite ist ein Überblick: was es gibt, wo es steht, was regelmäßig zu tun ist. Die
einzelnen Abläufe stehen in den vorhandenen Anleitungen, auf die hier verwiesen wird:

| Anleitung | Wofür |
| --- | --- |
| [Neuinstallation](../einrichtung/ANLEITUNG.md) | Tool von Grund auf neu einrichten |
| [Aktualisierung](../aktualisierung/ANLEITUNG.md) | Laufendes Tool auf einen neuen Stand bringen |
| [Umzug](../umzug/ANLEITUNG.md) | Tool samt Daten in ein anderes Supabase-Projekt bringen |
| [README](../README.md) | Was das Tool kann |
| [CLAUDE.md](../CLAUDE.md) | Regeln für Änderungen am Code |

## Inhalt

1. [Aufbau](#1-aufbau)
2. [Aussehen anpassen](#2-aussehen-anpassen)
3. [Orga-Passwort ändern](#3-orga-passwort-ändern)
4. [Aufräumen und Fristen](#4-aufräumen-und-fristen)
5. [Backup und Keep-alive auf dem NAS](#5-backup-und-keep-alive-auf-dem-nas)
6. [Aktualisieren](#6-aktualisieren)
7. [Umzug](#7-umzug)
8. [Übergabe an den nächsten Vorstand](#8-übergabe-an-den-nächsten-vorstand)
9. [Fehlersuche](#9-fehlersuche)

## 1. Aufbau

Das Tool besteht aus zwei Teilen: Dateien auf dem Webspace und einer Datenbank bei
Supabase. Ein Programm, das gebaut oder gestartet werden muss, gibt es nicht.

### Dateien auf dem Webspace

Alles liegt in einem Unterordner der Vereins-Website, meist `/orga/`.

| Datei | Für wen | Zweck |
| --- | --- | --- |
| `index.html` | Eltern | Übersicht offener Veranstaltungen |
| `fest-anmeldung.html` | Eltern | Anmeldung, Mitbringsel, Aufgaben, Check-in |
| `feedback.html` | Eltern | Rückmeldung nach der Veranstaltung |
| `vorschlag.html` | Leitung, Vorstand, Teams | Aufgaben melden |
| `orga.html` | Orgateam | To-dos, Veranstaltungen, Vorlagen, Planung, Auswertung |
| `config.js` | alle Seiten | Zugang zur Datenbank und Aussehen. **Die einzige Datei mit euren eigenen Werten.** |
| `common.js`, `common.css`, `eltern.css` | alle Seiten | gemeinsame Hilfsfunktionen und Gestaltung |
| `fonts/` | alle Seiten | Schriften, liegen lokal |
| `icons/` | alle Seiten | Logo und Favicon |
| `.htaccess` | Webserver | Sicherheitsregeln, Vorlage in `deploy/.htaccess` |

Die Seiten laden nichts von fremden Servern. Die einzige Verbindung nach außen ist die
eigene Supabase-Datenbank.

`deploy/.htaccess` setzt unter anderem eine Content-Security-Policy. Vor dem Hochladen
dort `PROJEKT-REF` durch die eigene Project URL ersetzen, sonst blockiert der Browser
jede Abfrage an die Datenbank. Außerdem sorgt sie dafür, dass Browser nach einem Update
die neuen Dateien holen (`Cache-Control: no-cache`).

### Datenbank

Supabase ist ein Postgres-Datenbankdienst. Die Seiten sprechen ihn direkt über seine
Schnittstelle an. Es gibt zwölf Tabellen:

| Tabelle | Inhalt | Wer liest |
| --- | --- | --- |
| `events` | Veranstaltungen mit Kategorien, Aufgaben, Zusatzfragen, Fristen | alle |
| `signups` | Anmeldungen und Absagen | alle, außer der Spalte `token` |
| `task_claims` | übernommene Aufgaben am Tag | alle |
| `task_images` | Fotos zu Aufgaben | alle |
| `templates` | Vorlagen für wiederkehrende Veranstaltungen | nur Orgateam |
| `planning` | Checkliste, Einkaufsliste, Rückblick | nur Orgateam |
| `proposals` | gemeldete Aufgaben | Melder alle außer abgelehnten, Orgateam alles |
| `feedback` | Rückmeldungen der Eltern | nur Orgateam |
| `payments` | Zahlungseingang je Anmeldung | nur Orgateam |
| `attendance` | Check-in: gekommen, gegangen, Stunden | nur Orgateam |
| `checkin_codes` | Code vom Aushang je Veranstaltung | nur Orgateam |
| `orga_keys` | Orga-Passwort | niemand über die Schnittstelle |

Die SQL-Dateien im Ordner `sql/`:

- `schema.sql`: der erste Stand der Datenbank
- `migration-2.sql` bis `migration-25.sql`: alle späteren Änderungen, in dieser
  Reihenfolge. Oben in jeder Datei steht, was sie ändert.

Für eine Neuinstallation werden sie nicht einzeln ausgeführt, sondern
`einrichtung/sql/neuinstallation.sql`. Diese Datei wird aus einem laufenden Projekt
erzeugt ([Neuinstallation](../einrichtung/ANLEITUNG.md), Abschnitt 10).

### Drei Stufen von Rechten

Es gibt keine Benutzerkonten. Alle Seiten benutzen denselben öffentlichen Schlüssel
(`anonKey`). Er steht absichtlich lesbar in `config.js` und sagt nur, welches Projekt
gemeint ist. Was jemand damit darf, entscheidet die Datenbank.

| Stufe | Wer | Woran die Datenbank es erkennt | Was erlaubt ist |
| --- | --- | --- | --- |
| Anonym | jeder mit einem Link | nichts weiter | Veranstaltungen lesen, sich anmelden, Aufgaben melden, Rückmeldung geben |
| Eigener Eintrag | wer eine Anmeldung abgeschickt hat | Zufallscode im persönlichen Link | die eigene Anmeldung ändern oder löschen |
| Orgateam | wer das Orga-Passwort kennt | Passwort aus `orga_keys`, geprüft von `is_orga()` | alles im Orga-Bereich |

Daraus folgt für dich:

- Wer etwas an den Seiten ändert, kann damit keine Rechte erweitern. Rechte stehen nur
  in der Datenbank.
- Der **`service_role`-Schlüssel** von Supabase gehört nie in eine Datei, auch nicht
  aufs NAS.

## 2. Aussehen anpassen

In `config.js` auf dem Webspace unter `SETTINGS`. Leere Werte bedeuten Standard.

| Eintrag | Wirkung | Hinweise |
| --- | --- | --- |
| `name` | Name der Kita im Kopf aller Seiten und im Seitentitel | z. B. `"Kita Sonnenschein"` |
| `logo` | Bild im Kopf aller Seiten | PNG oder SVG, quadratisch, etwa 80 px. Leer = kein Logo. Standard ist `"icons/logo.svg"`. |
| `favicon` | Symbol im Browser-Tab | PNG 64 × 64 px. Standard ist `"icons/favicon.png"`. |
| `colors.main` | Hauptfarbe für Knöpfe, Haken, Balken | z. B. `"#3F5540"` |
| `colors.accent` | Farbe für Warnungen, Absagen, Fehlendes | z. B. `"#8C4A5C"` |

So gehst du vor:

1. Eigenes Logo und Favicon in den Ordner `icons/` auf dem Webspace legen.
2. In `config.js` als relativen Pfad eintragen, z. B. `logo: "icons/logo.png"`.
3. `config.js` hochladen, Seite mit Strg+F5 neu laden.

Wichtig:

- **Nur eigene Adressen.** Bilder müssen auf derselben Domain liegen wie die Seiten.
  Eine Adresse einer anderen Website wird ohne Fehlermeldung ignoriert.
- **Farben nur als Hex-Wert** mit `#` und drei oder sechs Stellen, z. B. `"#3F5540"`.
  Alles andere wird ignoriert, es bleibt die Standardfarbe.
- Lädt das Logo nicht, verschwindet es still. Pfad prüfen.
- Die Symbole für „Zum Startbildschirm hinzufügen“ kommen aus `manifest-eltern.json`
  und `manifest-orga.json`. Die ändert `SETTINGS` nicht.
- Eine ältere `config.js` ohne `SETTINGS` funktioniert weiter, dann gilt überall der
  Standard.

## 3. Orga-Passwort ändern

Das Orga-Passwort steht in der Tabelle `orga_keys`, Spalte `secret`. Die Datenbank
vergleicht es bei jeder Abfrage über `is_orga()`. Eine Funktion zum Ändern im
Orga-Bereich gibt es nicht. Geändert wird im **SQL-Editor** von Supabase.

**Neues Passwort erzeugen** (ersetzt alle bisherigen): Die Anweisung steht in der
[Neuinstallation](../einrichtung/ANLEITUNG.md), Abschnitt 3, „Ist das Orga-Passwort
verloren“. Sie löscht alle Zeilen in `orga_keys`, lässt die Datenbank ein zufälliges
Passwort erzeugen und zeigt es einmal an. Sofort in den Passwortsafe übernehmen.

`orga_keys` kann mehrere Zeilen haben, eine je Person oder Team (Spalte `label`).
`is_orga()` akzeptiert jedes davon. Ein zusätzliches Passwort, ohne die alten zu
löschen:

```sql
insert into orga_keys (secret, label)
select translate(encode(extensions.gen_random_bytes(24), 'base64'), '+/', '-_'), 'Name oder Team'
returning secret as "Neues Orga-Passwort";
```

Ein einzelnes entfernen: `delete from orga_keys where label = 'Name oder Team';`

Nach dem Ändern:

- Wer im Orga-Bereich angemeldet ist, behält das alte Passwort, bis der Browser-Tab
  geschlossen wird. Speichern scheitert dann mit „Die Datenbank verweigert das Anlegen.
  Melde dich ab und wieder an …“. Abmelden, mit dem neuen Passwort anmelden.
- Das neue Passwort dem Orgateam persönlich geben, nicht in eine Gruppe schreiben.

## 4. Aufräumen und Fristen

Die Datenbankfunktion `daten_aufraeumen()` hält ein, was der Einwilligungstext den
Eltern verspricht. Stand `migration-24.sql` macht sie Folgendes:

| Was | Wann |
| --- | --- |
| Zahlen ohne Namen in den Rückblick sichern (`planning.review.zahlen` mit Anmeldungen, Erwachsene, Kinder, Mitbringsel, Aufgaben, Anwesenheit, Stunden; `planning.review.geld` mit Einnahmen und Bezahltem) | direkt vor dem Löschen |
| Anmeldungen löschen, mit ihnen Zahlungseingang und Check-in | wenn der Veranstaltungstag länger als die Frist zurückliegt |
| Aufgabenübernahmen löschen | ebenso |
| Anmeldungen zu gelöschten Veranstaltungen löschen | sofort |
| Veranstaltung archivieren | nach Ablauf der Frist, wenn keine Anmeldungen mehr da sind |
| Namen unter Rückmeldungen und gemeldeten Aufgaben entfernen | 60 Tage nach dem Veranstaltungstag |

Die Frist stellt das Orgateam je Veranstaltung ein, unter „Anmeldungen löschen nach“:
14 Tage (Standard), 30, 60, 90 Tage oder ein halbes Jahr. **Veranstaltungen ohne Datum
werden nie aufgeräumt.**

Planung, Rückblick, Fotos und Zahlen bleiben dauerhaft.

### Wann es läuft

Die Funktion wird auf zwei Wegen ausgelöst:

1. **Aus dem Orga-Bereich.** `orga.html` ruft sie nach dem Login auf und jedes Mal,
   wenn die Übersicht neu geladen wird, etwa nach „Fertig“ in einer Veranstaltung.
   Was gelöscht wurde, steht danach in den „To-dos“ als „Aufgeräumt: …“.
2. **Nächtlich über `pg_cron`**, wenn der Auftrag eingerichtet ist. Die Neuinstallation
   legt ihn an, sofern das Projekt, aus dem die Vorlage erzeugt wurde, einen hatte. Die
   Vorlage dafür steht als Kommentar in `sql/migration-16.sql`:

   ```sql
   select cron.schedule('kita-aufraeumen', '0 3 * * *', 'select daten_aufraeumen()');
   ```

   Vorher unter Database → Extensions `pg_cron` einschalten.

Prüfen, ob der Auftrag läuft, im SQL-Editor:

```sql
select jobname, status, start_time from cron.job_run_details
 order by start_time desc limit 5;
```

Von Hand auslösen, ebenfalls im SQL-Editor: `select * from daten_aufraeumen();`

Ohne Cron-Auftrag wird nur aufgeräumt, wenn sich jemand im Orga-Bereich anmeldet.
Zwischen zwei Festen kann das Wochen dauern, und die versprochene Frist wird dann nicht
eingehalten.

Wer `retention_days` oder die Sichtbarkeit ändert, ändert den Einwilligungstext auf der
Anmeldeseite und damit ein Versprechen an die Eltern. Vorher im Vorstand absprechen.

## 5. Backup und Keep-alive auf dem NAS

Im Ordner `nas/` liegen drei Skripte für ein Vereins-NAS. Die Einrichtung auf einer
Synology steht jeweils oben im Skript.

| Skript | Zweck | Braucht daneben | Zeitplan |
| --- | --- | --- | --- |
| `keepalive.sh` | ruft einmal die Datenbank ab, damit Supabase das Projekt nicht pausiert | `supabase.env` mit `SUPABASE_URL` und `SUPABASE_ANON_KEY` | täglich |
| `backup.sh` | sichert die Schemas `public` und `intern` mit `pg_dump` nach `sicherungen/`, löscht Sicherungen älter als 14 Tage | `pgpass` mit einer Zeile `HOST:5432:postgres:BENUTZER:PASSWORT`, Rechte `chmod 600` | täglich nachts |
| `wiederherstellen.sh` | spielt eine Sicherung ein und **ersetzt** alle Tabellen und Daten im Ziel | `pgpass` des Zielprojekts und das Repo (es braucht `umzug/sql/rechte-leeren.sql`) | nur bei Bedarf |

Hinweise:

- **Pausieren:** Im kostenlosen Tarif pausiert Supabase ein Projekt nach einer Woche ohne
  Zugriff. Ohne Keep-alive vor jeder Veranstaltung im Dashboard nachsehen und
  gegebenenfalls „Restore“ klicken.
- `keepalive.sh` braucht nur den öffentlichen `anonKey`. Es endet mit Fehler, wenn das
  Projekt nicht antwortet.
- Werte für `pgpass` stehen im Supabase-Dashboard unter Connect → Direct → Session
  pooler. Das Passwort ist das **Datenbank-Passwort**, nicht das Orga-Passwort.
- `pg_dump` auf dem NAS muss mindestens die Postgres-Version des Projekts haben
  (Project Settings → Infrastructure).
- **Sicherungen enthalten Elterndaten.** Auf einem verschlüsselten Ordner ablegen.
  `backup.sh` hält sie 14 Tage, passend zur Standardfrist.
- Im Aufgabenplaner „Ausführungsdetails per E-Mail senden“ und „nur wenn das Skript
  abnormal beendet wurde“ ankreuzen. So merkst du, wenn etwas ausfällt.
- `wiederherstellen.sh` fragt vorher nach; zum Fortfahren `ersetzen` eintippen. Es
  prüft am Ende, dass `signups.token` gesperrt ist.
- **Cron-Aufträge sind nicht in der Sicherung.** Im selben Projekt bleiben sie
  erhalten. In einem neuen Projekt den Auftrag aus [Abschnitt 4](#wann-es-läuft) neu
  anlegen.

## 6. Aktualisieren

Ablauf Schritt für Schritt: [Aktualisierung](../aktualisierung/ANLEITUNG.md).

Die Grundsätze:

1. **Stand notieren.** Die Datenbank kennt keine Versionsnummer. Nach jedem Update
   Datum, Commit und Nummer der letzten Migration im Passwortsafe festhalten.
2. **Vorher sichern:** Datenbank mit `pg_dump` (oder `nas/backup.sh` von Hand
   starten) und den Ordner `/orga/` vom Webspace herunterladen.
3. **Erst SQL, dann Dateien.** Neue `sql/migration-N.sql` in aufsteigender Nummer im
   SQL-Editor ausführen. Keine auslassen. Danach `einrichtung/sql/pruefen.sql` des neuen
   Stands; jede Zeile muss mit OK beginnen. Erst dann die Seiten hochladen.
4. **`config.js` auf dem Webspace nicht überschreiben.** Die Datei im Repo hat leere
   Felder; hochgeladen schaltet sie alle Seiten in den Demo-Modus. Neue Einträge von Hand
   übernehmen. Fehlen sie, nehmen die Seiten den Standard.
5. **Eigene Bilder in `icons/` und die `.htaccess`** nicht überschreiben.
6. **Hart neu laden** (Strg+F5) und im Orga-Bereich prüfen, dass kein roter Hinweis
   „Die Datenbank ist nicht auf dem Stand dieser Version“ erscheint.

Migrationen lassen sich nicht zurücknehmen, dürfen aber mehrfach laufen. Alte Seiten
laufen mit einer neueren Datenbank weiter. Geht etwas schief, die heruntergeladenen
Seiten wieder hochladen.

## 7. Umzug

Für den Wechsel in ein anderes Supabase-Projekt, etwa vom privaten Konto eines
Vorstands in das des Vereins: [Umzug](../umzug/ANLEITUNG.md).

Das Wichtigste:

- Die Skripte in `umzug/` übertragen alle Tabellen mit Daten, Funktionen, Policies,
  Rechte und Cron-Aufträge. Persönliche Links der Eltern und Orga-Passwort bleiben
  gültig.
- Das alte Projekt wird nur gelesen. Ein Probelauf ist gefahrlos.
- Gebraucht werden `pg_dump`, `pg_restore` und `psql` oder Docker.
- Danach in `config.js` URL und `anonKey` des neuen Projekts eintragen, in der
  `.htaccess` die Adresse unter `connect-src` ersetzen.
- Auf dem NAS `pgpass` und `supabase.env` auf das neue Projekt umstellen.
- `umzug/arbeit/` enthält danach eine vollständige Sicherung samt Orga-Passwort. Mit
  `./umzug.sh aufraeumen` löschen, ebenso `umzug.env`.

## 8. Übergabe an den nächsten Vorstand

Diese Zugänge und Unterlagen müssen weitergegeben werden, am besten im Passwortsafe des
Vereins:

| Was | Wofür | Wo zu finden |
| --- | --- | --- |
| Zugang zum Supabase-Konto | Dashboard, SQL-Editor, Projekt wiederherstellen | Konto auf eine Vereins-Mailadresse |
| Datenbank-Passwort | Sicherungen, NAS, Umzug | Project Settings → Database (dort auch zurücksetzen) |
| Project URL und `anonKey` | `config.js`, `.htaccess`, `keepalive.sh` | Project Settings → API |
| Orga-Passwort | Orga-Bereich | Passwortsafe; neu erzeugen siehe [Abschnitt 3](#3-orga-passwort-ändern) |
| SFTP-Zugang zum Webspace | Seiten hochladen | Webhoster |
| Zugang zum NAS und zum Aufgabenplaner | Backup und Keep-alive | NAS des Vereins |
| Zugang zum Repo | Updates holen, Commits ansehen | GitHub |
| Notiz zum Stand | nächstes Update | Datum, Commit, letzte Migration |
| eigene `config.js` und Logo | Wiederherstellen der Seiten | Kopie vom Webspace |

Checkliste beim Wechsel:

- [ ] Gehört das Supabase-Konto dem Verein? Sonst [Umzug](../umzug/ANLEITUNG.md)
      planen.
- [ ] Neue Verantwortliche im Supabase-Konto, beim Webhoster und auf dem NAS
      eingetragen, ausscheidende entfernt.
- [ ] Neues Orga-Passwort erzeugen ([Abschnitt 3](#3-orga-passwort-ändern)) und nur
      dem neuen Orgateam geben.
- [ ] Datenbank-Passwort zurücksetzen, wenn Ausscheidende es kannten. Danach `pgpass`
      auf dem NAS anpassen und `backup.sh` einmal von Hand laufen lassen.
- [ ] Prüfen, dass der Cron-Auftrag läuft ([Abschnitt 4](#wann-es-läuft)).
- [ ] Prüfen, dass `keepalive.sh` und `backup.sh` laufen (neueste Datei in
      `sicherungen/`).
- [ ] Auftragsverarbeitungsvertrag (DPA) mit Supabase lautet auf den Verein.
- [ ] Alte Sicherungen und Exporte mit Elterndaten auf privaten Geräten löschen.

## 9. Fehlersuche

| Was du siehst | Ursache | Was tun |
| --- | --- | --- |
| Seiten zeigen nur Beispieldaten | `config.js` auf dem Webspace hat leere Werte, meist die aus dem Repo hochgeladen | eigene `config.js` wieder hochladen, Strg+F5 |
| „Server nicht erreichbar.“ beim Orga-Login | Project URL falsch, Projekt pausiert oder Data API aus | URL in `config.js` prüfen, im Dashboard „Restore“, unter Project Settings → API Data API an und `public` unter „Exposed schemas“ |
| Keine Seite bekommt Daten, obwohl das Projekt läuft | `.htaccess` lässt die Datenbank nicht zu | in `connect-src` steht noch `PROJEKT-REF` oder die alte Adresse |
| „Passwort stimmt nicht.“ | Tippfehler, Leerzeichen mitkopiert, Passwort geändert | neu kopieren; sonst neues Passwort erzeugen ([Abschnitt 3](#3-orga-passwort-ändern)) |
| Roter Hinweis „Die Datenbank ist nicht auf dem Stand dieser Version“ | Migration fehlt oder ist abgebrochen; der Hinweis nennt die fehlenden Spalten | fehlende Migrationen in Reihenfolge ausführen, neu laden; bis dahin nichts anlegen |
| „Der Datenbank fehlt eine Spalte“ beim Speichern | dasselbe | Fenster offen lassen, Migration einspielen, erneut speichern |
| „Die Datenbank verweigert das Anlegen. Melde dich ab und wieder an …“ | Orga-Passwort in diesem Tab nicht mehr gültig | abmelden, neu anmelden |
| Seite bleibt weiß oder reagiert nicht | Seite und `common.js` passen nicht zusammen | alle Dateien hochladen, hart neu laden; sonst alte Kopie zurück |
| Anmeldungen bleiben länger als die Frist | Cron-Auftrag fehlt, und niemand hat sich im Orga-Bereich angemeldet | Cron-Auftrag prüfen oder anlegen ([Abschnitt 4](#wann-es-läuft)) |
| Veranstaltung wird nie archiviert | sie hat kein Datum | Datum eintragen |
| NAS meldet Fehler bei `keepalive.sh` | Projekt antwortet nicht, oft schon pausiert | im Dashboard „Restore“ |
| NAS meldet Fehler bei `backup.sh` | Datenbank-Passwort geändert, Projekt pausiert oder `pg_dump` zu alt | `pgpass` prüfen, Projekt wecken, neueres `pg_dump` |
| `pruefen.sql` meldet FEHLT oder ZUVIEL | Migration vergessen oder etwas von Hand angelegt | [Aktualisierung](../aktualisierung/ANLEITUNG.md), Abschnitt 8 |
| `pruefen.sql` oder `wiederherstellen.sh` meldet GEFAHR | über die Schnittstelle ist mehr lesbar als vorgesehen, z. B. `signups.token` | sofort nachgehen, notfalls Seiten vom Webspace nehmen |
| Logo, Favicon oder Farbe erscheinen nicht | fremde Domain, falscher Pfad oder Farbe nicht als Hex-Wert | [Abschnitt 2](#2-aussehen-anpassen) |
| Auf dem Handy alte Version | App auf dem Startbildschirm hat die Dateien zwischengespeichert | App ganz schließen und neu öffnen, sonst die Seite im Browser des Handys neu laden |
