-- Nachtrag 17: Zahlen festhalten, bevor die Namen verschwinden.
--
-- Problem: der Rueckblick rechnet die Ist-Mengen aus den Anmeldungen.
-- Werden die nach 14 Tagen geloescht, verliert man die Lerngrundlage,
-- wenn der Rueckblick bis dahin nicht ausgefuellt wurde.
--
-- Loesung: das Aufraeumen schreibt vorher eine Zusammenfassung ohne
-- Personenbezug in die Planung. Danach duerfen die Namen gehen.

create or replace function daten_aufraeumen()
returns table(was text, anzahl integer)
language plpgsql
security definer
as $funktion$
declare
  frist_tage constant int := 14;
  namen_tage constant int := 60;
  n int;
  ev record;
begin
  if not (is_orga() or current_user in ('postgres','supabase_admin','cron_job')) then
    raise exception 'nicht berechtigt';
  end if;

  -- 0. Fuer jede faellige Veranstaltung die Zahlen einfrieren
  n := 0;
  for ev in
    select e.id, e.slug
    from events e
    where e.event_on is not null
      and e.event_on < current_date - frist_tage
      and exists (select 1 from signups s where s.event = e.slug)
  loop
    insert into planning (event_id, checklist, review)
    values (ev.id, '[]'::jsonb, '{}'::jsonb)
    on conflict (event_id) do nothing;

    update planning p
    set review = coalesce(p.review, '{}'::jsonb) || jsonb_build_object(
      'zahlen', jsonb_build_object(
        'stand',        to_char(now(), 'YYYY-MM-DD'),
        'anmeldungen',  (select count(*) from signups s where s.event = ev.slug),
        'erwachsene',   (select coalesce(sum(s.adults),0) from signups s where s.event = ev.slug),
        'kinder',       (select coalesce(sum(s.kids),0)   from signups s where s.event = ev.slug),
        'kategorien',   coalesce((
          select jsonb_object_agg(k.cat, k.menge) from (
            select i->>'cat' as cat,
                   sum(coalesce(nullif(i->>'qty','')::int, 1)) as menge
            from signups s, jsonb_array_elements(s.items) i
            where s.event = ev.slug and i->>'cat' is not null
            group by 1) k), '{}'::jsonb),
        'aufgaben',     coalesce((
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

  -- 1. Anmeldungen zu geloeschten Veranstaltungen
  delete from signups s
  where not exists (select 1 from events e where e.slug = s.event);
  get diagnostics n = row_count;
  was := 'verwaiste Anmeldungen'; anzahl := n; return next;

  -- 2. Abgelaufene Anmeldungen
  delete from signups s
  using events e
  where e.slug = s.event
    and e.event_on is not null
    and e.event_on < current_date - frist_tage;
  get diagnostics n = row_count;
  was := 'abgelaufene Anmeldungen'; anzahl := n; return next;

  -- 3. Abgelaufene Aufgabenzusagen
  delete from task_claims c
  using events e
  where e.id = c.event_id
    and e.event_on is not null
    and e.event_on < current_date - frist_tage;
  get diagnostics n = row_count;
  was := 'abgelaufene Aufgabenzusagen'; anzahl := n; return next;

  -- 4. und 5. Namen anonymisieren, Inhalte bleiben
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
