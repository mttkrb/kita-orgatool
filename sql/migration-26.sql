-- ============================================================
-- Migration 26: Anmeldungen nicht mehr für alle lesbar
--
-- Bisher durfte anon alle Zeilen von signups lesen. Die Elternseiten zeigten zwar nur
-- "Sarah K.", wer die Schnittstelle direkt abfragte, bekam aber volle Namen,
-- Anmerkungen, Antworten auf Zusatzfragen und Absagegründe. Das passte nicht zum
-- Einwilligungstext.
--
-- Jetzt:
--   - Ganze Zeilen lesen nur das Orgateam (is_orga()) und die Familie selbst
--     (Token aus dem persönlichen Link im Header X-Entry-Token).
--   - Die Elternseiten holen alles andere über anmeldungen_oeffentlich(): Personen,
--     Mitbringsel, Aufgaben und Status, dazu den gekürzten Namen nur, wenn die
--     Veranstaltung Namen bei Mitbringseln oder Aufgaben zeigt. Keine Anmerkung,
--     keine Zusatzfragen, keine Absagegründe.
--
-- Erst diese Migration, dann index.html, fest-anmeldung.html und orga.html hochladen.
-- Dazwischen zeigen die alten Seiten keine Anmeldungen der anderen.
--
-- Mehrfach ausführbar.
-- ============================================================

drop policy if exists "anmelden" on signups;
create policy "anmelden" on signups for select to anon
  using (
    is_orga()
    or token = (current_setting('request.headers', true)::json ->> 'x-entry-token')
  );

-- Gekürzter Name wie shortName() in fest-anmeldung.html: Vorname und erster Buchstabe
-- des Nachnamens.
create or replace function intern.kurzname(p_name text)
returns text language sql immutable set search_path = public as $$
  select case when coalesce(array_length(t, 1), 0) < 2 then t[1]
              else t[1] || ' ' || left(t[array_length(t, 1)], 1) || '.' end
  from (select regexp_split_to_array(btrim(p_name), '\s+') as t) x;
$$;
revoke all on function intern.kurzname(text) from public;

-- Was die Elternseiten von den Anmeldungen brauchen, für höchstens 50 Veranstaltungen
create or replace function anmeldungen_oeffentlich(p_events text[])
returns table (event text, adults int, kids int, items jsonb, tasks jsonb, status text, name text)
language sql stable security definer set search_path = public as $$
  select s.event,
         case when s.status = 'absage' then 0 else s.adults end,
         case when s.status = 'absage' then 0 else s.kids end,
         case when s.status = 'absage' then '[]'::jsonb else s.items end,
         case when s.status = 'absage' then '[]'::jsonb else s.tasks end,
         s.status,
         case when s.status <> 'absage'
               and (coalesce(e.visibility ->> 'itemNames', 'true') <> 'false'
                    or coalesce(e.visibility ->> 'taskNames', 'true') <> 'false')
              then intern.kurzname(s.name) end
  from signups s
  join events e on e.slug = s.event
  where s.event = any (p_events[1:50])
  order by s.created_at;
$$;
revoke all on function anmeldungen_oeffentlich(text[]) from public;
grant execute on function anmeldungen_oeffentlich(text[]) to anon;

notify pgrst, 'reload schema';
