-- Nachtrag 11: Sprachliche Angleichung. Aus "Fest" wird "Veranstaltung",
-- weil der Familiensamstag keins ist. Betrifft nur gespeicherte Texte.

update events
set retention_note = replace(retention_note, 'nach dem Fest', 'nach der Veranstaltung')
where retention_note like '%nach dem Fest%';

update events
set intro = replace(intro, 'Fest', 'Veranstaltung')
where intro like '%Fest%';
