-- Nachtrag 5: Aufgaben ohne Zeitangabe, Werkzeug gesammelt statt pro Aufgabe.
-- Im Supabase SQL-Editor ausfuehren. Bestehende Anmeldungen bleiben unveraendert.

-- 1. Vorlage Familiensamstag: Zeitangaben raus, Materialhinweise raus
update templates
set tasks = '[{"id": "toiletten", "label": "Toiletten putzen (inklusive hinter den Schränken)", "when": "", "needed": 3}, {"id": "fenster", "label": "Fenster putzen (Büro, Personalraum, Dachfenster)", "when": "", "needed": 3}, {"id": "snoozel", "label": "Snoozelraum desinfizieren", "when": "", "needed": 2}, {"id": "kueche", "label": "Grundreinigung Küche und Vorratskammer", "when": "", "needed": 2}, {"id": "aussen", "label": "Außengelände: Ablaufgitter, Erdberg, Kunstrasen", "when": "", "needed": 4}, {"id": "streichen", "label": "Streichen und kleine Reparaturen", "when": "", "needed": 3}, {"id": "betreuung", "label": "Auf die Kinder aufpassen", "when": "", "needed": 2}, {"id": "verpflegung", "label": "Rohkost und Obst für die Kinder zubereiten", "when": "", "needed": 2}]'::jsonb,
    categories = '[{"id": "werkzeug", "label": "Werkzeug & Material", "target": 0, "unit": "Sachen", "ideas": ["Putzeimer & Lappen", "Sanitärreiniger", "Fensterleder & Abzieher", "Glasreiniger", "Wischmopp & Bodenreiniger", "Farbe & Rollen", "Pinsel", "Abdeckfolie & Kreppband", "Akkuschrauber", "Leiter", "Schubkarre & Schaufel", "Hochdruckreiniger", "Obst & Gemüse für die Kinder"]}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000005'::uuid;

-- 2. Dieselbe Bereinigung fuer die bereits angelegten Familiensamstage
update events
set tasks = '[{"id": "toiletten", "label": "Toiletten putzen (inklusive hinter den Schränken)", "when": "", "needed": 3}, {"id": "fenster", "label": "Fenster putzen (Büro, Personalraum, Dachfenster)", "when": "", "needed": 3}, {"id": "snoozel", "label": "Snoozelraum desinfizieren", "when": "", "needed": 2}, {"id": "kueche", "label": "Grundreinigung Küche und Vorratskammer", "when": "", "needed": 2}, {"id": "aussen", "label": "Außengelände: Ablaufgitter, Erdberg, Kunstrasen", "when": "", "needed": 4}, {"id": "streichen", "label": "Streichen und kleine Reparaturen", "when": "", "needed": 3}, {"id": "betreuung", "label": "Auf die Kinder aufpassen", "when": "", "needed": 2}, {"id": "verpflegung", "label": "Rohkost und Obst für die Kinder zubereiten", "when": "", "needed": 2}]'::jsonb,
    categories = '[{"id": "werkzeug", "label": "Werkzeug & Material", "target": 0, "unit": "Sachen", "ideas": ["Putzeimer & Lappen", "Sanitärreiniger", "Fensterleder & Abzieher", "Glasreiniger", "Wischmopp & Bodenreiniger", "Farbe & Rollen", "Pinsel", "Abdeckfolie & Kreppband", "Akkuschrauber", "Leiter", "Schubkarre & Schaufel", "Hochdruckreiniger", "Obst & Gemüse für die Kinder"]}]'::jsonb
where template_id = 'a1000000-0000-4000-8000-000000000005'::uuid and archived = false;

-- 3. Sicherheitsnetz: falls irgendwo noch ein Materialhinweis an einer
--    Aufgabe klebt, wird der Schluessel entfernt. Uhrzeiten der anderen
--    Feste bleiben erhalten.
update events
set tasks = (select jsonb_agg(elem - 'material')
             from jsonb_array_elements(events.tasks) as elem)
where tasks::text like '%"material"%';

update templates
set tasks = (select jsonb_agg(elem - 'material')
             from jsonb_array_elements(templates.tasks) as elem)
where tasks::text like '%"material"%';
