-- Nachbau der Supabase-Umgebung für die Rechteprüfung: Rollen, Schema extensions mit
-- pgcrypto und die Standardrechte, die Supabase neuen Tabellen gibt. Danach laufen
-- schema.sql und alle Migrationen wie im echten Projekt.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  execute format('alter database %I set search_path = public, extensions', current_database());
end $$;
create schema if not exists extensions;
create extension if not exists pgcrypto schema extensions;
grant usage on schema public to anon, authenticated;
grant usage on schema extensions to anon, authenticated;
-- Supabase gibt neuen Tabellen und Funktionen alle Rechte für anon
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant execute on functions to anon, authenticated;
