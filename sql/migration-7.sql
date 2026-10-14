-- Nachtrag 7: Erklaerungen und Fotos zu Aufgaben.
--
-- Die Bilder liegen als verkleinerte Datei in einer eigenen Tabelle,
-- nicht im Storage. Damit gelten dieselben Regeln wie fuer alles andere:
-- lesen darf jeder mit dem Link, hochladen und loeschen nur das Orgateam.
-- Wird ein Fest geloescht, verschwinden seine Bilder mit.

create table if not exists task_images (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  task_id text not null,
  caption text,
  data text not null,
  created_at timestamptz not null default now()
);

create index if not exists task_images_event_idx on task_images (event_id);

alter table task_images enable row level security;

drop policy if exists "bilder lesen"    on task_images;
drop policy if exists "bilder anlegen"  on task_images;
drop policy if exists "bilder loeschen" on task_images;

create policy "bilder lesen"    on task_images for select to anon using (true);
create policy "bilder anlegen"  on task_images for insert to anon with check (is_orga());
create policy "bilder loeschen" on task_images for delete to anon using (is_orga());
