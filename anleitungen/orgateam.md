# Anleitung für das Orgateam

Der Orga-Bereich (`orga.html`) ist die Arbeitsseite des Orgateams. Hier legst du
Veranstaltungen an, stellst ein, was die Eltern auf der Anmeldeseite sehen und gefragt
werden, planst mit Checkliste und Einkaufsliste, siehst die Anmeldungen, hakst Zahlungen und
Anwesenheit ab und hältst nach der Veranstaltung den Rückblick fest. Ein Benutzerkonto gibt es
nicht: Alle im Orgateam nutzen dasselbe Orga-Passwort.

Der Orga-Bereich hat drei Reiter: „To-dos“, „Veranstaltungen“ und „Vorlagen“. Dazu kommen drei
Arbeitsansichten, die sich aus den Reitern öffnen: der Editor einer Veranstaltung, der Editor
einer Vorlage und die Liste der Anmeldungen. Einen eigenen Reiter „Planung“ oder „Auswertung“
gibt es nicht. Checkliste, Einkaufsliste, Rückblick und Rückmeldungen stehen unten im Editor
der Veranstaltung.

## Inhalt

1. [Typischer Ablauf einer Veranstaltung](#1-typischer-ablauf-einer-veranstaltung)
2. [Anmelden und Abmelden](#2-anmelden-und-abmelden)
3. [Hinweis auf eine veraltete Datenbank](#3-hinweis-auf-eine-veraltete-datenbank)
4. [Reiter „To-dos“](#4-reiter-to-dos)
5. [Reiter „Veranstaltungen“](#5-reiter-veranstaltungen)
6. [Der Editor einer Veranstaltung](#6-der-editor-einer-veranstaltung)
7. [Gemeldete Aufgaben](#7-gemeldete-aufgaben)
8. [Planung: Checkliste und Einkaufsliste](#8-planung-checkliste-und-einkaufsliste)
9. [Auswertung: Rückblick, Geld und Rückmeldungen](#9-auswertung-rückblick-geld-und-rückmeldungen)
10. [Anmeldungen](#10-anmeldungen)
11. [Check-in am Eingang](#11-check-in-am-eingang)
12. [Reiter „Vorlagen“](#12-reiter-vorlagen)
13. [Sichern und Exportieren](#13-sichern-und-exportieren)
14. [Was Eltern sehen und was nur das Orgateam sieht](#14-was-eltern-sehen-und-was-nur-das-orgateam-sieht)
15. [Datenschutz und Fristen](#15-datenschutz-und-fristen)
16. [Häufige Fragen und Probleme](#16-häufige-fragen-und-probleme)

---

## 1. Typischer Ablauf einer Veranstaltung

1. **Vorlage prüfen.** Im Reiter „Vorlagen“ nachsehen, ob es für die Veranstaltung schon eine
   Vorlage gibt (etwa „Sommerfest“). Wenn nicht und die Veranstaltung wiederkommt, zuerst eine
   anlegen („+ Neue Vorlage“).
2. **Veranstaltung anlegen.** Bei der Vorlage auf „Veranstaltung daraus anlegen“ tippen. Ohne
   Vorlage im Reiter „Veranstaltungen“ auf „+ Neue Veranstaltung“.
3. **Eckdaten ausfüllen.** Name, Kurzname für den Link, Datum, Uhrzeit, Ort, Begrüßungstext.
   Löschfrist wählen und den „Abweichenden Hinweistext“ dazu prüfen (siehe
   [Abschnitt 6](#löschfrist-und-hinweistext)).
4. **Kosten eintragen**, falls die Veranstaltung etwas kostet: Preis pro Person,
   Zahlungshinweis, Zahlweg.
5. **Sichtbarkeit einstellen:** Was sollen die Eltern von den anderen Anmeldungen sehen?
6. **Inhalt anlegen:** Mitbringsel-Kategorien mit Zielwerten, Aufgaben, Zusatzfragen. Gibt es
   einen Rückblick vom letzten Mal, „Zielwerte aus dem Rückblick übernehmen“ antippen.
7. **Planen:** Checkliste mit „Wer“ und „Vorlauf“ füllen, Einkaufsliste anlegen.
8. **Speichern.** Danach den „Meldelink“ an Leitung, Vorstand und Teamleitungen schicken, damit
   sie Aufgaben melden können. Eingegangene Meldungen übernehmen oder ablehnen.
9. **Anmeldung freigeben.** Haken bei „Anmeldung freigegeben“ setzen, speichern, dann den
   „Anmeldelink“ an alle Eltern schicken.
10. **Im Reiter „To-dos“ dranbleiben.** Dort steht, was auf den Checklisten in den nächsten zwei
    Wochen fällig ist.
11. **Anmeldungen begleiten:** Zusagen per Zettel oder Anruf von Hand eintragen, Zahlungen
    abhaken.
12. **Check-in vorbereiten** (falls gewünscht): Haken bei „Check-in per QR-Code“, speichern,
    „Aushang mit QR-Code“ drucken und am Eingang aufhängen.
13. **Am Tag:** Eltern checken am Aushang ein. In den Anmeldungen siehst du, wer da ist, und
    hakst von Hand ab, wer ohne Handy kam.
14. **Danach:** Haken bei „Rückmeldungen der Eltern einsammeln“ setzen, speichern, den
    Rückmeldelink verteilen. Preise in der Einkaufsliste nachtragen. Den Rückblick ausfüllen,
    **bevor die Löschfrist abläuft**.
15. **Nach der Löschfrist** löscht das Tool Anmeldungen und Aufgabenzusagen, behält eine
    Zusammenfassung ohne Namen und archiviert die Veranstaltung. Beim nächsten Mal aus derselben
    Vorlage erscheinen Rückblick und Zielvorschläge.

---

## 2. Anmelden und Abmelden

### Anmelden

Auf der Startseite des Orga-Bereichs steht die Karte „Anmelden“. Gib im Feld „Orga-Passwort“
das gemeinsame Passwort ein und tippe auf „Weiter“ (oder drück Enter).

| Meldung | Bedeutung |
| --- | --- |
| „Bitte Passwort eingeben.“ | Das Feld ist leer. |
| „Passwort stimmt nicht.“ | Die Datenbank kennt dieses Passwort nicht. |
| „Server nicht erreichbar.“ | Keine Verbindung zur Datenbank. |

Nach dem Anmelden steht unter der Überschrift „Mit der Datenbank verbunden.“. Steht dort
„Demo-Modus …“, ist in `config.js` keine Datenbank eingetragen. Dann reicht ein beliebiges
Passwort, die Seite zeigt Beispieldaten, und **nichts wird gespeichert**. Gemeldete Aufgaben,
Rückmeldungen und Fotos gibt es im Demo-Modus nicht.

### Wo das Passwort gespeichert wird

Das Passwort bleibt nur im geöffneten Browser-Tab (im sogenannten Sitzungsspeicher des
Browsers). Lädst du die Seite neu, bist du weiter angemeldet. Schließt du den Tab, ist das
Passwort weg und du musst es neu eingeben. Auf dem Rechner oder in einem Cookie wird es nicht
abgelegt.

Das Passwort selbst steht in der Datenbank. Im Orga-Bereich lässt es sich nicht ändern. Wie man
ein neues erzeugt (etwa nach einem Vorstandswechsel), steht in `einrichtung/ANLEITUNG.md`.

### Abmelden

Oben rechts steht „Abmelden“. Der Knopf löscht das Passwort aus dem Tab und bringt dich zurück
zur Anmeldekarte. Auf gemeinsam genutzten Rechnern immer abmelden oder den Tab schließen.

### Was beim Anmelden noch passiert

Jedes Mal, wenn du dich anmeldest oder zur Übersicht zurückkehrst, räumt der Orga-Bereich die
Datenbank auf: Er löscht abgelaufene Anmeldungen und anonymisiert alte Namen (Details in
[Abschnitt 15](#15-datenschutz-und-fristen)). Wurde etwas aufgeräumt, steht im Reiter „To-dos“
eine Zeile wie „Aufgeräumt: 12 abgelaufene Anmeldungen, …“.

---

## 3. Hinweis auf eine veraltete Datenbank

Nach dem Anmelden prüft der Orga-Bereich, ob die Datenbank alle Tabellen, Spalten und
Funktionen hat, die diese Version der Seiten braucht. Fehlt etwas, erscheint oberhalb der Reiter ein roter Kasten:

> **Die Datenbank ist nicht auf dem Stand dieser Version.**
> Es fehlt: events.checkin, Tabelle attendance, …

Darin steht beim Namen, was fehlt. Das passiert, wenn neue Seiten hochgeladen wurden, aber die
passende Migration (eine Datei `sql/migration-N.sql`) noch nicht in Supabase ausgeführt wurde.
**Leg dann nichts an**, sonst schlägt das Speichern fehl. Wer die Datenbank betreut, führt die
fehlenden Migrationen aus (Anleitung in `aktualisierung/ANLEITUNG.md`). Danach Seite neu laden;
der Kasten verschwindet.

Beim Speichern einer Veranstaltung kann zusätzlich diese Meldung kommen: „Der Datenbank fehlt
eine Spalte (…). Führ die neueste migration-Datei in Supabase aus …“. Lass dann das Fenster
offen. Deine Eingaben sind noch da und lassen sich nach der Migration speichern.

---

## 4. Reiter „To-dos“

Der erste Reiter sammelt, was über alle Veranstaltungen hinweg ansteht. Die Zahl im Reiter,
etwa „To-dos (5)“, ist die Summe aus offenen Checklistenpunkten und wartenden Meldungen.

### Was dort steht

**Checklistenpunkte, die in den nächsten zwei Wochen fällig sind.** Berücksichtigt werden nur
Punkte, die

- noch nicht abgehakt sind,
- einen „Vorlauf“ haben (nicht „kein fester Termin“),
- zu einer Veranstaltung mit Datum gehören, die weder archiviert noch vorbei ist.

Das Fälligkeitsdatum ist das Veranstaltungsdatum minus Vorlauf. Angezeigt werden höchstens 15
Punkte, sortiert so: zuerst Punkte, für die niemand zuständig ist und die in sieben Tagen oder
früher fällig sind (roter Rand, Etikett „niemand zuständig“), danach nach Fälligkeit. Rechts
steht „heute“, „morgen“, „in 5 Tagen“ oder in Rot „seit 3 Tagen überfällig“, darunter das Datum.

- **Haken setzen** speichert den Punkt sofort als erledigt.
- **Auf den Titel tippen** öffnet den Editor der Veranstaltung und springt zu diesem Punkt.
  Enthält der Titel „Einkauf“, „besorg“ oder „bestell“, springt die Seite direkt zur
  Einkaufsliste.

**Gemeldete Aufgaben, die auf Entscheidung warten** („3 gemeldete Aufgaben warten auf
Entscheidung“), mit Titel, Veranstaltung und Name der meldenden Person. Ein Tipp auf den Titel
öffnet den Editor an der Stelle „Gemeldete Aufgaben“.

**„Rückblick fehlt“:** bis zu vier vergangene Veranstaltungen mit Datum, bei denen im Rückblick
weder eine Bewertung noch eine Notiz noch „Tatsächlich da“ eingetragen ist. Ein Tipp auf den
Titel öffnet den Editor beim Rückblick.

Steht nichts an, zeigt der Reiter „Nichts überfällig“. Gibt es keine kommende Veranstaltung mit
Datum, steht dort, dass sich ohne Datum keine Fristen rechnen lassen.

---

## 5. Reiter „Veranstaltungen“

### Die Liste

Jede Veranstaltung ist eine Karte mit Name, Datum (oder „ohne Datum“), Ort (oder „ohne Ort“)
und, falls aus einer Vorlage angelegt, dem Etikett „Vorlage: …“. Pflichtveranstaltungen tragen
das Etikett „Pflicht“. Rechts steht der Zustand:

| Etikett | Bedeutung |
| --- | --- |
| „aktiv“ | Anmeldung offen |
| „Anmeldung gesperrt“ | Haken „Anmeldung freigegeben“ fehlt |
| „Anmeldung ab 01.09.2026“ | „Frühestens ab“ liegt in der Zukunft |
| „Anmeldung zu“ | „Anmeldeschluss“ ist vorbei |
| „Nachbereitung“ | Das Datum der Veranstaltung ist vorbei |
| „archiviert“ | Haken „Archivieren“ gesetzt oder automatisch archiviert |

Sortiert ist so: erst laufende, dann vergangene, dann archivierte Veranstaltungen, innerhalb
davon nach Datum. Veranstaltungen ohne Datum stehen am Ende ihrer Gruppe.

### Knöpfe auf jeder Karte

| Knopf | Was er tut |
| --- | --- |
| „Bearbeiten“ | Öffnet den Editor ([Abschnitt 6](#6-der-editor-einer-veranstaltung)). |
| „Anmeldungen“ | Öffnet die Liste der Anmeldungen ([Abschnitt 10](#10-anmeldungen)). |
| „Anmeldelink“ | Kopiert den Link zur Anmeldeseite. Der geht an alle Eltern. |
| „Meldelink“ | Kopiert den Link zum Melden von Aufgaben. Der ist für Leitung, Vorstand und Teamleitungen, nicht für alle Eltern. |
| „Duplizieren“ | Öffnet den Editor mit einer Kopie (siehe unten). |
| „Löschen“ | Löscht die Veranstaltung nach Rückfrage (siehe unten). |

Klappt das Kopieren in die Zwischenablage nicht, zeigt der Browser ein Fenster mit dem Link
zum Markieren.

### Neue Veranstaltung

„+ Neue Veranstaltung“ öffnet einen leeren Editor. Er ist mit vier Beispielkategorien
(Kuchen & Süßes, Herzhaftes, Salate, Getränke) und drei Beispielaufgaben (Aufbau, Grillen,
Abbau) vorbelegt. Was nicht passt, entfernst du mit „×“. Gespeichert wird erst mit
„Speichern“.

Am besten legst du wiederkehrende Veranstaltungen aus einer Vorlage an
([Abschnitt 12](#12-reiter-vorlagen)), dann sind Kategorien, Aufgaben, Fragen, Kosten,
Checkliste und Einkaufsliste schon da.

### Duplizieren

„Duplizieren“ öffnet den Editor mit einer Kopie: Name mit „(Kopie)“, Kurzname mit „-kopie“,
nicht archiviert. Übernommen werden alle Einstellungen der Veranstaltung (Datum, Ort, Kosten,
Sichtbarkeit, Kategorien, Aufgaben, Fragen, Check-in, Vorlage). **Nicht übernommen** werden
Checkliste, Einkaufsliste, Rückblick, Fotos der Aufgaben und natürlich die Anmeldungen. Der
Haken „Anmeldung freigegeben“ ist bei der Kopie aus. Die Kopie entsteht erst mit „Speichern“;
vorher Name, Kurzname und Datum anpassen.

### Löschen

„Löschen“ öffnet ein eigenes Fenster. Es zählt zuerst, was an der Veranstaltung hängt
(Anmeldungen mit Namen, übernommene Aufgaben, Fotos, gemeldete Aufgaben, Rückmeldungen), und
weist darauf hin, dass „Archivieren“ im Editor der sanftere Weg ist.

Hängen Daten dran, wählst du unter „Sicherung vorher herunterladen“:

| Auswahl | Was du bekommst |
| --- | --- |
| „Vollständig“ | Datei `geloescht-<kurzname>-<datum>.json` mit Veranstaltung, Planung, Anmeldungen samt Namen und Anmerkungen, Aufgabenzusagen, Fotos, Meldungen, Rückmeldungen. Nur damit ließe sich später etwas wiederherstellen. |
| „Nur Zahlen“ | Datei `zahlen-<kurzname>-<datum>.json` ohne Namen: Anzahl Zusagen und Absagen, Erwachsene, Kinder, Mengen je Kategorie und Aufgabe, Rückblick, Checkliste, Einkaufsliste, Bewertungen und Texte der Rückmeldungen, Meldungen. |
| „Keine Sicherung“ | Direkt löschen. |

Zahlungseingänge und Anwesenheit stehen in keiner der beiden Sicherungen.

Zum Bestätigen tippst du den Namen der Veranstaltung ab (Groß- und Kleinschreibung egal) und
tippst auf „Endgültig löschen“. „Abbrechen“, Escape oder ein Klick neben das Fenster brechen
ab. Klappt die Sicherung nicht, fragt die Seite, ob trotzdem gelöscht werden soll.

Gelöscht werden die Veranstaltung, Planung, Fotos, Aufgabenzusagen, Meldungen, Rückmeldungen
und der Check-in-Code. Die Anmeldungen samt Zahlungen und Anwesenheit verschwinden beim
anschließenden Aufräumen. **Das lässt sich nicht rückgängig machen.** Eine vollständige
Sicherung enthält Namen; leg sie nur so lange ab, wie du sie brauchst.

---

## 6. Der Editor einer Veranstaltung

Der Editor ist eine lange Seite mit Abschnitten. Unten klebt eine Leiste mit diesen Knöpfen:

| Knopf | Was er tut |
| --- | --- |
| „Speichern“ | Speichert alles. Der Editor bleibt offen. |
| „Fertig, zur Übersicht“ | Zurück zur Liste. |
| „Anmeldeseite öffnen“ | Öffnet die Anmeldeseite in einem neuen Tab. |
| „Anmeldelink kopieren“ | Kopiert den Link für alle Eltern. |
| „Meldelink kopieren“ | Kopiert den Link für Leitung, Vorstand und Teamleitungen. Erst nach dem ersten Speichern. |

Hast du etwas geändert und nicht gespeichert, fragt die Seite beim Verlassen nach
(„Ungespeicherte Änderungen gehen verloren. Trotzdem zurück?“). Auch beim Schließen des Tabs
warnt der Browser.

Nach dem Speichern steht über den Knöpfen eine Meldung, etwa „Gespeichert. 3 Punkte auf der
Checkliste noch offen. Link: …“. Ist die Anmeldung noch gesperrt, erinnert die Meldung daran.
Fragt die Veranstaltung gar nichts ab (keine Kategorien, Aufgaben, Fragen), sagt die Meldung,
dass die Anmeldeseite nur Datum und Ort zeigt. Das passt für eine reine Orga-Planung.

Wurde die Veranstaltung aus einer Vorlage angelegt, steht oben „Aus der Vorlage …. Änderungen
hier gelten nur für diese Veranstaltung.“ Darunter erscheint, sobald es frühere Veranstaltungen
derselben Vorlage gibt, der Kasten „Aus den letzten Malen“ ([Abschnitt 9](#zielwerte-aus-dem-rückblick)).

### Zeilen bearbeiten, verschieben, entfernen

Kategorien, Aufgaben, Fragen, Checklistenpunkte und Einkaufsposten sind Zeilen. Fertige Zeilen
zeigen eine Kurzfassung. Rechts oben an jeder Zeile:

| Zeichen | Wirkung |
| --- | --- |
| ✎ | Zeile aufklappen oder zuklappen |
| ↑ / ↓ | Zeile nach oben oder unten schieben. Die Reihenfolge gilt auch auf der Anmeldeseite. |
| × | Zeile entfernen. Darunter erscheint 30 Sekunden lang „… entfernt“ mit „Rückgängig“. |

Neue, leere Zeilen sind gleich aufgeklappt. Erst „Speichern“ macht alles dauerhaft. Leere
Zeilen ohne Namen werden beim Speichern weggelassen.

### Eckdaten

| Feld | Was es bewirkt |
| --- | --- |
| „Name der Veranstaltung“ | Überschrift auf der Anmeldeseite. Pflicht. |
| „Kurzname für den Link“ | Steht im Link: `fest-anmeldung.html?event=<kurzname>`. Nur Kleinbuchstaben, Zahlen und Bindestriche. Bleibt das Feld leer, wird es beim Verlassen des Namensfelds aus dem Namen gebildet (ä wird ae, Leerzeichen werden Bindestriche). Beim Speichern wird es in diese Form gebracht. Sobald es Anmeldungen gibt, lässt er sich nicht mehr ändern. |
| „Datum“ | Grundlage für alles Zeitliche: Startseite, Fristen der Checkliste, Check-in, Löschfrist. Nach diesem Datum verschwindet die Veranstaltung von der Startseite der Eltern. |
| „Uhrzeit“ | Freier Text, zum Beispiel „15–18 Uhr“. |
| „Abweichender Anzeigetext“ (optional) | Ersetzt das ausgeschriebene Datum in der Anzeige, etwa „Freitag, 18. Oktober, ab mittags“. Das Feld „Datum“ gilt trotzdem für alle Fristen. |
| „Pflichtveranstaltung“ | Eltern müssen zu- oder absagen; wer nicht kann, meldet sich mit Begründung ab. In den Anmeldungen zählt der Orga-Bereich dann Zusagen und Absagen getrennt. Ohne den Haken können Eltern über ihren persönlichen Link ebenfalls absagen; die Begründung ist dann freiwillig. |
| „Check-in per QR-Code“ | Schaltet den Check-in ein. Darunter erscheint „Aushang mit QR-Code“ ([Abschnitt 11](#11-check-in-am-eingang)). |
| „Wie viele Familien insgesamt?“ (optional) | Bei Pflichtveranstaltungen zeigen die Anmeldungen damit „ohne Antwort“: Familienzahl minus Zahl der Antworten. Bei anderen Veranstaltungen wird die Zahl nicht angezeigt. |
| „Anmeldung freigegeben“ | Erst mit diesem Haken können sich Eltern eintragen. Ohne ihn sehen sie die Veranstaltung mit dem Hinweis, dass die Anmeldung noch kommt. Bei neuen, duplizierten und aus Vorlagen angelegten Veranstaltungen ist er aus. |
| „Frühestens ab“ (optional) | Vorher ist die Anmeldung nicht offen. |
| „Anmeldeschluss“ (optional) | Danach ist die Anmeldung zu. Ohne Anmeldeschluss läuft sie bis zum Veranstaltungstag. |
| „Ort“ | Freier Text. |
| „Begrüßungstext“ (optional) | Text oben auf der Anmeldeseite. Formatierung siehe unten. |
| „Anmeldungen löschen nach“ | 14 Tagen (empfohlen), 30, 60, 90 Tagen oder einem halben Jahr. Siehe unten. |
| „Abweichender Hinweistext“ (optional) | Ersetzt den Satz zur Löschung im Einwilligungstext. Siehe unten. |
| „Wen soll die Anmeldung zählen?“ | Zwei Personengruppen, siehe unten. |
| „Archivieren“ | Die Veranstaltung verschwindet von der Startseite der Eltern. Der direkte Link bleibt gültig. |

> **Der Kurzname bleibt, sobald Anmeldungen da sind.** Die Anmeldungen und die persönlichen
> Links der Eltern hängen am Kurznamen. Änderst du ihn bei einer gespeicherten Veranstaltung mit
> Anmeldungen, setzt die Seite beim Speichern den alten Kurznamen zurück und meldet „Der
> Kurzname bleibt …: Es gibt schon 3 Anmeldungen, und die persönlichen Links enthalten ihn.
> Nochmal auf Speichern drücken, um den Rest zu sichern.“ Dann noch einmal „Speichern“.
> Ohne Anmeldungen lässt er sich ändern, aber schon verschickte Anmeldelinks und gedruckte
> Aushänge führen danach ins Leere.

Ist der Kurzname schon vergeben, trägt die Seite beim Speichern einen freien Vorschlag ein
(etwa `sommerfest-2026-2`) und bittet, noch einmal auf „Speichern“ zu drücken.

#### Begrüßungstext formatieren

Der Begrüßungstext kennt einfache Auszeichnungen wie in WhatsApp:

| Du schreibst | Eltern sehen |
| --- | --- |
| `*fett*` (auch `**fett**`) | **fett** |
| `_kursiv_` | *kursiv* |
| `~durchgestrichen~` | ~~durchgestrichen~~ |
| Leerzeile | neuer Absatz |
| einfacher Zeilenumbruch | Zeilenumbruch im Absatz |

Die Zeichen wirken nur am Wortanfang und Wortende. `kita_sonne` oder `3*4` bleiben normaler
Text.

**Einfügen aus Google Forms, Word oder Mail:** Kopierst du formatierten Text und fügst ihn in
das Feld ein, setzt die Seite Fett in `*…*` und Kursiv in `_…_` um und macht aus Absätzen
Leerzeilen. Durchgestrichenes, Farben, Links und Bilder werden dabei nicht übernommen, nur der
Text.

#### Löschfrist und Hinweistext

Unter „Anmeldungen löschen nach“ steht, ab wann gelöscht wird, zum Beispiel „Löschung ab
02.10.2026.“ Das ist der Tag nach Ablauf der Frist: Veranstaltungstag plus Frist plus ein Tag.
Gelöscht werden Namen, Anmerkungen und Antworten; die Zahlen für den Rückblick werden vorher
gesichert. Tatsächlich gelöscht wird beim ersten Aufräumen ab diesem Tag.

Der Einwilligungstext, den die Eltern beim Anmelden sehen, endet mit einem Satz zur Löschung.
Derselbe Satz steht ganz unten auf der Anmeldeseite. Ist „Abweichender Hinweistext“ leer,
bildet die Seite ihn aus der Frist („Alle Angaben werden 30 Tage nach der Veranstaltung
gelöscht.“). Steht dort ein eigener Text, gilt dieser Text.

Bei neuen Veranstaltungen und solchen aus Vorlagen ist das Feld leer. Steht darin genau der
Satz „Alle Angaben werden zwei Wochen nach der Veranstaltung gelöscht.“, gilt:

- Wählst du eine andere Frist, leert die Seite das Feld.
- Ist die Frist nicht 14 Tage, nimmt die Anmeldeseite statt dieses Satzes den Satz aus der
  Frist.

> **Wichtig:** Einen eigenen Hinweistext prüfst du selbst gegen die Frist, auch nach jeder
> Änderung der Frist. Sonst versprichst du den Eltern eine Frist, und das Tool löscht nach
> einer anderen.

#### Personengruppen

Unter „Wen soll die Anmeldung zählen?“ stehen zwei Gruppen, standardmäßig „Erwachsene“ und
„Kinder“, je mit Haken, frei wählbarem Namen und „höchstens“ (1 bis 30, Standard 6). Was
abgeschaltet ist, taucht im Formular nicht auf. Beim Oma-Opa-Tag etwa nur eine Gruppe
„Großeltern“. Die Namen erscheinen überall: im Formular, in den Summen, im Export und an den
Preisfeldern.

### Kosten und Bezahlung

Leer lassen, wenn die Veranstaltung nichts kostet. Die Eltern sehen beim Anmelden, was es für
sie zusammen kostet.

| Feld | Was es bewirkt |
| --- | --- |
| „<Gruppe>: Preis pro Person“ | Je ein Feld pro Personengruppe, beschriftet mit dem Gruppennamen. Eingabe wie „3,50“. Ist die Gruppe abgeschaltet, ist das Feld gesperrt. Leer heißt kostenlos. |
| „Zahlungshinweis für die Eltern“ | Bis 1000 Zeichen, etwa Kontoverbindung und Frist. Steht nach dem Anmelden unter dem Betrag, zusammen mit einem Verwendungszweck aus Veranstaltung und Name. |
| „Zahllink oder PayPal“ (optional) | Bis 300 Zeichen. Drei Möglichkeiten, siehe unten. |

Der Betrag einer Anmeldung ist immer: Personen jeder eingeschalteten Gruppe mal Preis, plus
bestellte Stück mal Stückpreis. Absagen kosten nichts. Der Betrag wird nie gespeichert, sondern
jedes Mal neu gerechnet. Ändert eine Familie ihre Anmeldung, ändert sich auch ihr Betrag.

**Zahlweg.** Unter dem Feld erklärt ein Hinweis, was erkannt wurde:

| Eingabe | Was die Eltern nach dem Anmelden bekommen |
| --- | --- |
| PayPal.me-Name, etwa `kitasommerfest` (auch der ganze Link `paypal.me/kitasommerfest` geht) | Einen Knopf, der PayPal mit dem richtigen Betrag öffnet. |
| PayPal-Adresse (E-Mail) der Person, die sammelt | Adresse, Betrag und Verwendungszweck zum Kopieren, für „Freunde & Familie“. Die Adresse steht damit für alle mit dem Link sichtbar auf der Anmeldeseite. Nur eintragen, wenn die Person einverstanden ist. |
| Link mit `https://`, etwa von Wero oder der Bank | Einen Knopf zu diesem Link, den Betrag daneben. Ob der Betrag beim Anbieter schon eingetragen ist, hängt vom Anbieter ab. |

Passt die Eingabe zu nichts davon, wird der Hinweis rot („Das ist weder ein Link mit https://
noch eine E-Mail-Adresse noch ein PayPal.me-Name.“) und der Zahlweg wird **nicht** gespeichert.
Die Seite lädt nichts von PayPal oder der Bank; die Eltern öffnen den Link selbst.

Zusätzliche Bestellungen mit Stückpreis, etwa ein Weckmann, legst du bei den Zusatzfragen an
(Art „Bestellung mit Stückpreis“, siehe unten).

### Was sehen die Gäste auf der Seite?

Die Haken betreffen nur die öffentliche Anmeldeseite. Im Orga-Bereich siehst du immer alles.

| Haken | Wirkung, wenn gesetzt | Standard |
| --- | --- | --- |
| „Gesamtzahlen im Kopf — Anmeldungen und Personen“ | Oben steht, wie viele angemeldet sind. | an |
| „Liste der Mitbringsel“ | Eltern sehen, was schon zugesagt ist. Ohne den Haken bleiben nur die Fortschrittsbalken. | an |
| „Namen an den Mitbringseln“ | Bei jedem Mitbringsel steht, wer es bringt. | an |
| „Namen in der Helferliste“ | Bei Aufgaben steht, wer hilft. Sonst nur „3 von 6 belegt“. | an |
| „Aufgabenliste oben zeigen statt der Mitbringsel“ | Für Arbeitseinsätze: Aufgaben stehen im Vordergrund. | aus |
| „Aufgaben werden vor Ort verteilt“ | Keine Plätze, kein Eintragen im Anmeldeformular. Die Aufgaben stehen als Liste auf der Seite; dort tragen sich Helfer mit „Ich mach das“ ein und haken ab, was erledigt ist. | aus |

Namen erscheinen auf der Anmeldeseite gekürzt (Vorname und Anfangsbuchstabe des Nachnamens).

Aus diesen Haken, den Kosten, dem Check-in und der Löschfrist baut die Anmeldeseite den
Einwilligungstext. Wer Haken ändert, ändert, was den Eltern zugesagt wurde (siehe
[Abschnitt 15](#15-datenschutz-und-fristen)).

### Mitbringsel-Kategorien

Jede Kategorie ist eine Zeile:

| Feld | Bedeutung |
| --- | --- |
| „Kategorie“ | Name, etwa „Kuchen & Süßes“ |
| „Ziel (0 = kein Ziel)“ | Steuert den Fortschrittsbalken auf der Anmeldeseite und die Lücken auf der Startseite. |
| „Einheit“ | Etwa „Kuchen“, „Kisten“. Standard „Beiträge“. |
| „Vorschläge zum Antippen“ | Mit Komma getrennt. Ein angehängtes `x2` heißt: davon werden zwei gebraucht, etwa `Akkuschrauber x2, Säge, Leiter`. Ohne Angabe ist es nur ein Vorschlag. |

Die Kurzfassung zeigt das Ziel oder „4 Stück konkret gesucht“ oder „ohne Ziel“.

### Aufgaben am Veranstaltungstag

Jede Aufgabe ist eine Zeile:

| Feld | Bedeutung |
| --- | --- |
| „Aufgabe“ | Name, etwa „Aufbau“ |
| „Wann“ (optional) | Etwa „ab 13 Uhr“, leer lassen, wenn ganztags |
| „Wie viele“ | Gesuchte Helfer, Standard 4 |
| „Erklärung für die Eltern“ (optional) | Was genau zu tun ist |
| „Fotos“ (optional) | Mehrere Bilder möglich. Werden im Browser verkleinert und erst beim Speichern hochgeladen. Mit „×“ am Bild entfernen. **Keine Bilder mit Kindern** — die Liste ist für alle sichtbar, die den Link haben. Nur in der Veranstaltung, nicht in Vorlagen. |

Wie die Eltern Aufgaben übernehmen, hängt vom Haken „Aufgaben werden vor Ort verteilt“ ab:

- **Haken aus (Standard):** Eltern kreuzen Aufgaben im Anmeldeformular an („vorab“). Die
  Plätze sind begrenzt durch „Wie viele“. Die Aufgaben stehen in der Anmeldung.
- **Haken an:** Aufgaben werden am Tag übernommen. Helfer tragen auf der Anmeldeseite ihren
  Namen ein („Ich mach das“) und haken ab, wenn es erledigt ist. Diese Übernahmen siehst du in
  den Anmeldungen im Kasten „Aufgabenstand“.

Unter der Liste:

| Knopf | Wann er erscheint | Was er tut |
| --- | --- | --- |
| „+ Aufgabe“ | immer | neue leere Zeile |
| „+ Standardaufgaben aus der Vorlage“ | bei Veranstaltungen aus einer Vorlage | ergänzt die Aufgaben der Vorlage, die noch fehlen |
| „+ 3 offene Aufgaben vom …“ | wenn bei der letzten Veranstaltung derselben Vorlage Aufgaben am Tag übernommen, aber nicht alle abgehakt wurden | übernimmt die nicht erledigten Aufgaben samt Erklärung und Fotos |

Der dritte Knopf braucht die Erledigt-Haken vom letzten Mal. Wurden damals keine Aufgaben auf
der Seite übernommen, erscheint er nicht.

### Zusätzliche Fragen an die Gäste

Jede Frage ist eine Zeile mit „Frage“, „Art der Antwort“ und „Pflichtfeld“ (nein/ja):

| Art | Eltern sehen |
| --- | --- |
| „Kurzer Text“ | einzeiliges Feld |
| „Langer Text“ | mehrzeiliges Feld |
| „Auswahl“ | Auswahlliste; „Antwortmöglichkeiten“ mit Komma getrennt, etwa „zu Fuß, Rad, Auto“ |
| „Ja/Nein“ | Haken |
| „Zahl“ | Zahlenfeld |
| „Bestellung mit Stückpreis“ | Anzahl eintragen; der Betrag kommt zum Gesamtpreis dazu |

Bei „Bestellung mit Stückpreis“ gibt es statt „Pflichtfeld“ zwei Felder: „Preis pro Stück (€)“
und „höchstens pro Anmeldung“ (1 bis 99, Standard 10). Bestellungen sind nie Pflicht. Die
bestellten Mengen siehst du in den Anmeldungen als eigene Summe, etwa „17 Bratwurst
vorbestellen“.

> **Fragen nach den ersten Anmeldungen nicht mehr umbenennen.** Die Antworten hängen am Text der
> Frage. Bei Bestellungen fallen die bisherigen Mengen sonst aus der Rechnung.

---

## 7. Gemeldete Aufgaben

Leitung, Vorstand und Teamleitungen melden über den Meldelink (`vorschlag.html?event=…`)
Aufgaben, die bei der Veranstaltung erledigt werden sollen, mit Titel, Erklärung, Zahl der
Hände, Name und auf Wunsch einem Foto. Den Meldelink kopierst du mit „Meldelink“ auf der Karte
oder „Meldelink kopieren“ im Editor (erst nach dem ersten Speichern).

Gibt es offene Meldungen, erscheint im Editor der Abschnitt „Gemeldete Aufgaben“ (sonst ist er
ausgeblendet). Jede Meldung zeigt Titel, „gemeldet von …“, Zahl der Hände, Datum, Erklärung und
Foto.

| Knopf | Was er tut |
| --- | --- |
| „Übernehmen“ | Legt unten in „Aufgaben am Veranstaltungstag“ eine neue Aufgabe an, mit Titel, Erklärung, Zahl und Foto. **Erst beim Speichern** wird die Meldung als übernommen markiert. Verlässt du den Editor ohne Speichern, bleibt sie offen. |
| „Ablehnen“ | Fragt nach einer kurzen Notiz (optional) und markiert die Meldung **sofort** als abgelehnt. „Abbrechen“ im Fragefenster lässt sie offen. |

Wartende Meldungen stehen auch im Reiter „To-dos“.

---

## 8. Planung: Checkliste und Einkaufsliste

Beides steht unten im Editor und ist nur für das Orgateam sichtbar.

### Planung — interne Checkliste

Alles, was vorher passieren muss: Pavillon leihen, Kaffee bestellen, Aushang drucken.

| Feld | Bedeutung |
| --- | --- |
| Haken vor dem Punkt | erledigt (wird durchgestrichen) |
| „Was ist zu tun?“ | Beschreibung |
| „Wer“ | Name oder Rolle |
| „Vorlauf“ | „kein fester Termin“, „am Tag der Veranstaltung“, „1 Tag vorher“, „3 Tage vorher“, „1 Woche vorher“, „2 Wochen vorher“, „3 Wochen vorher“, „4 Wochen vorher“, „6 Wochen vorher“, „8 Wochen vorher“, „3 Monate vorher“ |

Ist ein Datum eingetragen, steht unter dem Punkt „fällig am 05.06.2026 (in 12 Tagen)“. Fehlt
das Datum, steht dort „Datum der Veranstaltung fehlt — kein Termin berechenbar“. Ist der Punkt
in sieben Tagen oder früher fällig und niemand eingetragen, trägt er das rote Etikett „niemand
zuständig“. Enthält der Text „Einkauf“, „besorg“ oder „bestell“, erscheint der Link „zur
Einkaufsliste springen“.

Offene Punkte mit Vorlauf erscheinen zwei Wochen vor ihrer Fälligkeit im Reiter „To-dos“.

### Einkaufsliste

| Feld | Bedeutung |
| --- | --- |
| Haken vor dem Posten | gekauft |
| „Menge“, „Einheit“, „Was“ | etwa „2“, „Pk“, „Brötchen“ |
| „Wer besorgt es“ | Name |
| „Preis (€)“ | Ausgabe für diesen Posten, etwa „12,90“ |

Unter der Liste steht die Summe: „Ausgaben: 44,90 €, davon schon gekauft 32,00 €“. Die Summe
geht in den Rückblick ein (Saldo).

| Knopf | Was er tut |
| --- | --- |
| „+ Posten“ | neue Zeile |
| „+ Standardliste aus der Vorlage“ | ergänzt die Posten aus der Standard-Einkaufsliste der Vorlage, die noch fehlen (Vergleich nach „Was“). Haken stehen danach auf „nicht gekauft“. |
| „Als Text kopieren“ | Kopiert die Liste als Text für WhatsApp: Kopfzeile „Einkauf — <Name>, <Datum>“, dann je Zeile `[x]` oder `[ ]`, Menge, Einheit, Was, „— Wer“. Preise stehen nicht drin. |
| „Als CSV“ | Lädt `einkauf-<kurzname>.csv` herunter mit Menge, Einheit, Was, Wer besorgt, Preis (EUR), gekauft (ja/nein). Öffnet sich in Excel. |

Was in die Einkaufsliste geht, wird wie alles andere erst mit „Speichern“ dauerhaft.

---

## 9. Auswertung: Rückblick, Geld und Rückmeldungen

Der letzte Abschnitt im Editor heißt „Rückblick — für das nächste Mal“. Du füllst ihn nach der
Veranstaltung aus.

### Rückmeldungen der Eltern

Haken „Rückmeldungen der Eltern einsammeln — erzeugt einen eigenen Link“ setzen und speichern.
Dann erscheint der Link zur Rückmeldeseite (`feedback.html?event=…`) und der Knopf
„Rückmeldelink kopieren“. Den Link schickst du nach der Veranstaltung an alle Eltern. Auf der
Anmeldeseite erscheint er außerdem, sobald das Datum vorbei ist.

Eltern geben eine Note von 1 („ging gar nicht“) bis 5 („richtig gut“), schreiben, was gut war und was sich ändern sollte, und auf
Wunsch ihren Namen. Im Editor siehst du die Zahl der Rückmeldungen, den Schnitt („4,2 von 5 im
Schnitt“) und jede Rückmeldung mit „Gut:“, „Ändern:“, Name oder „anonym“ und Datum. Löschen
lassen sich Rückmeldungen im Orga-Bereich nicht. Nimmst du den Haken wieder raus, siehst du die
eingegangenen Rückmeldungen nicht mehr (sie bleiben aber gespeichert).

### Zahlen und Bewertung

| Feld | Bedeutung |
| --- | --- |
| „Tatsächlich da (Personen)“ | Von Hand, etwa aus dem Zählen am Eingang. |
| „Angemeldet waren“ | Gerechnet aus den Anmeldungen (Personen beider Gruppen), nicht änderbar. |
| „<Kategorie> — tatsächlich“ | Je Kategorie, vorbelegt aus den zugesagten Mitbringseln, überschreibbar. |
| „Bewertung“ | Je Kategorie: „noch offen“, „zu wenig“, „hat gepasst“, „zu viel“. |
| „Was war gut, was fehlte?“ | Freier Text. |

Wichtig: Fülle den Rückblick aus und speichere, **bevor die Löschfrist abläuft**. Danach gibt es
keine Anmeldungen mehr, aus denen „Angemeldet waren“ und die Vorbelegung gerechnet werden; beide
zeigen dann 0. Die Zusammenfassung, die das Aufräumen vorher schreibt, bleibt erhalten und
erscheint beim nächsten Mal im Kasten „Aus den letzten Malen“.

### Geld

Sobald es Einnahmen oder Ausgaben gibt, zeigt der Rückblick den Block „Geld“:

| Wert | Woher |
| --- | --- |
| „Einnahmen laut Anmeldungen“ | Summe der Beträge aller Anmeldungen (Soll), nicht was schon bezahlt ist |
| „Ausgaben laut Einkaufsliste“ | Summe der Preise in der Einkaufsliste |
| „Saldo“ | Einnahmen minus Ausgaben, rot wenn negativ |

Beim Speichern werden Einnahmen und Ausgaben im Rückblick festgehalten. Sind die Anmeldungen
nach der Frist gelöscht, zeigt der Block den zuletzt festgehaltenen Wert.

### Zielwerte aus dem Rückblick

Wird eine Veranstaltung aus einer Vorlage angelegt, die schon gelaufen ist, steht oben im Editor
„Aus den letzten Malen“: für jede frühere Veranstaltung Anmeldungen, Personen (und „tatsächlich
da“), eine Tabelle mit Kategorie, Ziel, Ist und Bewertung und die Notiz. Sind die Anmeldungen
schon gelöscht, steht dabei „(aus der Zusammenfassung, die Anmeldungen sind gelöscht)“.

Gibt es beim jüngsten Rückblick Bewertungen, erscheint „Zielwerte aus dem Rückblick übernehmen“.
Der Knopf setzt die Ziele der Kategorien so:

| Bewertung | Neues Ziel |
| --- | --- |
| „zu wenig“ | Ist plus 25 %, mindestens Ist plus 2 |
| „hat gepasst“ | Ist |
| „zu viel“ | Ist minus 15 %, mindestens 1 |

Das gilt nur für Kategorien mit derselben Kennung wie beim letzten Mal (also aus derselben
Vorlage). Prüf die Werte gegen die erwartete Personenzahl und speichere dann.

---

## 10. Anmeldungen

„Anmeldungen“ auf einer Karte im Reiter „Veranstaltungen“ öffnet die Liste. „← Zurück zur
Übersicht“ führt zurück.

### Summen oben

| Wert | Wann |
| --- | --- |
| „Anmeldungen“ | bei normalen Veranstaltungen: Zahl aller Einträge, Absagen eingeschlossen |
| „Zusagen“, „Absagen“, „ohne Antwort“ | bei Pflichtveranstaltungen; „ohne Antwort“ nur mit „Wie viele Familien insgesamt?“ |
| Personen je Gruppe | je eingeschalteter Gruppe |
| „Mitbringsel“ | Zahl aller Mitbringsel |
| „da“, „Stunden zusammen“ | mit Check-in |
| Menge je Bestellartikel | bei Bestellungen mit Stückpreis, ohne Absagen |
| „Einnahmen (Soll)“, „bezahlt“, „offen (2 Familien)“ | wenn die Veranstaltung etwas kostet |

### Knöpfe

| Knopf | Was er tut |
| --- | --- |
| „+ Anmeldung eintragen“ | Formular für Zusagen per Zettel oder Anruf |
| „Als CSV exportieren“ | Tabelle für Excel, siehe unten |
| „Aktualisieren“ | Liste neu laden |
| „Nur offene Zahlungen“ | nur wenn die Veranstaltung etwas kostet; siehe unten. Ein zweiter Tipp („Alle Anmeldungen zeigen“) hebt den Filter auf. |

### Aufgabenstand

Haben Helfer Aufgaben am Tag übernommen (Haken „Aufgaben werden vor Ort verteilt“), zeigt der
Kasten „Aufgabenstand“ je Aufgabe, wer sie übernommen hat (mit ✓, wenn abgehakt), und
„niemand“, „läuft“ oder „erledigt“.

### Die Tabelle

| Spalte | Inhalt |
| --- | --- |
| „Wer“ | Name, Etikett „abgemeldet“ bei Absagen, Personen je Gruppe, Check-in, Zahlung, Anmerkung (bei Absagen die Begründung), Antworten auf Zusatzfragen |
| „Bringt mit“ | Mitbringsel mit Menge und Kategorie |
| „Hilft bei“ | vorab angekreuzte Aufgaben |
| (ohne Titel) | „bearbeiten“ und „löschen“ |

Ist noch niemand angemeldet, steht dort „Noch keine Anmeldung. Teile den Link, dann füllt sich
die Liste.“

### Anmeldung von Hand eintragen oder bearbeiten

„+ Anmeldung eintragen“ oder „bearbeiten“ öffnet das Formular („Anmeldung eintragen“ bzw.
„Anmeldung bearbeiten“). Der Eintrag erscheint für die Eltern wie jede andere Anmeldung.

| Feld | Bedeutung |
| --- | --- |
| „Name“ | Pflicht. Steht der Name schon auf der Liste, fragt die Seite nach. |
| Personengruppen | Auswahl von 0 bis „höchstens“ |
| „Bringt mit“ | je Zeile Kategorie, „Was genau?“ und Menge; „+ Mitbringsel“ für weitere |
| „Hilft bei“ | Aufgaben mit „2 frei“ oder „voll, geht aber“; du kannst also über die Plätze hinaus eintragen |
| Bestellartikel | Anzahl je Bestellung mit Stückpreis |
| „Anmerkung“ | freier Text |

„Eintragen“ speichert, „Abbrechen“ schließt das Formular.

Was das Formular nicht kann:

- Andere Zusatzfragen als Bestellungen lassen sich hier nicht beantworten oder ändern. Beim
  Bearbeiten bleiben die vorhandenen Antworten erhalten.
- Eine Zusage lässt sich hier nicht in eine Absage umwandeln oder umgekehrt.
- Wer vom Orgateam eingetragen wird, hat **keinen persönlichen Link**. Ändern kann den Eintrag
  dann nur das Orgateam.

### Der persönliche Link der Eltern

Jede Familie bekommt nach dem Anmelden einen persönlichen Link, mit dem sie ihren Eintrag
ändert oder sich abmeldet. Der Link enthält ein geheimes Zeichen, das auch das Orgateam nicht
lesen kann. **Der Orga-Bereich kann den persönlichen Link deshalb weder anzeigen noch neu
verschicken.** Hat eine Familie ihn verloren, änderst du ihren Eintrag selbst mit „bearbeiten“
oder löschst ihn, und sie meldet sich neu an.

### Anmeldung löschen

„löschen“ fragt nach („Anmeldung von … löschen?“) und wirkt sofort, ohne Rückholen. Ist für die
Anmeldung ein Zahlungseingang eingetragen, warnt die Rückfrage: Mit der Anmeldung verschwindet
auch der Zahlungseingang. Erst zurückzahlen, dann löschen.

Eltern können eine Anmeldung, für die ein Zahlungseingang eingetragen ist, über ihren
persönlichen Link nicht mehr löschen. Absagen über das Formular geht weiter. Löschen muss dann
das Orgateam.

### Zahlungseingang abhaken

Kostet die Veranstaltung etwas, steht bei jeder Anmeldung ein Haken für die Person, die das
Geld sammelt:

| Anzeige | Bedeutung |
| --- | --- |
| „18,50 € offen“ (Haken aus) | Betrag noch nicht eingegangen |
| „bezahlt 18,50 € am 12.09.2026“ (Haken an) | Haken setzen speichert den Betrag, der in diesem Moment fällig ist, und das Datum |
| „Anmeldung geändert, jetzt 21,00 € — noch 2,50 € offen“ | Die Familie hat nach dem Abhaken mehr angemeldet oder bestellt |
| „… — 2,50 € zu viel“ | Die Familie hat nach dem Abhaken reduziert |
| „abgemeldet, hat aber 18,50 € bezahlt — zurückzahlen?“ mit „bezahlt (Haken weg, wenn erstattet)“ | Absage nach Zahlung. Nach dem Erstatten den Haken entfernen. |

Haken entfernen löscht den Zahlungseingang. Bei einer Differenz: Haken raus und wieder rein
speichert den neuen Betrag.

**„Nur offene Zahlungen“** zeigt nur Anmeldungen mit offenem Betrag und Absagen, die schon
bezahlt haben. Darüber steht „4 von 20 Anmeldungen mit offenem Betrag.“ oder „Alles bezahlt.
Niemand ist mehr offen.“ Anmeldungen mit zu viel gezahltem Betrag zeigt der Filter nicht.

„bezahlt“ in den Summen enthält auch Zahlungen von Familien, die inzwischen abgesagt haben.

### Export als CSV

„Als CSV exportieren“ lädt `anmeldungen-<kurzname>.csv` herunter. Spalten: Name, Status
(zugesagt/abgemeldet), die beiden Gruppen, Mitbringsel, Aufgaben, Anmerkung, je eine Spalte pro
Zusatzfrage, Betrag (EUR), Bezahlt (EUR), Bezahlt am, mit Check-in zusätzlich Da, Gekommen,
Gegangen, Stunden, und Angemeldet am. Die Datei ist mit Semikolon getrennt und öffnet sich in
Excel mit Umlauten und rechenbaren Beträgen. Sie enthält Namen; entsprechend ablegen und nach
Gebrauch löschen.

---

## 11. Check-in am Eingang

Mit dem Check-in scannen die Eltern am Veranstaltungstag einen Aushang am Eingang, auf Wunsch
auch beim Gehen. So siehst du, wer da war und wie lange, etwa für Arbeitsstunden.

### Einschalten und Aushang drucken

1. Im Editor unter „Eckdaten“ den Haken „Check-in per QR-Code“ setzen. Die Veranstaltung braucht
   ein Datum.
2. „Speichern“.
3. „Aushang mit QR-Code“ antippen. Ohne Speichern oder ohne Datum meldet die Seite, was fehlt.
4. Es öffnet sich der Aushang: Kitaname, Name der Veranstaltung, Datum, Uhrzeit und Ort, „Hier
   einchecken“, der QR-Code, eine kurze Erklärung und der Link in Kleinschrift.
5. „Drucken“ druckt nur den Aushang. „Schließen“ führt zurück in den Editor.

Der QR-Code führt auf die Anmeldeseite mit einem Code für diese Veranstaltung
(`fest-anmeldung.html?event=…&checkin=CODE`). Der Code entsteht beim ersten Öffnen des Aushangs
und bleibt danach gleich; du kannst den Aushang also jederzeit noch einmal drucken.

**„Neuen Code erzeugen“** verwirft den alten Code. Schon gedruckte Aushänge funktionieren danach
nicht mehr. Sinnvoll, wenn ein Foto des Aushangs herumgeht. Danach den neuen Aushang drucken und
aufhängen.

### Was die Eltern tun

- Einchecken geht nur am Tag der Veranstaltung (deutsche Zeit).
- Eltern mit Anmeldung tippen auf „Wir sind da“. Das Handy merkt sich die Anmeldung, wenn sie
  dort angemeldet wurden oder den persönlichen Link geöffnet haben.
- Wer nicht angemeldet ist, meldet sich beim Scannen kurz an und ist dann eingecheckt.
- Wer abgesagt hat und trotzdem scannt, bekommt den Hinweis, unten auf „Wir kommen“ zu tippen
  und zu speichern. Danach ist die Familie zugesagt und eingecheckt.
- Beim Gehen können Eltern auschecken. Dann rechnet das Tool die Dauer.

### Anwesenheit in den Anmeldungen

Mit Check-in steht bei jeder Zusage ein Haken „war da“:

| Anzeige | Bedeutung |
| --- | --- |
| „nicht eingecheckt“ | noch nicht da |
| „da ab 14:05 bis 17:40“ | per QR ein- und ausgecheckt |
| „da (vom Orgateam abgehakt)“ | von Hand abgehakt |

- **Von Hand abhaken:** Haken setzen, etwa für Eltern ohne Handy. Das geht an jedem Tag.
- **Haken entfernen** löscht den Eintrag samt Uhrzeiten.
- **Stunden:** Neben einem gesetzten Haken steht ein Feld „Std.“. Es zeigt die gerechnete Dauer
  und lässt sich überschreiben, etwa „3,5“ (0 bis 24). Ein eingetragener Wert gilt vor der
  gerechneten Dauer. Feld leeren stellt wieder auf die gerechnete Dauer.

Oben stehen „da“ (Zahl) und „Stunden zusammen“. Abgesagte Anmeldungen haben keinen Haken, außer
sie waren trotzdem eingecheckt.

---

## 12. Reiter „Vorlagen“

Vorlagen sind für alles, was wiederkommt: Sommerfest, Laternenfest, Oma-Opa-Tag. Jede
Veranstaltung aus einer Vorlage erbt deren Inhalt und sammelt ihre eigene Historie. Daraus
entstehen beim nächsten Mal „Aus den letzten Malen“, die Zielvorschläge und die offenen
Aufgaben vom letzten Mal.

### Die Liste

Jede Vorlage zeigt Name, Kurzbeschreibung, Zahl der Kategorien, Aufgaben und
Checklistenpunkte und ein Etikett: „neu“ oder „2× gelaufen“.

| Knopf | Was er tut |
| --- | --- |
| „Veranstaltung daraus anlegen“ | Öffnet den Editor einer neuen Veranstaltung |
| „Bearbeiten“ | Öffnet den Vorlagen-Editor |
| „Löschen“ | Löscht nach Rückfrage (Name abtippen). Veranstaltungen daraus bleiben, verlieren aber die Verbindung und damit Historie und Zielvorschläge. |

### Vorlagen-Editor

„+ Neue Vorlage“ oder „Bearbeiten“. Abschnitte:

| Abschnitt | Inhalt |
| --- | --- |
| „Eckdaten“ | „Name“ (Pflicht), „Kurzbeschreibung“, „Wen soll die Anmeldung zählen?“ |
| „Kosten und Bezahlung“ | wie im Editor der Veranstaltung |
| „Mitbringsel-Kategorien“ | wie dort |
| „Aufgaben am Veranstaltungstag“ | wie dort, aber ohne Fotos (siehe unten) |
| „Zusätzliche Fragen“ | wie dort |
| „Standard-Einkaufsliste“ | wird jeder Veranstaltung daraus mitgegeben |
| „Planungs-Checkliste“ | mit „Wer“ und „Vorlauf“; ein Fälligkeitsdatum gibt es erst in der Veranstaltung |

„Vorlage speichern“ speichert, „Fertig, zur Übersicht“ führt zurück.

Aufgaben in der Vorlage haben kein Feld „Fotos“. Fotos fügst du in der Veranstaltung hinzu.

### Was „Veranstaltung daraus anlegen“ übernimmt

| Wird übernommen | Wird nicht übernommen |
| --- | --- |
| Name plus Jahr („Sommerfest 2026“), Kurzname daraus | Datum, Uhrzeit, Ort, Begrüßungstext |
| Personengruppen | Sichtbarkeit (steht auf Standard) |
| Kosten und Zahlweg | Pflichtveranstaltung, Check-in |
| Kategorien, Aufgaben, Zusatzfragen | Löschfrist (steht auf 14 Tage) |
| Checkliste, Einkaufsliste (als Startpunkt) | Freigabe (ist aus) |

Spätere Änderungen an der Vorlage ändern bestehende Veranstaltungen nicht. Mit „+
Standardaufgaben aus der Vorlage“ und „+ Standardliste aus der Vorlage“ holst du Ergänzungen
nachträglich in eine Veranstaltung.

---

## 13. Sichern und Exportieren

Im Reiter „Veranstaltungen“ oben:

| Knopf | Datei | Inhalt |
| --- | --- | --- |
| „Alles sichern (JSON)“ | `<kitaname>-sicherung-<datum>.json` | Vorlagen, Veranstaltungen, Planung (Checklisten, Rückblicke) und alle Anmeldungen mit Namen |
| „Alle Anmeldungen (CSV)“ | `<kitaname>-anmeldungen-alle-<datum>.csv` | eine Zeile pro Anmeldung über alle Veranstaltungen: Veranstaltung, Datum, Name, Status, Personen, Mitbringsel, Aufgaben, Zusatzangaben, Betrag (EUR), Anmerkung, Angemeldet am |

Ist kein Kitaname eingestellt, beginnen die Dateinamen mit „kita“. Nicht in der JSON-Sicherung
stehen Einkaufslisten, Zahlungseingänge, Anwesenheit, Fotos, Meldungen und Rückmeldungen. Eine
vollständige Sicherung der Datenbank ist das nicht; die macht, wer die Datenbank betreut.

Beide Dateien enthalten Namen. Leg sie nur so lange ab, wie du sie brauchst.

Weitere Exporte: „Als CSV exportieren“ in den Anmeldungen ([Abschnitt 10](#export-als-csv)) und
„Als CSV“ bei der Einkaufsliste ([Abschnitt 8](#einkaufsliste)).

---

## 14. Was Eltern sehen und was nur das Orgateam sieht

| Was | Eltern auf den öffentlichen Seiten | Orgateam |
| --- | --- | --- |
| Name, Datum, Uhrzeit, Ort, Begrüßungstext | ja | ja |
| Veranstaltung auf der Startseite | solange nicht archiviert und Datum nicht vorbei | immer |
| Veranstaltung über den direkten Link | immer, auch archiviert | immer |
| Gesamtzahl der Anmeldungen und Personen, ohne Absagen | wenn Haken „Gesamtzahlen im Kopf“, auf der Anmeldeseite und der Startseite | immer |
| Liste der Mitbringsel | wenn Haken „Liste der Mitbringsel“, sonst nur Fortschrittsbalken | immer |
| Namen an Mitbringseln und vorab angekreuzten Aufgaben | wenn die jeweiligen Haken gesetzt sind, gekürzt | immer, voller Name |
| Namen bei Aufgaben am Tag („Ich mach das“) | immer, ungekürzt, so wie eingetippt | ja |
| Aufgaben mit Erklärung und Fotos | ja, für alle mit dem Link | ja |
| Eigener Betrag, Zahlungshinweis, Zahlweg | ja, nach dem Anmelden | ja |
| PayPal-Adresse als Zahlweg | für alle mit dem Link | ja |
| Anmerkungen und Antworten auf Zusatzfragen anderer | nein | ja |
| wer abgesagt hat, und Begründungen | nein | ja |
| Zahlungseingänge | nein | ja |
| Anwesenheit und Stunden | nein | ja |
| Checkliste, Einkaufsliste, Rückblick, Geld | nein | ja |
| Rückmeldungen | nein (nur die eigene beim Abschicken) | ja |
| Gemeldete Aufgaben | die meldende Person sieht offene Meldungen | ja |
| Vorlagen | nein | ja |

Ganze Anmeldungen mit vollem Namen, Anmerkung, Antworten auf Zusatzfragen und Absagegrund
liefert die Datenbank nur an das Orgateam und an die Familie selbst über ihren persönlichen
Link. Die Elternseiten bekommen nur Personenzahlen, Mitbringsel, Aufgaben, ob zu- oder abgesagt
ist, und den gekürzten Namen. Den Namen nur, wenn bei der Veranstaltung „Namen an den
Mitbringseln“ oder „Namen in der Helferliste“ gesetzt ist. Welche dieser Angaben die Seite
anzeigt, bestimmen die Haken unter „Was sehen die Gäste auf der Seite?“. Ändern oder löschen
kann eine Anmeldung nur das Orgateam oder wer den persönlichen Link hat.

Ausnahme sind die Aufgaben am Tag: Was Helfer bei „Ich mach das“ eintippen, ist für alle mit
dem Link lesbar, ungekürzt.

---

## 15. Datenschutz und Fristen

### Was automatisch gelöscht oder anonymisiert wird

Das Aufräumen läuft jedes Mal, wenn sich jemand im Orga-Bereich anmeldet oder zur Übersicht
zurückkehrt, und, falls in der Datenbank eingerichtet, jede Nacht um 3 Uhr.

| Was | Wann | Was passiert |
| --- | --- | --- |
| Anmeldungen (mit Zahlungseingang und Anwesenheit) | nach Ablauf der Löschfrist, gezählt ab dem Veranstaltungstag | gelöscht |
| Aufgabenübernahmen am Tag | nach Ablauf der Löschfrist | gelöscht |
| Anmeldungen ohne zugehörige Veranstaltung (Veranstaltung gelöscht) | beim nächsten Aufräumen | gelöscht |
| Veranstaltung | nach Ablauf der Löschfrist, wenn keine Anmeldungen mehr da sind | archiviert |
| Namen unter Rückmeldungen | 60 Tage nach dem Veranstaltungstag | Name entfernt, Text bleibt |
| Namen unter gemeldeten Aufgaben | 60 Tage nach dem Veranstaltungstag | Name entfernt, Text bleibt |

**Veranstaltungen ohne Datum werden nie aufgeräumt.** Das Datum ist die Grundlage aller Fristen.

### Was vorher gesichert wird

Bevor Anmeldungen gelöscht werden, schreibt das Aufräumen eine Zusammenfassung ohne Namen in den
Rückblick: Zahl der Anmeldungen, Erwachsene, Kinder, Mengen je Kategorie und Aufgabe, Zahl der
Anwesenden und Stunden, Einnahmen und bezahlte Summe. Daraus speist sich beim nächsten Mal „Aus
den letzten Malen“.

### Was dauerhaft bleibt

Veranstaltungen, Vorlagen, Checklisten, Einkaufslisten, Rückblicke mit Zahlen und Geld, Fotos
der Aufgaben, Texte und Noten der Rückmeldungen, Texte der Meldungen. Was du löschen willst,
löschst du mit „Löschen“ auf der Karte.

### Sichtbarkeit und Löschfrist sind ein Versprechen

Der Einwilligungstext auf der Anmeldeseite wird aus den Einstellungen der Veranstaltung gebaut:
was für alle sichtbar ist (Mitbringsel, Aufgaben, mit oder ohne Namen), dass das Orgateam alles
sieht und Zahlungen festhält, dass beim Check-in Kommen und Gehen festgehalten werden und dass
das Handy sich die Anmeldung merkt, und wann gelöscht wird.

**Wer Sichtbarkeit oder Löschfrist ändert, ändert ein Versprechen an die Eltern.** Wer sich schon
angemeldet hat, hat dem alten Text zugestimmt. Deshalb:

- Sichtbarkeit und Löschfrist vor dem Freigeben der Anmeldung festlegen.
- Nach dem Freigeben nur in Richtung „weniger zeigen“ und „früher löschen“ ändern, oder die
  Angemeldeten informieren.
- Steht ein eigener „Abweichender Hinweistext“ drin, ihn nach jeder Änderung der Frist
  prüfen ([Abschnitt 6](#löschfrist-und-hinweistext)).
- Check-in und Kosten erst einschalten, wenn klar ist, dass ihr sie braucht; beides erweitert
  den Einwilligungstext.

### Eure eigenen Dateien

Sicherungen und CSV-Exporte mit Namen landen in deinen Downloads. Lösch sie, wenn du sie nicht
mehr brauchst. Für Fotos zu Aufgaben gilt: keine Kinder darauf.

---

## 16. Häufige Fragen und Probleme

| Problem | Lösung |
| --- | --- |
| Roter Kasten „Die Datenbank ist nicht auf dem Stand dieser Version.“ | Die genannten Migrationen fehlen. Nichts anlegen, die Person informieren, die die Datenbank betreut ([Abschnitt 3](#3-hinweis-auf-eine-veraltete-datenbank)). |
| Beim Speichern „Der Datenbank fehlt eine Spalte …“ | Fenster offen lassen, Migration ausführen lassen, dann noch einmal „Speichern“. |
| Beim Speichern „Die Datenbank verweigert das Anlegen.“ | „Abmelden“, neu anmelden. Meist ist das Passwort in dieser Sitzung nicht mehr gültig (zum Beispiel nach einem Passwortwechsel). |
| „Passwort stimmt nicht.“ | Passwort aus dem Passwortsafe des Vereins nehmen. Ein neues erzeugen: `einrichtung/ANLEITUNG.md`. |
| Nach dem Schließen des Tabs muss ich mich neu anmelden. | So gewollt: Das Passwort bleibt nur im offenen Tab. |
| Eltern sehen die Veranstaltung nicht auf der Startseite. | Archiviert oder Datum vorbei. Der direkte Link funktioniert trotzdem. |
| Eltern können sich nicht eintragen. | Haken „Anmeldung freigegeben“ fehlt, „Frühestens ab“ liegt in der Zukunft oder „Anmeldeschluss“ ist vorbei. Etikett auf der Karte zeigt den Grund. |
| Beim Speichern „Der Kurzname bleibt …: Es gibt schon … Anmeldungen …“ | Sobald es Anmeldungen gibt, bleibt der Kurzname. Die Seite hat den alten wieder eingetragen. Noch einmal „Speichern“ sichert die übrigen Änderungen. |
| „Der Kurzname … gehört schon zu …“ | Die Seite hat einen freien Kurznamen eingetragen. Noch einmal „Speichern“ oder selbst einen anderen wählen. |
| Eine Familie hat ihren persönlichen Link verloren. | Den Link kann der Orga-Bereich nicht anzeigen. Eintrag mit „bearbeiten“ selbst ändern, oder löschen und neu anmelden lassen. |
| Eltern können sich über ihren Link nicht löschen. | Für die Anmeldung ist ein Zahlungseingang eingetragen. Zurückzahlen, dann löscht das Orgateam. Absagen über das Formular geht. |
| Abgesagt, aber schon bezahlt. | Die Anmeldung zeigt „… zurückzahlen?“. Erstatten, dann Haken „bezahlt“ entfernen. |
| Bei einer bezahlten Anmeldung steht „noch … offen“ oder „zu viel“. | Die Familie hat ihre Anmeldung geändert. Restbetrag einfordern oder erstatten, dann Haken raus und wieder rein. |
| Bestellmengen sind aus der Rechnung verschwunden. | Die Frage wurde umbenannt. Alten Text der Frage wiederherstellen und speichern. |
| Zahlweg wird nicht gespeichert, Hinweis ist rot. | Eingabe ist weder `https://`-Link noch E-Mail-Adresse noch PayPal.me-Name. |
| Der Einwilligungstext nennt die falsche Löschfrist. | „Abweichender Hinweistext“ leeren oder anpassen, speichern. |
| „Aushang mit QR-Code“ meldet einen Fehler. | Erst mit Haken bei Check-in speichern. Die Veranstaltung braucht ein Datum. |
| Der QR-Code am Eingang funktioniert nicht. | Check-in geht nur am Veranstaltungstag. Wurde „Neuen Code erzeugen“ benutzt, gilt nur der neue Aushang. |
| Jemand kam ohne Handy. | In den Anmeldungen den Haken „war da“ setzen, Stunden von Hand eintragen. Ohne Anmeldung vorher „+ Anmeldung eintragen“. |
| Ein Checklistenpunkt steht nicht in den To-dos. | Vorlauf ist „kein fester Termin“, die Veranstaltung hat kein Datum, ist archiviert oder vorbei, oder der Punkt ist mehr als zwei Wochen entfernt. |
| Der Knopf „Zielwerte aus dem Rückblick übernehmen“ fehlt. | Die Veranstaltung ist nicht aus einer Vorlage, oder beim letzten Mal wurde keine Kategorie bewertet, oder die Ziele stimmen schon. |
| „Angemeldet waren“ zeigt 0. | Die Löschfrist ist abgelaufen, die Anmeldungen sind weg. Die Zusammenfassung steht beim nächsten Mal unter „Aus den letzten Malen“. Künftig den Rückblick vor Ablauf der Frist ausfüllen. |
| Eine Zeile aus Versehen entfernt. | 30 Sekunden lang „Rückgängig“. Danach: Editor ohne Speichern verlassen, dann ist der alte Stand noch da. |
| Bei Aufgaben in der Vorlage fehlt das Feld „Fotos“. | Vorlagen speichern keine Fotos. Fotos in der Veranstaltung hinzufügen. |
| Gemeldete Aufgabe übernommen, aber sie steht wieder bei den Meldungen. | Nach „Übernehmen“ nicht gespeichert. Noch einmal übernehmen und „Speichern“. |
| Rückmeldungen sind nicht mehr zu sehen. | Haken „Rückmeldungen der Eltern einsammeln“ wieder setzen. |
| Alles, was ich eingebe, ist nach dem Neuladen weg. | Demo-Modus: in `config.js` ist keine Datenbank eingetragen. |
