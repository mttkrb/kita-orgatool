-- Nachtrag 14: Anmeldezeitraum je Veranstaltung.
--
-- signup_from:  ab wann sich Eltern anmelden koennen (leer = sofort)
-- signup_until: bis wann (leer = bis zum Veranstaltungstag)
--
-- Vorher und nachher ist die Veranstaltung weiterhin sichtbar,
-- nur das Formular ist zu.

alter table events add column if not exists signup_from  date;
alter table events add column if not exists signup_until date;
