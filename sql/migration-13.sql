-- Nachtrag 13: Einkaufslisten zu Veranstaltungen.
--
-- Die Liste haengt an der internen Planung, ist also nur fuers Orgateam
-- sichtbar. Vorlagen bringen eine Standardliste mit, die Mengen stammen
-- aus euren alten Excel-Listen.

alter table planning  add column if not exists shopping jsonb not null default '[]';
alter table templates add column if not exists shopping jsonb not null default '[]';


-- Standardliste: Sankt Martin
update templates set shopping = '[{"id": "e1622", "menge": 15, "einheit": "l", "artikel": "Glühwein", "wer": "", "done": false}, {"id": "e55060", "menge": 8, "einheit": "l", "artikel": "Kinderpunsch (2024 waren 4 l zu wenig)", "wer": "", "done": false}, {"id": "e17504", "menge": 130, "einheit": "Stk", "artikel": "Rostbratwürstchen", "wer": "", "done": false}, {"id": "e18524", "menge": 120, "einheit": "Stk", "artikel": "Bockwürstchen Geflügel", "wer": "", "done": false}, {"id": "e86703", "menge": 20, "einheit": "Stk", "artikel": "Würstchen vegetarisch", "wer": "", "done": false}, {"id": "e84579", "menge": 130, "einheit": "Stk", "artikel": "Brötchen", "wer": "", "done": false}, {"id": "e46433", "menge": 2, "einheit": "Stk", "artikel": "Gasflaschen prüfen oder tauschen", "wer": "", "done": false}, {"id": "e53736", "menge": 1, "einheit": "Pk", "artikel": "Servietten", "wer": "", "done": false}, {"id": "e50280", "menge": 1, "einheit": "Pk", "artikel": "Becher", "wer": "", "done": false}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000002'::uuid and (shopping is null or shopping = '[]'::jsonb);

-- Standardliste: Sommerfest
update templates set shopping = '[{"id": "e49880", "menge": 10, "einheit": "Pk", "artikel": "Schweinewürstchen (2024: 15 gekauft, 10 gebraucht)", "wer": "", "done": false}, {"id": "e7172", "menge": 7, "einheit": "Pk", "artikel": "Geflügelwürstchen", "wer": "", "done": false}, {"id": "e86703", "menge": 2, "einheit": "Pk", "artikel": "Würstchen vegetarisch", "wer": "", "done": false}, {"id": "e27082", "menge": 2, "einheit": "Pk", "artikel": "Grillkäse", "wer": "", "done": false}, {"id": "e84579", "menge": 50, "einheit": "Stk", "artikel": "Brötchen", "wer": "", "done": false}, {"id": "e29541", "menge": 10, "einheit": "Stk", "artikel": "Baguette", "wer": "", "done": false}, {"id": "e22424", "menge": 3, "einheit": "Ka", "artikel": "Apfelschorle", "wer": "", "done": false}, {"id": "e30251", "menge": 4, "einheit": "Ka", "artikel": "Wasser", "wer": "", "done": false}, {"id": "e50486", "menge": 3, "einheit": "Ka", "artikel": "Cola", "wer": "", "done": false}, {"id": "e81326", "menge": 2, "einheit": "Ka", "artikel": "Cola Zero", "wer": "", "done": false}, {"id": "e45222", "menge": 1, "einheit": "Ka", "artikel": "Fanta und Sprite", "wer": "", "done": false}, {"id": "e35349", "menge": 7, "einheit": "Ka", "artikel": "Kölsch", "wer": "", "done": false}, {"id": "e77443", "menge": 1, "einheit": "Pk", "artikel": "Ketchup und Senf", "wer": "", "done": false}, {"id": "e53428", "menge": 1, "einheit": "Pk", "artikel": "Grillkohle und Anzünder", "wer": "", "done": false}, {"id": "e7707", "menge": 1, "einheit": "Pk", "artikel": "Mülltüten", "wer": "", "done": false}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000004'::uuid and (shopping is null or shopping = '[]'::jsonb);

-- Standardliste: Weihnachtsfeier
update templates set shopping = '[{"id": "e53736", "menge": 1, "einheit": "Pk", "artikel": "Servietten", "wer": "", "done": false}, {"id": "e48817", "menge": 6, "einheit": "Stk", "artikel": "Schalen fürs Buffet", "wer": "", "done": false}, {"id": "e86052", "menge": 1, "einheit": "Pk", "artikel": "Kaffeepulver (Vorratskammer prüfen)", "wer": "", "done": false}, {"id": "e77254", "menge": 2, "einheit": "l", "artikel": "H-Milch", "wer": "", "done": false}, {"id": "e8031", "menge": 1, "einheit": "Pk", "artikel": "Deko und Kerzen", "wer": "", "done": false}, {"id": "e18285", "menge": 1, "einheit": "Pk", "artikel": "Einweggeschirr, falls Location keins stellt", "wer": "", "done": false}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000003'::uuid and (shopping is null or shopping = '[]'::jsonb);

-- Standardliste: Oma-Opa-Tag
update templates set shopping = '[{"id": "e94169", "menge": 1, "einheit": "Pk", "artikel": "Kaffeepulver", "wer": "", "done": false}, {"id": "e77254", "menge": 2, "einheit": "l", "artikel": "H-Milch", "wer": "", "done": false}, {"id": "e42404", "menge": 1, "einheit": "Pk", "artikel": "Zucker und Sahne", "wer": "", "done": false}, {"id": "e53736", "menge": 1, "einheit": "Pk", "artikel": "Servietten", "wer": "", "done": false}, {"id": "e92483", "menge": 2, "einheit": "Pk", "artikel": "Kuchenplatten und Kuchengabeln", "wer": "", "done": false}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000001'::uuid and (shopping is null or shopping = '[]'::jsonb);

-- Standardliste: Familiensamstag
update templates set shopping = '[{"id": "e65864", "menge": 1, "einheit": "Pk", "artikel": "Putzmittel auffüllen", "wer": "", "done": false}, {"id": "e45476", "menge": 2, "einheit": "Pk", "artikel": "Müllsäcke", "wer": "", "done": false}, {"id": "e87207", "menge": 1, "einheit": "Pk", "artikel": "Obst und Gemüse für die Kinder", "wer": "", "done": false}, {"id": "e325", "menge": 1, "einheit": "Pk", "artikel": "Getränke für die Helfenden", "wer": "", "done": false}]'::jsonb
where id = 'a1000000-0000-4000-8000-000000000005'::uuid and (shopping is null or shopping = '[]'::jsonb);
