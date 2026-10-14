-- Nachtrag 3: echtes Datumsfeld und Bearbeitungsrecht fuers Orgateam.
-- Im Supabase SQL-Editor ausfuehren (leerer Tab, einfuegen, Run).
-- Bestehende Daten bleiben unveraendert.

alter table events add column if not exists event_on date;

-- Orgateam darf Anmeldungen korrigieren, Gaeste weiterhin nur ihre eigene
drop policy if exists "eigene aendern" on signups;
create policy "eigene aendern" on signups for update to anon
  using (
    token = (current_setting('request.headers', true)::json ->> 'x-entry-token')
    or is_orga()
  );
