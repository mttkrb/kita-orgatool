-- ============================================================
-- Migration 21: Kosten und Bezahlung
--
-- Neue Spalte payment an Veranstaltungen und Vorlagen:
--   { adults: 3.5, kids: 5, note: "Bitte bis … überweisen …", paypal: "kita-name" }
--   adults/kids  Preis je Person der ersten bzw. zweiten Gruppe in Euro, leer = kostenlos
--   note         Zahlungshinweis für die Eltern (Kontoverbindung, Frist, bar am Tag …)
--   paypal       Name bei PayPal.me, daraus wird ein Link mit dem Betrag
--
-- Bestellartikel mit Stückpreis (z. B. zusätzlicher Weckmann) sind eine Zusatzfrage
-- vom Typ "order" in events.fields mit { price, max }. Die bestellte Menge steht wie
-- jede Antwort in signups.fields. Dafür braucht es keine neue Spalte.
--
-- Der Betrag einer Anmeldung wird nicht gespeichert, sondern aus Personen und
-- Bestellungen berechnet. Es kommt kein personenbezogenes Feld dazu.
--
-- Ausgaben des Orgateams stehen als Feld preis in planning.shopping, das nur das
-- Orgateam lesen kann. Auch dafür braucht es keine neue Spalte.
--
-- Mehrfach ausführbar.
-- ============================================================

alter table events    add column if not exists payment jsonb not null default '{}';
alter table templates add column if not exists payment jsonb not null default '{}';

-- Nur das Orgateam schreibt Veranstaltungen und Vorlagen. Eine Größengrenze schadet
-- trotzdem nicht: ein Zahlungshinweis ist ein paar Zeilen, kein Roman.
alter table events drop constraint if exists events_payment_groesse;
alter table events add constraint events_payment_groesse
  check (jsonb_typeof(payment) = 'object' and octet_length(payment::text) <= 4000);

alter table templates drop constraint if exists templates_payment_groesse;
alter table templates add constraint templates_payment_groesse
  check (jsonb_typeof(payment) = 'object' and octet_length(payment::text) <= 4000);

-- Spaltenrechte zusätzlich vergeben. Hat anon schon Tabellenrechte, ändert das nichts;
-- sind die Rechte spaltenweise vergeben, wäre die neue Spalte sonst unsichtbar.
-- Wer schreiben darf, entscheiden weiterhin die Policies (is_orga()).
grant select (payment) on events to anon;
grant insert (payment), update (payment) on events to anon;
grant select (payment), insert (payment), update (payment) on templates to anon;

-- PostgREST soll die neuen Spalten sofort kennen
notify pgrst, 'reload schema';
