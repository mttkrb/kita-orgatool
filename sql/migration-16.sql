-- Nachtrag 16: Automatisches Aufraeumen.
--
-- Bisher wurde nie etwas von allein geloescht, obwohl im Einwilligungstext
-- steht, dass die Angaben zwei Wochen nach der Veranstaltung verschwinden.
-- Diese Migration loest das Versprechen ein.
--
-- Geloescht wird:
--   * Anmeldungen und uebernommene Aufgaben: 14 Tage nach dem Termin
--   * Anmeldungen zu geloeschten Veranstaltungen: sofort
-- Anonymisiert wird:
--   * Namen unter Rueckmeldungen und gemeldeten Aufgaben: nach 60 Tagen
-- Erhalten bleiben:
--   * Veranstaltung, Planung, Rueckblick, Fotos, Zahlen ohne Personenbezug

create or replace function daten_aufraeumen()
returns table(was text, anzahl integer)
language plpgsql
security definer
as $funktion$
declare
  frist_tage   constant int := 14;
  namen_tage   constant int := 60;
  n int;
begin
  -- Nur das Orgateam oder der Zeitplaner duerfen das ausloesen
  if not (is_orga() or current_user in ('postgres','supabase_admin','cron_job')) then
    raise exception 'nicht berechtigt';
  end if;

  -- 1. Anmeldungen zu Veranstaltungen, die es nicht mehr gibt
  delete from signups s
  where not exists (select 1 from events e where e.slug = s.event);
  get diagnostics n = row_count;
  was := 'verwaiste Anmeldungen'; anzahl := n; return next;

  -- 2. Anmeldungen, deren Veranstaltung laenger als die Frist vorbei ist
  delete from signups s
  using events e
  where e.slug = s.event
    and e.event_on is not null
    and e.event_on < current_date - frist_tage;
  get diagnostics n = row_count;
  was := 'abgelaufene Anmeldungen'; anzahl := n; return next;

  -- 3. Uebernommene Aufgaben derselben Veranstaltungen
  delete from task_claims c
  using events e
  where e.id = c.event_id
    and e.event_on is not null
    and e.event_on < current_date - frist_tage;
  get diagnostics n = row_count;
  was := 'abgelaufene Aufgabenzusagen'; anzahl := n; return next;

  -- 4. Namen unter Rueckmeldungen anonymisieren, Inhalt bleibt fuer den Rueckblick
  update feedback f set from_name = null
  from events e
  where e.id = f.event_id
    and f.from_name is not null
    and e.event_on is not null
    and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Rueckmeldungen'; anzahl := n; return next;

  -- 5. Dasselbe fuer gemeldete Aufgaben
  update proposals p set from_name = null
  from events e
  where e.id = p.event_id
    and p.from_name is not null
    and e.event_on is not null
    and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Meldungen'; anzahl := n; return next;

  return;
end;
$funktion$;

grant execute on function daten_aufraeumen() to anon;

-- ------------------------------------------------------------
-- Taeglich um 3 Uhr laufen lassen.
-- Setzt die Erweiterung pg_cron voraus: Supabase → Database →
-- Extensions → pg_cron einschalten. Klappt das nicht, ist es
-- nicht schlimm: der Orga-Bereich ruft dieselbe Funktion bei
-- jeder Anmeldung auf.
-- ------------------------------------------------------------
-- create extension if not exists pg_cron;
-- select cron.schedule('kita-aufraeumen', '0 3 * * *', 'select daten_aufraeumen()');
