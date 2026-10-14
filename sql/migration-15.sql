-- Nachtrag 15: Anmeldung manuell freigeben.
--
-- Ersetzt den Zwang, vorab ein Startdatum zu kennen. Das Orgateam
-- schaltet frei, wenn Aufgaben und Kategorien stehen.
-- Bestehende Veranstaltungen bleiben freigegeben, damit laufende
-- Anmeldungen nicht ploetzlich zu sind.

alter table events add column if not exists signup_released boolean not null default true;
