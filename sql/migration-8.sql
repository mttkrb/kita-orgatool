-- Nachtrag 8: Aufgabenliste zum Mitmachen am Tag selbst.
--
-- Bildet die ausgehaengte Liste ab: jemand schreibt seinen Namen an eine
-- Aufgabe und streicht sie durch, wenn sie fertig ist. Deshalb darf hier
-- jeder mit dem Link eintragen, abhaken und wieder loeschen - genau wie
-- am Aushang mit dem Stift. Namen und Stand sind fuer alle sichtbar.

create table if not exists task_claims (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  task_id text not null,
  name text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists task_claims_event_idx on task_claims (event_id);

alter table task_claims enable row level security;

drop policy if exists "aufgaben lesen"    on task_claims;
drop policy if exists "aufgaben belegen"  on task_claims;
drop policy if exists "aufgaben aendern"  on task_claims;
drop policy if exists "aufgaben freigeben" on task_claims;

create policy "aufgaben lesen"     on task_claims for select to anon using (true);
create policy "aufgaben belegen"   on task_claims for insert to anon with check (true);
create policy "aufgaben aendern"   on task_claims for update to anon using (true);
create policy "aufgaben freigeben" on task_claims for delete to anon using (true);
