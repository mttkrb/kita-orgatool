-- ============================================================
--  Kita-Anmeldungen - Datenbank-Setup fuer Supabase
--
--  Diese Datei komplett markieren, in den Supabase SQL-Editor
--  einfuegen und "Run" druecken. Kann gefahrlos mehrfach
--  ausgefuehrt werden - bestehende Daten bleiben erhalten.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Tabellen
-- ------------------------------------------------------------

-- Vorlagen fuer wiederkehrende Feste
create table if not exists templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  categories jsonb not null default '[]',
  tasks jsonb not null default '[]',
  fields jsonb not null default '[]',
  checklist jsonb not null default '[]',
  created_at timestamptz not null default now()
);

-- Feste
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  event_date text,
  event_time text,
  place text,
  intro text,
  categories jsonb not null default '[]',
  tasks jsonb not null default '[]',
  fields jsonb not null default '[]',
  ask_people boolean not null default true,
  retention_note text,
  archived boolean not null default false,
  template_id uuid references templates(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table events add column if not exists template_id uuid references templates(id) on delete set null;

-- Personengruppen pro Fest, z.B. nur "Grosseltern" statt Erwachsene/Kinder
alter table events    add column if not exists people jsonb not null default '{}';
alter table events    add column if not exists event_on date;
alter table templates add column if not exists people jsonb not null default '{}';
alter table events    add column if not exists visibility jsonb not null default '{}';

-- Interne Planung: Checkliste und Rueckblick. Nur mit Orga-Passwort lesbar.
create table if not exists planning (
  event_id uuid primary key references events(id) on delete cascade,
  checklist jsonb not null default '[]',
  review jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

-- Anmeldungen
create table if not exists signups (
  id uuid primary key default gen_random_uuid(),
  event text not null,
  created_at timestamptz not null default now(),
  name text not null,
  adults int not null default 1,
  kids int not null default 0,
  items jsonb not null default '[]',
  tasks jsonb not null default '[]',
  fields jsonb not null default '{}',
  materials jsonb not null default '[]',
  note text,
  token text not null default encode(gen_random_bytes(8),'hex')
);

-- Orga-Passwoerter, eine Zeile pro Person oder Team
create table if not exists orga_keys (
  secret text primary key,
  label text
);
insert into orga_keys (secret, label)
values ('HIER-EIN-LANGES-ZUFALLS-PASSWORT', 'Orgateam')
on conflict do nothing;

-- ------------------------------------------------------------
-- 2. Prueffunktion fuer das Orga-Passwort.
--    Liest orga_keys mit erhoehten Rechten, ohne die Tabelle
--    selbst lesbar zu machen.
-- ------------------------------------------------------------
create or replace function is_orga() returns boolean
language sql
security definer
stable
as $function$
  select exists (
    select 1 from orga_keys k
    where k.secret = current_setting('request.headers', true)::json ->> 'x-orga-key'
  );
$function$;

grant execute on function is_orga() to anon;

-- ------------------------------------------------------------
-- 3. Row Level Security einschalten
-- ------------------------------------------------------------
alter table templates enable row level security;
alter table events    enable row level security;
alter table planning  enable row level security;
alter table signups   enable row level security;
alter table orga_keys enable row level security;   -- keine Policy = fuer anon unlesbar

-- Anmeldungen: alle Spalten ausser token sind oeffentlich lesbar
revoke select on signups from anon;
grant select (id, event, created_at, name, adults, kids, items, tasks, fields, materials, note)
  on signups to anon;

-- ------------------------------------------------------------
-- 4. Policies
-- ------------------------------------------------------------

-- Feste: lesen darf jeder, aendern nur das Orgateam
drop policy if exists "events lesen"    on events;
drop policy if exists "events anlegen"  on events;
drop policy if exists "events aendern"  on events;
drop policy if exists "events loeschen" on events;

create policy "events lesen"    on events for select to anon using (true);
create policy "events anlegen"  on events for insert to anon with check (is_orga());
create policy "events aendern"  on events for update to anon using (is_orga());
create policy "events loeschen" on events for delete to anon using (is_orga());

-- Vorlagen und Planung: nur das Orgateam, auch beim Lesen
drop policy if exists "vorlagen" on templates;
drop policy if exists "planung"  on planning;

create policy "vorlagen" on templates for all to anon using (is_orga()) with check (is_orga());
create policy "planung"  on planning  for all to anon using (is_orga()) with check (is_orga());

-- Anmeldungen: lesen und anlegen offen, aendern nur mit eigenem Token
drop policy if exists "anmelden"        on signups;
drop policy if exists "anmeldung neu"   on signups;
drop policy if exists "eigene aendern"  on signups;
drop policy if exists "eigene loeschen" on signups;

create policy "anmelden"      on signups for select to anon using (true);
create policy "anmeldung neu" on signups for insert to anon with check (true);

create policy "eigene aendern" on signups for update to anon
  using (
    token = (current_setting('request.headers', true)::json ->> 'x-entry-token')
    or is_orga()
  );

create policy "eigene loeschen" on signups for delete to anon
  using (
    token = (current_setting('request.headers', true)::json ->> 'x-entry-token')
    or is_orga()
  );

-- ------------------------------------------------------------
-- 5. Zum Schluss: eigenes Orga-Passwort setzen.
--    Naechste Zeile anpassen, Doppelstrich entfernen, ausfuehren.
-- ------------------------------------------------------------
-- update orga_keys set secret = 'dein-langes-zufalls-passwort' where label = 'Orgateam';
