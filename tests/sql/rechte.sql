-- Rechteprüfung für Migration 22 (Zahlungseingang), 23 und 25 (Check-in), 24 (Abmelden mit
-- Zahlung, Aufräumen), 27 (orga_keys), dazu die gesperrte Token-Spalte aus schema.sql.
-- Weist auch nach, was verboten ist. Jede Zeile beginnt mit OK oder FEHLER.
\set QUIET on
\pset tuples_only on
\pset format unaligned
-- Testdaten als Superuser
insert into orga_keys (secret, label) values ('geheim-orga', 'Test') on conflict do nothing;
insert into events (id, slug, title, event_on, checkin, payment) values
  ('11111111-1111-1111-1111-111111111111','heute','Arbeitseinsatz',(now() at time zone 'Europe/Berlin')::date,true,'{"adults":3}'),
  ('22222222-2222-2222-2222-222222222222','morgen','Laternenfest',(now() at time zone 'Europe/Berlin')::date+1,true,'{}'),
  ('33333333-3333-3333-3333-333333333333','ohne','Sommerfest',(now() at time zone 'Europe/Berlin')::date,false,'{}');
insert into checkin_codes values ('11111111-1111-1111-1111-111111111111','richtiger-code'),
  ('22222222-2222-2222-2222-222222222222','code-morgen'),('33333333-3333-3333-3333-333333333333','code-ohne');
insert into signups (id, event, name, token) values
  ('aaaaaaaa-0000-0000-0000-000000000001','heute','Familie A','token-a-12345'),
  ('aaaaaaaa-0000-0000-0000-000000000002','morgen','Familie B','token-b-12345'),
  ('aaaaaaaa-0000-0000-0000-000000000003','ohne','Familie C','token-c-12345'),
  ('aaaaaaaa-0000-0000-0000-000000000004','heute','Familie D','token-d-12345');
insert into signups (id, event, name, token, status) values
  ('aaaaaaaa-0000-0000-0000-000000000005','heute','Familie E','token-e-12345','absage');
insert into payments values ('aaaaaaaa-0000-0000-0000-000000000004', 6, now());
update events set visibility = '{"itemNames":false,"taskNames":false}' where slug = 'morgen';
update signups set note = 'privat' where id = 'aaaaaaaa-0000-0000-0000-000000000001';

create function pruef(name text, ok boolean) returns void language plpgsql as $$
begin raise notice '%: %', case when ok then 'OK  ' else 'FEHLER' end, name; end $$;
grant execute on function pruef(text, boolean) to anon;

set role anon;
-- ohne Orga-Passwort
set request.headers = '{}';
select pruef('anon liest payments nicht', (select count(*) from payments) = 0);
select pruef('anon liest checkin_codes nicht', (select count(*) from checkin_codes) = 0);
select pruef('anon liest attendance nicht', (select count(*) from attendance) = 0);
do $$ begin insert into payments values ('aaaaaaaa-0000-0000-0000-000000000001', 1, now());
  perform pruef('anon schreibt payments nicht', false);
  exception when others then perform pruef('anon schreibt payments nicht ('||sqlstate||')', true); end $$;
do $$ begin insert into attendance (signup_id, checked_in_at) values ('aaaaaaaa-0000-0000-0000-000000000003', now());
  perform pruef('anon schreibt attendance nicht', false);
  exception when others then perform pruef('anon schreibt attendance nicht ('||sqlstate||')', true); end $$;
do $$ begin perform 1 from checkin_codes where code = 'richtiger-code';
  perform pruef('anon findet Code nicht per Filter', not found); end $$;
-- Migration 27: orga_keys schon über das Tabellenrecht gesperrt, nicht nur über RLS
do $$ begin perform 1 from orga_keys;
  perform pruef('anon liest orga_keys nicht', false);
  exception when insufficient_privilege then perform pruef('anon liest orga_keys nicht (42501)', true); end $$;
do $$ begin insert into orga_keys (secret, label) values ('eingeschleust', 'X');
  perform pruef('anon schreibt orga_keys nicht', false);
  exception when insufficient_privilege then perform pruef('anon schreibt orga_keys nicht (42501)', true); end $$;
do $$ begin perform token from signups;
  perform pruef('token bleibt gesperrt', false);
  exception when insufficient_privilege then perform pruef('token bleibt gesperrt (42501)', true); end $$;
do $$ begin perform * from checkin_pruefen('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345');
  perform pruef('checkin_pruefen nicht aufrufbar', false);
  exception when insufficient_privilege then perform pruef('checkin_pruefen nicht aufrufbar', true); end $$;
select pruef('events.payment lesbar', (select payment->>'adults' from events where slug='heute') = '3');
select pruef('events.checkin lesbar', (select checkin from events where slug='heute'));
do $$ begin update events set checkin = false where slug = 'heute';
  perform pruef('anon ändert events.checkin nicht', (select checkin from events where slug='heute')); end $$;

