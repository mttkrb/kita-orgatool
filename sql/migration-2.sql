-- Nachtrag: frei benennbare Personengruppen pro Fest.
-- Im Supabase SQL-Editor ausfuehren (leerer Tab, einfuegen, Run).
-- Bestehende Feste und Anmeldungen bleiben unveraendert.

alter table events    add column if not exists people jsonb not null default '{}';
alter table templates add column if not exists people jsonb not null default '{}';

alter table events add column if not exists visibility jsonb not null default '{}';
