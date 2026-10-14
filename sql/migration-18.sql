-- Nachtrag 18: Aufbewahrungsfrist je Veranstaltung.
--
-- Bisher galten starre 14 Tage. Jetzt entscheidet das Orgateam pro
-- Veranstaltung, wie lange die Anmeldungen bleiben. Voreinstellung
-- bleibt 14 Tage, weil das die sparsamste Variante ist.

alter table events add column if not exists retention_days int not null default 14;

create or replace function daten_aufraeumen()
returns table(was text, anzahl integer)
language plpgsql
security definer
as $funktion$
declare
  namen_tage constant int := 60;
  n int;
  ev record;
begin
  if not (is_orga() or current_user in ('postgres','supabase_admin','cron_job')) then
    raise exception 'nicht berechtigt';
  end if;

  -- 0. Zahlen einfrieren, bevor Namen gehen
  n := 0;
  for ev in
    select e.id, e.slug
    from events e
    where e.event_on is not null
      and e.event_on < current_date - coalesce(e.retention_days, 14)
      and exists (select 1 from signups s where s.event = e.slug)
  loop
    insert into planning (event_id, checklist, review)
    values (ev.id, '[]'::jsonb, '{}'::jsonb)
    on conflict (event_id) do nothing;

    update planning p
    set review = coalesce(p.review, '{}'::jsonb) || jsonb_build_object(
      'zahlen', jsonb_build_object(
        'stand',       to_char(now(), 'YYYY-MM-DD'),
        'anmeldungen', (select count(*) from signups s where s.event = ev.slug),
        'erwachsene',  (select coalesce(sum(s.adults),0) from signups s where s.event = ev.slug),
        'kinder',      (select coalesce(sum(s.kids),0)   from signups s where s.event = ev.slug),
        'kategorien',  coalesce((
          select jsonb_object_agg(k.cat, k.menge) from (
            select i->>'cat' as cat,
                   sum(coalesce(nullif(i->>'qty','')::int, 1)) as menge
            from signups s, jsonb_array_elements(s.items) i
            where s.event = ev.slug and i->>'cat' is not null
            group by 1) k), '{}'::jsonb),
        'aufgaben',    coalesce((
          select jsonb_object_agg(a.tid, a.anzahl) from (
            select t.value #>> '{}' as tid, count(*) as anzahl
            from signups s, jsonb_array_elements(s.tasks) t
            where s.event = ev.slug
            group by 1) a), '{}'::jsonb)
      ))
    where p.event_id = ev.id;
    n := n + 1;
  end loop;
  was := 'Veranstaltungen mit gesicherten Zahlen'; anzahl := n; return next;

  delete from signups s
  where not exists (select 1 from events e where e.slug = s.event);
  get diagnostics n = row_count;
  was := 'verwaiste Anmeldungen'; anzahl := n; return next;

  delete from signups s
  using events e
  where e.slug = s.event
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14);
  get diagnostics n = row_count;
  was := 'abgelaufene Anmeldungen'; anzahl := n; return next;

  delete from task_claims c
  using events e
  where e.id = c.event_id
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14);
  get diagnostics n = row_count;
  was := 'abgelaufene Aufgabenzusagen'; anzahl := n; return next;

  update feedback f set from_name = null
  from events e
  where e.id = f.event_id and f.from_name is not null
    and e.event_on is not null and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Rueckmeldungen'; anzahl := n; return next;

  update proposals p set from_name = null
  from events e
  where e.id = p.event_id and p.from_name is not null
    and e.event_on is not null and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Meldungen'; anzahl := n; return next;

  return;
end;
$funktion$;

grant execute on function daten_aufraeumen() to anon;
