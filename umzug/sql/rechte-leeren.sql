-- Nimmt anon, authenticated und service_role alle Rechte an den Objekten in public.
--
-- Supabase gibt neuen Tabellen von sich aus alle Rechte für anon. Beim Einspielen
-- entstehen die Tabellen neu und bekämen damit mehr Rechte als im alten Projekt,
-- unter anderem das Leserecht auf signups.token. Das Umzugsskript leert deshalb
-- zuerst alle Rechte und spielt danach genau die Rechte aus der Sicherung ein.
-- Spaltenrechte fallen mit dem Entzug der Tabellenrechte automatisch weg.
do $$
declare
  o record;
begin
  for o in
    select c.oid::regclass as name, c.relkind
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_class'::regclass and d.objid = c.oid and d.deptype = 'e')
  loop
    if o.relkind = 'S' then
      execute format('revoke all on sequence %s from anon, authenticated, service_role', o.name);
    else
      execute format('revoke all on table %s from anon, authenticated, service_role', o.name);
    end if;
  end loop;

  for o in
    select p.oid::regprocedure as name
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind in ('f', 'p')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
  loop
    execute format('revoke all on routine %s from anon, authenticated, service_role', o.name);
  end loop;
end $$;
