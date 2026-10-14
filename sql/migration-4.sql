-- Nachtrag 4: Material pro Aufgabe (vor allem fuer Familiensamstage).
-- Im Supabase SQL-Editor ausfuehren. Bestehende Daten bleiben unveraendert.

-- Zusagen, wer welches Material mitbringt
alter table signups add column if not exists materials jsonb not null default '[]';

-- Die neue Spalte muss auch oeffentlich lesbar sein, sonst zeigt
-- die Anmeldeseite die Zusagen nicht an
grant select (id, event, created_at, name, adults, kids, items, tasks, fields, materials, note)
  on signups to anon;

-- Materialhinweise fuer die Standardaufgaben des Familiensamstags
update templates
set tasks = '[{"id": "toiletten", "label": "Toiletten putzen (inklusive hinter den Schränken)", "when": "vormittags", "needed": 3, "material": "Putzeimer, Lappen, Sanitärreiniger"}, {"id": "fenster", "label": "Fenster putzen (Büro, Personalraum, Dachfenster)", "when": "vormittags", "needed": 3, "material": "Fensterleder, Abzieher, Glasreiniger"}, {"id": "snoozel", "label": "Snoozelraum desinfizieren", "when": "vormittags", "needed": 2, "material": "Desinfektionsmittel, Tücher"}, {"id": "kueche", "label": "Grundreinigung Küche und Vorratskammer", "when": "vormittags", "needed": 2, "material": "Wischmopp, Bodenreiniger"}, {"id": "aussen", "label": "Außengelände: Ablaufgitter, Erdberg, Kunstrasen", "when": "ganztags", "needed": 4, "material": "Schubkarre, Schaufel, Handfeger"}, {"id": "streichen", "label": "Streichen und kleine Reparaturen", "when": "ganztags", "needed": 3, "material": "Farbe, Rollen, Pinsel, Abdeckfolie, Kreppband"}, {"id": "betreuung", "label": "Auf die Kinder aufpassen", "when": "abwechselnd", "needed": 2, "material": ""}, {"id": "verpflegung", "label": "Rohkost und Obst für die Kinder zubereiten", "when": "vormittags", "needed": 2, "material": "Obst, Gemüse, Schneidebretter"}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000005'::uuid;

-- Der Familiensamstag zeigt die Aufgaben oben statt der Mitbringsel
update events
set visibility = coalesce(visibility, '{}'::jsonb) || '{"tasksFirst": true}'::jsonb
where template_id = 'a1000000-0000-4000-8000-000000000005'::uuid;
