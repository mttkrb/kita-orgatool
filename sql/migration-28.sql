-- ============================================================
-- Migration 28: Belege zu Einkäufen
--
-- Neue Tabelle receipts: Foto eines Kassenbons zu einer Veranstaltung, mit Laden,
-- Kaufdatum, Betrag und optional dem Posten der Einkaufsliste (shopping.id).
-- Nur das Orgateam liest und schreibt (is_orga()), wie bei payments.
--
-- Aufbewahrung wie die Fotos der Aufgaben: Belege bleiben dauerhaft, damit später noch
-- zu sehen ist, was wo gekauft wurde. Gelöscht wird von Hand oder mit der Veranstaltung
-- (Kaskade). daten_aufraeumen() fasst sie nicht an. Kartennummern und Namen deckt das
-- Orgateam vor dem Foto ab; darauf weist orga.html hin.
--
-- Das Bild wird im Browser verkleinert und als JPEG in der Zeile gespeichert, wie bei
-- task_images. Grenzen für Größe, Format und Textlängen stehen in der Tabelle.
--
-- Erst diese Migration, dann orga.html hochladen. Danach einrichtung/vorlage-erzeugen.sh.
-- Mehrfach ausführbar.
-- ============================================================

create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  created_at timestamptz not null default now(),
  shop text,
  bought_on date,
  amount numeric(8,2),
  item_id text,
  image text not null
);
create index if not exists receipts_event_idx on receipts (event_id);

alter table receipts drop constraint if exists receipts_grenzen_chk;
alter table receipts add constraint receipts_grenzen_chk check (
  length(coalesce(shop, '')) <= 120
  and length(coalesce(item_id, '')) <= 100
  and (amount is null or (amount >= 0 and amount < 100000))
  and length(image) <= 1500000
  and image ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$');

alter table receipts enable row level security;

drop policy if exists "belege nur orga" on receipts;
create policy "belege nur orga" on receipts for all to anon
  using (is_orga()) with check (is_orga());

revoke all on receipts from anon, authenticated;
grant select, insert, update, delete on receipts to anon;

notify pgrst, 'reload schema';
