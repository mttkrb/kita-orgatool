-- Minimaler Nachbau der Supabase-Umgebung und des Schemas vor Migration 21.
-- Grundlage ist der historische Stand im Kopf von orga.html, ergänzt um die Spalten, die
-- die Seiten heute erwarten. Nur für die Rechteprüfung der neuen Migrationen gedacht,
-- kein Ersatz für schema.sql und migration-2 … 20.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  execute format('alter database %I set search_path = public, extensions', current_database());
end $$;
create schema extensions; create extension pgcrypto schema extensions;
set search_path = public, extensions;
grant usage on schema public to anon, authenticated;
grant usage on schema extensions to anon, authenticated;
-- Supabase gibt neuen Tabellen alle Rechte für anon
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant execute on functions to anon, authenticated;

create table templates (id uuid primary key default gen_random_uuid(), name text not null, description text,
  categories jsonb not null default '[]', tasks jsonb not null default '[]', fields jsonb not null default '[]',
  checklist jsonb not null default '[]', people jsonb not null default '{}', shopping jsonb not null default '[]',
  created_at timestamptz not null default now());
create table events (id uuid primary key default gen_random_uuid(), slug text unique not null, title text not null,
  event_date text, event_time text, place text, intro text, categories jsonb not null default '[]',
  tasks jsonb not null default '[]', fields jsonb not null default '[]', ask_people boolean not null default true,
  retention_note text, archived boolean not null default false, template_id uuid references templates(id) on delete set null,
  people jsonb not null default '{}', visibility jsonb not null default '{}', event_on date, signup_from date, signup_until date,
  signup_released boolean not null default true, retention_days int not null default 14, mandatory boolean not null default false,
  expected_families int, created_at timestamptz not null default now());
create table planning (event_id uuid primary key references events(id) on delete cascade, checklist jsonb not null default '[]',
  review jsonb not null default '{}', shopping jsonb not null default '[]', updated_at timestamptz not null default now());
create table signups (id uuid primary key default gen_random_uuid(), event text not null, created_at timestamptz not null default now(),
  name text not null, adults int not null default 1, kids int not null default 0, items jsonb not null default '[]',
  tasks jsonb not null default '[]', fields jsonb not null default '{}', note text, status text not null default 'zusage',
  materials jsonb not null default '[]', token text not null default encode(gen_random_bytes(8),'hex'));
create table orga_keys (secret text primary key, label text);
insert into orga_keys values ('geheim-orga', 'Orgateam');
create or replace function is_orga() returns boolean language sql security definer stable as $$
  select exists (select 1 from orga_keys k where k.secret = current_setting('request.headers', true)::json ->> 'x-orga-key'); $$;
grant execute on function is_orga() to anon;
alter table events enable row level security; alter table signups enable row level security;
alter table templates enable row level security; alter table planning enable row level security;
alter table orga_keys enable row level security;
revoke all on orga_keys from anon, authenticated;
revoke select on signups from anon;
grant select (id, event, created_at, name, adults, kids, items, tasks, fields, materials, note, status) on signups to anon;
create policy "events lesen" on events for select to anon using (true);
create policy "events anlegen" on events for insert to anon with check (is_orga());
create policy "events aendern" on events for update to anon using (is_orga());
create policy "events loeschen" on events for delete to anon using (is_orga());
create policy "vorlagen" on templates for all to anon using (is_orga()) with check (is_orga());
create policy "planung" on planning for all to anon using (is_orga()) with check (is_orga());
create policy "anmelden" on signups for select to anon using (true);
create policy "anmeldung neu" on signups for insert to anon with check (true);
create policy "eigene aendern" on signups for update to anon
  using (token = (current_setting('request.headers',true)::json ->> 'x-entry-token') or is_orga());
create policy "eigene loeschen" on signups for delete to anon
  using (token = (current_setting('request.headers',true)::json ->> 'x-entry-token') or is_orga());
