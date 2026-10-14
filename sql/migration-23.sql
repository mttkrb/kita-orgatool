-- ============================================================
-- Migration 23: Check-in per QR-Code
--
-- Am Eingang hängt ein Aushang mit QR-Code. Er führt auf die Anmeldeseite mit
-- ?event=…&checkin=CODE. Eltern checken sich dort mit einem Tipp ein und auf
-- Wunsch beim Gehen wieder aus. Wer nicht angemeldet ist, meldet sich dort an
-- und ist damit eingecheckt.
--
--   events.checkin    Check-in für diese Veranstaltung an (Standard aus)
--   checkin_codes     Code vom Aushang je Veranstaltung. Nur fürs Orgateam lesbar,
--                     eigene Tabelle, weil events für alle lesbar ist.
--   attendance        Wer war da, von wann bis wann. Nur fürs Orgateam lesbar.
--                     Wird mit der Anmeldung gelöscht (Kaskade), also auch beim
--                     Aufräumen nach Frist.
--   checkin()         Ein- und Auschecken für Eltern. Prüft Token der Anmeldung,
--                     Code vom Aushang und Datum (nur am Veranstaltungstag).
--   checkin_status()  Eigenen Stand abfragen, mit Token.
--
-- Mehrfach ausführbar.
-- ============================================================

alter table events add column if not exists checkin boolean not null default false;
grant select (checkin), insert (checkin), update (checkin) on events to anon;

create table if not exists checkin_codes (
  event_id uuid primary key references events(id) on delete cascade,
  code text not null default translate(encode(extensions.gen_random_bytes(9), 'base64'), '+/', '-_')
    check (length(code) between 8 and 40)
);
alter table checkin_codes enable row level security;
drop policy if exists "checkin codes nur orga" on checkin_codes;
create policy "checkin codes nur orga" on checkin_codes for all to anon
  using (is_orga()) with check (is_orga());
revoke all on checkin_codes from anon, authenticated;
grant select, insert, update, delete on checkin_codes to anon;

create table if not exists attendance (
  signup_id uuid primary key references signups(id) on delete cascade,
  checked_in_at timestamptz,
  checked_out_at timestamptz,
  hours numeric(4,2) check (hours is null or (hours >= 0 and hours <= 24)),
  source text not null default 'qr' check (source in ('qr','orga'))
);
alter table attendance enable row level security;
drop policy if exists "anwesenheit nur orga" on attendance;
create policy "anwesenheit nur orga" on attendance for all to anon
  using (is_orga()) with check (is_orga());
revoke all on attendance from anon, authenticated;
grant select, insert, update, delete on attendance to anon;

-- Prüft Token und liefert die Anmeldung mit ihrer Veranstaltung.
-- Intern, nicht über die API aufrufbar.
create or replace function checkin_pruefen(p_signup uuid, p_token text)
returns table (signup_id uuid, event_id uuid, event_on date, aktiv boolean)
language sql security definer stable set search_path = public as $$
  select s.id, e.id, e.event_on, e.checkin
  from signups s join events e on e.slug = s.event
  where s.id = p_signup and s.token = p_token and length(coalesce(p_token,'')) between 8 and 64;
$$;
revoke all on function checkin_pruefen(uuid, text) from public, anon, authenticated;

-- Ein- oder Auschecken. Antwort: { ok, fehler?, checked_in_at, checked_out_at }
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

-- Eigener Stand, nur mit Token. Antwort: { ok, checked_in_at, checked_out_at }
create or replace function checkin_status(p_signup uuid, p_token text)
returns json language plpgsql security definer stable set search_path = public as $$
declare
  a record;
  r attendance%rowtype;
begin
  select * into a from checkin_pruefen(p_signup, p_token);
  if not found then
    return json_build_object('ok', false, 'fehler', 'anmeldung');
  end if;
  select * into r from attendance where attendance.signup_id = a.signup_id;
  return json_build_object('ok', true, 'checked_in_at', r.checked_in_at,
                           'checked_out_at', r.checked_out_at);
end $$;
revoke all on function checkin_status(uuid, text) from public;
grant execute on function checkin_status(uuid, text) to anon;

notify pgrst, 'reload schema';
