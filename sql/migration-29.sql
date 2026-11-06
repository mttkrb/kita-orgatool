-- ============================================================
-- Migration 29: Zahlung erlassen
--
-- Neue Tabelle fee_waivers: Das Orgateam erlässt einer Anmeldung den Beitrag, etwa
-- Erzieherinnen und Erziehern. Sie stehen weiter in den Anmeldungen, zählen bei den
-- Personen mit und kosten nichts.
--
-- Eigene Tabelle statt Spalte in signups: Eltern dürfen ihre eigene Zeile ändern, und
-- Spaltenrechte gelten auch fürs Orgateam (dieselbe Rolle anon). Eine Spalte könnte
-- also jede Familie selbst setzen. Hier liest und schreibt nur, wer das Orga-Passwort
-- hat; die Anmeldeseite der Eltern kennt den Erlass nicht.
--
-- intern.anmeldung_betrag() rechnet wie kosten() in common.js und gibt für erlassene
-- Anmeldungen 0 zurück. Damit hält daten_aufraeumen() die richtigen Einnahmen fest.
--
-- Erlass und Zahlungseingang sind getrennt: intern.hat_zahlung() sieht nur payments,
-- eine erlassene Anmeldung ohne Zahlung können die Eltern weiter selbst löschen.
--
-- Erst diese Migration, dann common.js und orga.html hochladen.
-- Danach einrichtung/vorlage-erzeugen.sh. Setzt migration-24.sql voraus.
-- Mehrfach ausführbar.
-- ============================================================

create table if not exists fee_waivers (
  signup_id uuid primary key references signups(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table fee_waivers enable row level security;

drop policy if exists "erlass orga" on fee_waivers;
create policy "erlass orga" on fee_waivers for all to anon
  using (is_orga()) with check (is_orga());

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
