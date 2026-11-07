-- ============================================================
-- Migration 30: Belege ohne Foto und als PDF
--
-- 1. Ausgaben ohne Beleg: receipts.image darf leer sein, etwa wenn der Bon verloren ist
--    oder bar ohne Quittung gezahlt wurde. Dann ist der Betrag Pflicht, sonst wäre der
--    Eintrag leer.
-- 2. PDF-Belege, etwa Online-Rechnungen: Neben JPEG, PNG und WebP ist
--    data:application/pdf erlaubt. Die Größengrenze bleibt (1,5 MB als data:-Adresse,
--    also gut 1 MB PDF).
--
-- Rechte bleiben wie in migration-28.sql: nur das Orgateam liest und schreibt.
-- Erst diese Migration, dann orga.html hochladen. Danach einrichtung/vorlage-erzeugen.sh.
-- Setzt migration-28.sql voraus. Mehrfach ausführbar.
-- ============================================================

alter table receipts alter column image drop not null;

alter table receipts drop constraint if exists receipts_grenzen_chk;
alter table receipts add constraint receipts_grenzen_chk check (
  length(coalesce(shop, '')) <= 120
  and length(coalesce(item_id, '')) <= 100
  and (amount is null or (amount >= 0 and amount < 100000))
  and (image is null or (length(image) <= 1500000
       and image ~ '^data:(image/(jpeg|png|webp)|application/pdf);base64,[A-Za-z0-9+/=]+$'))
  and (image is not null or amount is not null));

notify pgrst, 'reload schema';
