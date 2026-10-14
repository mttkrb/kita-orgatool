-- Nachtrag 9: Aufgabenvorschlaege von Leitung, Vorstand und Teamleitungen.
--
-- Wer den Vorschlagslink hat, darf eintragen - lesen, aendern und loeschen
-- kann nur das Orgateam. Damit ist das Formular offen, die Sammlung aber nicht.

create table if not exists proposals (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  title text not null,
  info text,
  needed int not null default 2,
  from_name text,
  image text,
  status text not null default 'neu',   -- neu | uebernommen | abgelehnt
  note text,
  created_at timestamptz not null default now()
);

create index if not exists proposals_event_idx on proposals (event_id, status);

alter table proposals enable row level security;

drop policy if exists "vorschlag einreichen" on proposals;
drop policy if exists "vorschlaege lesen"    on proposals;
drop policy if exists "vorschlaege aendern"  on proposals;
drop policy if exists "vorschlaege loeschen" on proposals;

create policy "vorschlag einreichen" on proposals for insert to anon with check (true);
create policy "vorschlaege lesen"    on proposals for select to anon using (is_orga());
create policy "vorschlaege aendern"  on proposals for update to anon using (is_orga());
create policy "vorschlaege loeschen" on proposals for delete to anon using (is_orga());
