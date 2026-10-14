-- Nachtrag 10: Gemeldete Aufgaben sind fuer die Melder sichtbar.
--
-- Ziel: wer etwas melden will, sieht vorher, was schon gemeldet wurde,
-- und meldet es nicht doppelt.
--
-- Abgelehnte Meldungen bleiben ausgenommen. Nur bei ihnen steht eine
-- interne Notiz des Orgateams in der Zeile - die soll niemand sonst lesen.
-- Das Orgateam sieht ueber is_orga() weiterhin alles.

drop policy if exists "vorschlaege lesen" on proposals;

create policy "vorschlaege lesen" on proposals for select to anon
  using (is_orga() or status <> 'abgelehnt');