-- Anmeldungen lesen (migration-26): ohne Token keine Zeile, mit Token nur die eigene
select pruef('anon liest fremde Anmeldungen nicht', (select count(*) from signups) = 0);
do $$ begin perform 1 from signups where name = 'Familie A';
  perform pruef('anon findet Namen nicht per Filter', not found); end $$;
select pruef('öffentlich: alle Anmeldungen gezählt', (select count(*) from anmeldungen_oeffentlich(array['heute'])) = 3);
select pruef('öffentlich: Name gekürzt', (select count(*) from anmeldungen_oeffentlich(array['heute']) where name = 'Familie A.') = 1);
select pruef('öffentlich: Absage ohne Name und Personen', (select count(*) from anmeldungen_oeffentlich(array['heute'])
  where status = 'absage' and name is null and adults = 0) = 1);
select pruef('öffentlich: kein Name, wenn Namen aus', (select count(*) from anmeldungen_oeffentlich(array['morgen'])
  where name is not null) = 0);
do $$ begin perform note from anmeldungen_oeffentlich(array['heute']);
  perform pruef('öffentlich: keine Anmerkung', false);
  exception when undefined_column then perform pruef('öffentlich: keine Anmerkung', true); end $$;
do $$ begin perform * from intern.kurzname('Anna Beispiel');
  perform pruef('intern.kurzname nicht aufrufbar', false);
  exception when insufficient_privilege then perform pruef('intern.kurzname nicht aufrufbar', true); end $$;
set request.headers = '{"x-entry-token":"token-a-12345"}';
select pruef('Token liest eigene Anmeldung', (select count(*) from signups) = 1
  and (select note from signups where id = 'aaaaaaaa-0000-0000-0000-000000000001') = 'privat');
set request.headers = '{"x-entry-token":"falsch-12345"}';
select pruef('falsches Token liest nichts', (select count(*) from signups) = 0);
set request.headers = '{}';

