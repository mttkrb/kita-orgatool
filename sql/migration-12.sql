-- Nachtrag 12: Rueckmeldungen der Eltern nach einer Veranstaltung.
--
-- Abgeben darf jeder mit dem Link, lesen nur das Orgateam. Das ist Absicht:
-- wer weiss, dass die Nachbarin mitliest, schreibt weniger ehrlich.

create table if not exists feedback (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  rating int,                -- 1 bis 5, optional
  good text,
  better text,
  from_name text,            -- freiwillig
  created_at timestamptz not null default now()
);

create index if not exists feedback_event_idx on feedback (event_id);

alter table feedback enable row level security;

drop policy if exists "feedback geben"    on feedback;
drop policy if exists "feedback lesen"    on feedback;
drop policy if exists "feedback loeschen" on feedback;

create policy "feedback geben"    on feedback for insert to anon with check (true);
create policy "feedback lesen"    on feedback for select to anon using (is_orga());
create policy "feedback loeschen" on feedback for delete to anon using (is_orga());
