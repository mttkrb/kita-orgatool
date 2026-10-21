-- ============================================================
-- Migration 27: Keine Rechte für anon auf orga_keys
--
-- Supabase gibt neuen Tabellen von sich aus alle Rechte für anon. Bei orga_keys sind
-- sie nie entzogen worden. Bisher hielt nur RLS ohne Policy das Passwort zurück; eine
-- versehentliche Policy oder ein ausgeschaltetes RLS hätte es für jeden lesbar und
-- änderbar gemacht. Jetzt verweigert schon das Tabellenrecht den Zugriff (42501).
--
-- is_orga() läuft als security definer und liest orga_keys weiter. Das Orga-Passwort
-- ändert man wie bisher im SQL-Editor, der als postgres arbeitet.
--
-- Keine Änderung an den Seiten. Danach einrichtung/vorlage-erzeugen.sh laufen lassen;
-- einrichtung/sql/pruefen.sql meldet sonst "GEFAHR: orga_keys ist für jeden lesbar".
--
-- Mehrfach ausführbar.
-- ============================================================

revoke all on table orga_keys from anon, authenticated;
