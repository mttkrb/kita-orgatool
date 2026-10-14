-- ============================================================
-- Migration 25: Kein Check-in nach Absage
--
-- checkin() lehnt Anmeldungen mit Status absage ab (fehler: absage). Wer doch kommt,
-- ändert auf der Anmeldeseite seine Antwort auf Zusage und ist damit eingecheckt.
-- Sonst wie in migration-23.sql.
--
-- Mehrfach ausführbar.
-- ============================================================

create or replace function checkin(p_signup uuid, p_token text, p_code text, p_out boolean default false)
returns json language plpgsql security definer volatile set search_path = public as $$
declare
  a record;
  heute date := (now() at time zone 'Europe/Berlin')::date;
  r attendance%rowtype;
begin
  select * into a from checkin_pruefen(p_signup, p_token);
  if not found then
    return json_build_object('ok', false, 'fehler', 'anmeldung');
  end if;
  if not a.aktiv then
    return json_build_object('ok', false, 'fehler', 'aus');
  end if;
  if not exists (select 1 from checkin_codes c
                 where c.event_id = a.event_id and c.code = p_code) then
    return json_build_object('ok', false, 'fehler', 'code');
  end if;
  if a.event_on is null or a.event_on <> heute then
    return json_build_object('ok', false, 'fehler', 'tag');
  end if;
  if not p_out and exists (select 1 from signups s
                           where s.id = a.signup_id and s.status = 'absage') then
    return json_build_object('ok', false, 'fehler', 'absage');
  end if;

  if p_out then
    update attendance set checked_out_at = now()
     where attendance.signup_id = a.signup_id and checked_in_at is not null
    returning * into r;
    if not found then
      return json_build_object('ok', false, 'fehler', 'nicht_da');
    end if;
  else
    insert into attendance (signup_id, checked_in_at, source)
    values (a.signup_id, now(), 'qr')
    on conflict (signup_id) do update
      set checked_in_at = coalesce(attendance.checked_in_at, excluded.checked_in_at)
    returning * into r;
  end if;
  return json_build_object('ok', true, 'checked_in_at', r.checked_in_at,
                           'checked_out_at', r.checked_out_at);
end $$;
revoke all on function checkin(uuid, text, text, boolean) from public;
grant execute on function checkin(uuid, text, text, boolean) to anon;

notify pgrst, 'reload schema';
