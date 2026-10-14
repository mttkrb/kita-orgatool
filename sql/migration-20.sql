-- Nachtrag 20: Pflichtveranstaltungen mit Ab- und Zusage.
--
-- Beim Familiensamstag reicht es nicht, wer kommt zu wissen — wer nicht
-- kann, muss sich aktiv abmelden und einen Grund angeben. Deshalb bekommt
-- jede Anmeldung einen Status.

alter table signups add column if not exists status text not null default 'zusage';

alter table events add column if not exists mandatory boolean not null default false;
alter table events add column if not exists expected_families int;

-- Die neue Spalte muss oeffentlich lesbar sein, sonst zeigt die
-- Anmeldeseite den eigenen Eintrag nicht mehr richtig an
grant select (id, event, created_at, name, adults, kids, items, tasks, fields, materials, note, status)
  on signups to anon;