-- Check-in
select pruef('falsches Token', checkin('aaaaaaaa-0000-0000-0000-000000000001','falsch-12345','richtiger-code')->>'fehler' = 'anmeldung');
select pruef('falscher Code', checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','falsch')->>'fehler' = 'code');
select pruef('Code einer anderen Veranstaltung', checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','code-morgen')->>'fehler' = 'code');
select pruef('falscher Tag', checkin('aaaaaaaa-0000-0000-0000-000000000002','token-b-12345','code-morgen')->>'fehler' = 'tag');
select pruef('Check-in aus', checkin('aaaaaaaa-0000-0000-0000-000000000003','token-c-12345','code-ohne')->>'fehler' = 'aus');
select pruef('Auschecken ohne Einchecken', checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','richtiger-code',true)->>'fehler' = 'nicht_da');
select pruef('Absage checkt nicht ein', checkin('aaaaaaaa-0000-0000-0000-000000000005','token-e-12345','richtiger-code')->>'fehler' = 'absage');
select pruef('Absage hinterlässt keine Anwesenheit', (checkin_status('aaaaaaaa-0000-0000-0000-000000000005','token-e-12345')->>'checked_in_at') is null);
select pruef('Einchecken', (checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','richtiger-code')->>'ok')::boolean);
select pruef('zweimal Einchecken behält erste Zeit',
  (checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','richtiger-code')->>'checked_in_at') =
  (checkin_status('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345')->>'checked_in_at'));
select pruef('Auschecken', (checkin('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345','richtiger-code',true)->>'checked_out_at') is not null);
select pruef('Status mit Token', (checkin_status('aaaaaaaa-0000-0000-0000-000000000001','token-a-12345')->>'checked_out_at') is not null);
select pruef('Status ohne Token', checkin_status('aaaaaaaa-0000-0000-0000-000000000001','falsch-12345')->>'fehler' = 'anmeldung');

-- mit Orga-Passwort
set request.headers = '{"x-orga-key":"geheim-orga"}';
select pruef('Orga liest alle Anmeldungen', (select count(*) from signups) = 5);
select pruef('Orga liest payments', (select count(*) from payments) = 1);
select pruef('Orga liest attendance', (select count(*) from attendance) = 1);
select pruef('Orga liest checkin_codes', (select count(*) from checkin_codes) = 3);
insert into attendance (signup_id, checked_in_at, source, hours) values ('aaaaaaaa-0000-0000-0000-000000000004', now(), 'orga', 2.5);
select pruef('Orga hakt von Hand ab', (select count(*) from attendance) = 2);
update checkin_codes set code = 'neuer-code-123' where event_id = '11111111-1111-1111-1111-111111111111';
select pruef('Orga erneuert Code', (select code from checkin_codes where event_id='11111111-1111-1111-1111-111111111111') = 'neuer-code-123');

-- Eltern löschen eigene Anmeldung: mit Zahlung gesperrt, ohne Zahlung erlaubt
set request.headers = '{"x-entry-token":"token-d-12345"}';
delete from signups where id = 'aaaaaaaa-0000-0000-0000-000000000004';
set request.headers = '{"x-entry-token":"token-c-12345"}';
delete from signups where id = 'aaaaaaaa-0000-0000-0000-000000000003';
reset role;
select pruef('Eltern löschen bezahlte Anmeldung nicht', (select count(*) from signups where id='aaaaaaaa-0000-0000-0000-000000000004') = 1);
select pruef('Zahlung bleibt dabei erhalten', (select count(*) from payments where signup_id='aaaaaaaa-0000-0000-0000-000000000004') = 1);
select pruef('Eltern löschen Anmeldung ohne Zahlung', (select count(*) from signups where id='aaaaaaaa-0000-0000-0000-000000000003') = 0);
set role anon;
set request.headers = '{"x-entry-token":"token-d-12345"}';
update signups set status = 'absage', note = 'krank' where id = 'aaaaaaaa-0000-0000-0000-000000000004';
reset role;
select pruef('Absage über das Formular bleibt möglich', (select status from signups where id='aaaaaaaa-0000-0000-0000-000000000004') = 'absage');
set role anon;
set request.headers = '{"x-orga-key":"geheim-orga"}';
delete from signups where id = 'aaaaaaaa-0000-0000-0000-000000000004';
reset role;
select pruef('Orga löscht bezahlte Anmeldung', (select count(*) from signups where id='aaaaaaaa-0000-0000-0000-000000000004') = 0);
select pruef('Löschen nimmt payments mit', (select count(*) from payments) = 0);
select pruef('Löschen nimmt attendance mit', (select count(*) from attendance where signup_id='aaaaaaaa-0000-0000-0000-000000000004') = 0);

-- Betrag in der Datenbank wie kosten() in common.js
insert into events (id, slug, title, event_on, retention_days, people, fields, payment) values
  ('44444444-4444-4444-4444-444444444444','vorbei','Sankt Martin',current_date - 20, 14,
   '{"adults":{"on":true,"label":"Erwachsene"},"kids":{"on":true,"label":"Kinder"}}',
   '[{"type":"order","label":"Weckmann","price":2.5,"max":10},{"type":"text","label":"Notiz"}]',
   '{"adults":3,"kids":1.5}');
insert into signups (id, event, name, adults, kids, fields, status) values
  ('bbbbbbbb-0000-0000-0000-000000000001','vorbei','Familie E',2,1,'{"Weckmann":"3"}','zusage'),
  ('bbbbbbbb-0000-0000-0000-000000000002','vorbei','Familie F',1,0,'{"Weckmann":"500"}','zusage'),
  ('bbbbbbbb-0000-0000-0000-000000000003','vorbei','Familie G',2,2,'{"Weckmann":"abc"}','absage');
insert into payments values ('bbbbbbbb-0000-0000-0000-000000000001', 15, now());
insert into attendance (signup_id, checked_in_at, checked_out_at) values
  ('bbbbbbbb-0000-0000-0000-000000000001', now() - interval '3 hours', now() - interval '30 minutes');
select pruef('Betrag mit Bestellung', (select intern.anmeldung_betrag(s, e) from signups s, events e
  where s.id='bbbbbbbb-0000-0000-0000-000000000001' and e.slug='vorbei') = 15.00);
select pruef('Bestellmenge auf max gekappt', (select intern.anmeldung_betrag(s, e) from signups s, events e
  where s.id='bbbbbbbb-0000-0000-0000-000000000002' and e.slug='vorbei') = 28.00);
select pruef('Absage kostet nichts', (select intern.anmeldung_betrag(s, e) from signups s, events e
  where s.id='bbbbbbbb-0000-0000-0000-000000000003' and e.slug='vorbei') = 0);

-- Aufräumen hält Geld und Anwesenheit fest, bevor die Namen gehen
select count(*) from daten_aufraeumen();
select pruef('Anmeldungen nach Frist gelöscht', (select count(*) from signups where event='vorbei') = 0);
select pruef('Einnahmen gesichert', (select review->'geld'->>'einnahmen' from planning
  where event_id='44444444-4444-4444-4444-444444444444')::numeric = 43);
select pruef('Bezahlt gesichert', (select review->'geld'->>'bezahlt' from planning
  where event_id='44444444-4444-4444-4444-444444444444')::numeric = 15);
select pruef('Anwesenheit gesichert', (select review->'zahlen'->>'anwesend' from planning
  where event_id='44444444-4444-4444-4444-444444444444')::int = 1);
select pruef('Stunden gesichert', (select review->'zahlen'->>'stunden' from planning
  where event_id='44444444-4444-4444-4444-444444444444')::numeric = 2.5);
select pruef('Zahlen wie bisher gesichert', (select review->'zahlen'->>'anmeldungen' from planning
  where event_id='44444444-4444-4444-4444-444444444444')::int = 3);
