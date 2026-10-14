-- Nachtrag 6: Zusatzfragen beim Oma-Opa-Tag.
-- Fragt das besuchte Kind ab (Pflicht) und die Namen der Besucher (freiwillig).
-- Im Supabase SQL-Editor ausfuehren.
--
-- Hinweis: Antworten auf Zusatzfragen sieht nur das Orgateam.
-- Auf der oeffentlichen Seite erscheinen ausschliesslich Mitbringsel und Aufgaben.

update templates
set fields = '[{"id": "kind", "label": "Welches Kind wird besucht?", "type": "text", "required": true, "options": []}, {"id": "besucher", "label": "Wer kommt? (Namen, freiwillig)", "type": "textarea", "required": false, "options": []}, {"id": "abholen", "label": "Darf der Besuch das Kind danach abholen?", "type": "select", "required": true, "options": ["ja", "nein"]}, {"id": "abholer", "label": "Wer holt ab?", "type": "text", "required": false, "options": []}, {"id": "nicht_da", "label": "Kind ist an dem Tag nicht in der Kita oder wird vorher abgeholt", "type": "checkbox", "required": false, "options": []}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000001'::uuid;

-- Gilt ab dem naechsten Termin; die archivierten Feste bleiben, wie sie waren
update events
set fields = '[{"id": "kind", "label": "Welches Kind wird besucht?", "type": "text", "required": true, "options": []}, {"id": "besucher", "label": "Wer kommt? (Namen, freiwillig)", "type": "textarea", "required": false, "options": []}, {"id": "abholen", "label": "Darf der Besuch das Kind danach abholen?", "type": "select", "required": true, "options": ["ja", "nein"]}, {"id": "abholer", "label": "Wer holt ab?", "type": "text", "required": false, "options": []}, {"id": "nicht_da", "label": "Kind ist an dem Tag nicht in der Kita oder wird vorher abgeholt", "type": "checkbox", "required": false, "options": []}]'::jsonb
where template_id = 'a1000000-0000-4000-8000-000000000001'::uuid and archived = false;
