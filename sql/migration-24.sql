-- ============================================================
-- Migration 24: Abmelden mit Zahlung, Geld und Anwesenheit beim Aufräumen
--
-- 1. Hat das Orgateam bei einer Anmeldung "bezahlt" abgehakt, können Eltern sie über
--    den persönlichen Link nicht mehr löschen. Sonst verschwände mit der Anmeldung
--    auch der Zahlungseingang (Kaskade), und niemand sähe, dass Geld zurückgeht.
--    Die Eltern wenden sich dann ans Orgateam; das Orgateam löscht weiterhin selbst.
--    Absagen über das Formular (Status absage) bleiben möglich.
--
-- 2. daten_aufraeumen() hält vor dem Löschen zusätzlich fest:
--      review.geld    einnahmen (Soll aus Personen und Bestellungen), bezahlt, stand
--      review.zahlen  anwesend (Familien mit Check-in) und stunden
--    So überleben Einnahmen und Anwesenheit die Namen, auch wenn niemand den
--    Rückblick gespeichert hat. Grundlage ist der Stand aus migration-19.sql.
--
-- Hilfsfunktionen liegen im Schema intern. Das ist über die Schnittstelle nicht
-- erreichbar; so verrät niemand per Aufruf, wer schon bezahlt hat.
--
-- Setzt migration-22.sql (payments) und migration-23.sql (attendance) voraus.
-- Mehrfach ausführbar.
-- ============================================================

create schema if not exists intern;
revoke all on schema intern from public;
grant usage on schema intern to anon;

-- Ob für eine Anmeldung ein Zahlungseingang eingetragen ist. Läuft mit den Rechten
-- des Eigentümers, weil anon payments nicht lesen darf.
create or replace function intern.hat_zahlung(p_signup uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from payments where signup_id = p_signup);
$$;
revoke all on function intern.hat_zahlung(uuid) from public;
grant execute on function intern.hat_zahlung(uuid) to anon;

drop policy if exists "eigene loeschen" on signups;
create policy "eigene loeschen" on signups for delete to anon
  using (
    is_orga()
    or (token = (current_setting('request.headers', true)::json ->> 'x-entry-token')
        and not intern.hat_zahlung(id))
  );

-- Betrag einer Anmeldung, wie kosten() in common.js: Personen beider Gruppen plus
-- Bestellungen (Zusatzfragen vom Typ order, Menge auf max gekappt). Absagen kosten nichts.
create or replace function intern.anmeldung_betrag(s signups, e events)
returns numeric language sql stable set search_path = public as $$
  select case when s.status = 'absage' then 0::numeric else round(
      case when case when e.people ? 'adults' then coalesce((e.people->'adults'->>'on')::boolean, false)
                     else e.ask_people end
           then s.adults * greatest(0, coalesce(nullif(e.payment->>'adults', '')::numeric, 0)) else 0 end
    + case when case when e.people ? 'kids' then coalesce((e.people->'kids'->>'on')::boolean, false)
                     else e.ask_people end
           then s.kids * greatest(0, coalesce(nullif(e.payment->>'kids', '')::numeric, 0)) else 0 end
    + coalesce((
        select sum(
          least(coalesce(nullif(nullif(f->>'max', ''), '0')::numeric, 99),
                greatest(0, floor(case when (s.fields->>(f->>'label')) ~ '^\s*[0-9]+([.][0-9]+)?\s*$'
                                       then (s.fields->>(f->>'label'))::numeric else 0 end)))
          * greatest(0, coalesce(nullif(f->>'price', '')::numeric, 0)))
        from jsonb_array_elements(coalesce(e.fields, '[]'::jsonb)) f
        where f->>'type' = 'order'), 0), 2) end;
$$;
revoke all on function intern.anmeldung_betrag(signups, events) from public;

create or replace function daten_aufraeumen()
returns table(was text, anzahl integer)
language plpgsql
security definer
set search_path = public, extensions
as $funktion$
declare
  namen_tage constant int := 60;
  n int;
  ev record;
begin
  if not (is_orga() or current_user in ('postgres','supabase_admin','cron_job')) then
    raise exception 'nicht berechtigt';
  end if;

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
            group by 1) a), '{}'::jsonb),
        'anwesend',    (select count(*) from attendance a join signups s on s.id = a.signup_id
                         where s.event = ev.slug),
        'stunden',     (select round(coalesce(sum(coalesce(a.hours,
                           extract(epoch from (a.checked_out_at - a.checked_in_at)) / 3600)), 0)::numeric, 2)
                         from attendance a join signups s on s.id = a.signup_id where s.event = ev.slug)
      ),
      'geld', coalesce(p.review->'geld', '{}'::jsonb) || jsonb_build_object(
        'einnahmen',   (select coalesce(sum(intern.anmeldung_betrag(s, e)), 0)
                         from signups s join events e on e.slug = s.event where s.event = ev.slug),
        'bezahlt',     (select coalesce(sum(z.amount), 0) from payments z join signups s on s.id = z.signup_id
                         where s.event = ev.slug),
        'stand',       to_char(now(), 'YYYY-MM-DD')
      ))
    where p.event_id = ev.id;
  end loop;

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

  -- NEU: archivieren, sobald die Frist abgelaufen ist und keine Namen mehr da sind
  update events e
  set archived = true
  where e.archived = false
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14)
    and not exists (select 1 from signups s where s.event = e.slug);
  get diagnostics n = row_count;
  was := 'archivierte Veranstaltungen'; anzahl := n; return next;

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

notify pgrst, 'reload schema';
