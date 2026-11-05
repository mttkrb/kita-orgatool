-- ============================================================
-- Migration 29: Zahlung erlassen
--
-- Neue Tabelle fee_waivers: Das Orgateam erlässt einer Anmeldung den Beitrag, etwa
-- Erzieherinnen und Erziehern. Sie stehen weiter in den Anmeldungen, zählen bei den
-- Personen mit und kosten nichts.
--
-- Eigene Tabelle statt Spalte in signups: Eltern dürfen ihre eigene Zeile ändern, und
-- Spaltenrechte gelten auch fürs Orgateam (dieselbe Rolle anon). Eine Spalte könnte
-- also jede Familie selbst setzen. Hier schreibt nur, wer das Orga-Passwort hat.
-- Die eigene Zeile lesen darf auch, wer das Token aus dem persönlichen Link schickt,
-- damit die Anmeldeseite "du zahlst nichts" zeigen kann.
--
-- intern.anmeldung_betrag() rechnet wie kosten() in common.js und gibt für erlassene
-- Anmeldungen 0 zurück. Damit hält daten_aufraeumen() die richtigen Einnahmen fest.
--
-- Erlass und Zahlungseingang sind getrennt: intern.hat_zahlung() sieht nur payments,
-- eine erlassene Anmeldung ohne Zahlung können die Eltern weiter selbst löschen.
--
-- Erst diese Migration, dann common.js, orga.html und fest-anmeldung.html hochladen.
-- Danach einrichtung/vorlage-erzeugen.sh. Setzt migration-24.sql voraus.
-- Mehrfach ausführbar.
-- ============================================================

create table if not exists fee_waivers (
  signup_id uuid primary key references signups(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table fee_waivers enable row level security;

-- Ob die Anfrage das Token dieser Anmeldung mitschickt. Läuft mit den Rechten des
-- Eigentümers, weil anon die Spalte token nicht lesen darf.
create or replace function intern.eigene_anmeldung(p_signup uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from signups
    where id = p_signup
      and token = (current_setting('request.headers', true)::json ->> 'x-entry-token'));
$$;
revoke all on function intern.eigene_anmeldung(uuid) from public;
grant execute on function intern.eigene_anmeldung(uuid) to anon;

drop policy if exists "erlass orga" on fee_waivers;
create policy "erlass orga" on fee_waivers for all to anon
  using (is_orga()) with check (is_orga());

drop policy if exists "erlass eigener eintrag" on fee_waivers;
create policy "erlass eigener eintrag" on fee_waivers for select to anon
  using (intern.eigene_anmeldung(signup_id));

revoke all on fee_waivers from anon, authenticated;
grant select, insert, delete on fee_waivers to anon;

-- Betrag einer Anmeldung, wie kosten() in common.js. Neu: erlassen kostet nichts.
create or replace function intern.anmeldung_betrag(s signups, e events)
returns numeric language sql stable set search_path = public as $$
  select case when s.status = 'absage'
                or exists (select 1 from fee_waivers w where w.signup_id = s.id)
         then 0::numeric else round(
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

notify pgrst, 'reload schema';
