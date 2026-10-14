-- ============================================================
-- Migration 21: Kosten, Bezahlung und Zahlungseingang
--
-- Neue Spalte payment an Veranstaltungen und Vorlagen:
--   { adults: 3.5, kids: 5, note: "Bitte bis … überweisen …", paypal: "kita-name" }
--   adults/kids  Preis je Person der ersten bzw. zweiten Gruppe in Euro, leer = kostenlos
--   note         Zahlungshinweis für die Eltern (Kontoverbindung, Frist, bar am Tag …)
--   paypal       PayPal.me-Name (daraus wird ein Link mit Betrag) oder eine
--                PayPal-Adresse, an die per Freunde & Familie gesendet wird
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

-- ============================================================
-- Zahlungseingang: Wer hat bezahlt? Nur fürs Orgateam.
--
-- Eigene Tabelle statt Spalte in signups, weil signups für alle lesbar ist und
-- Spaltenrechte auch fürs Orgateam gelten (siehe CLAUDE.md, Sicherheitsmodell).
-- Eine Zeile je bezahlter Anmeldung. Kein Haken = keine Zeile.
--   amount   Betrag, der beim Abhaken fällig war. Ändert die Familie danach
--            ihre Anmeldung, zeigt der Orga-Bereich die Differenz.
--   paid_at  wann abgehakt wurde
-- Wird mit der Anmeldung gelöscht (Kaskade), also auch beim Aufräumen nach Frist.
-- ============================================================

create table if not exists payments (
  signup_id uuid primary key references signups(id) on delete cascade,
  amount numeric(8,2) not null default 0 check (amount >= 0 and amount < 100000),
  paid_at timestamptz not null default now()
);

alter table payments enable row level security;

drop policy if exists "zahlungen nur orga" on payments;
create policy "zahlungen nur orga" on payments for all to anon
  using (is_orga()) with check (is_orga());

revoke all on payments from anon, authenticated;
grant select, insert, update, delete on payments to anon;

notify pgrst, 'reload schema';
