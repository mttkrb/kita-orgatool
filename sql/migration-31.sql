-- ============================================================
-- Migration 31: Bausteine je Veranstaltung ein- und ausschalten
--
-- events.blocks und templates.blocks halten, welche Blöcke im Editor nicht gebraucht
-- werden, etwa { "kosten": false, "spenden": false }. Fehlt ein Schlüssel, ist der Block
-- an. Reine Ansicht für das Orgateam: Ausgeschaltet wird nur ein leerer Block, die
-- Anmeldeseite der Eltern liest das Feld nicht. Kein Personenbezug.
-- Eine Veranstaltung aus einer Vorlage übernimmt deren Schalter.
--
-- Rechte wie die übrigen Spalten von events und templates.
-- Erst diese Migration, dann orga.html hochladen. Danach einrichtung/vorlage-erzeugen.sh.
-- Mehrfach ausführbar.
-- ============================================================

alter table events    add column if not exists blocks jsonb not null default '{}';
alter table templates add column if not exists blocks jsonb not null default '{}';

alter table events drop constraint if exists events_blocks_chk;
alter table events add constraint events_blocks_chk
  check (jsonb_typeof(blocks) = 'object' and length(blocks::text) <= 2000);
alter table templates drop constraint if exists templates_blocks_chk;
alter table templates add constraint templates_blocks_chk
  check (jsonb_typeof(blocks) = 'object' and length(blocks::text) <= 2000);

notify pgrst, 'reload schema';
