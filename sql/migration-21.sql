-- Nachtrag 21: Eingabegrenzen auf Datenbankebene (Sicherheit).
-- Warum: Der Anon-Key ist oeffentlich. Wer die REST-Schnittstelle direkt
-- anspricht, umgeht die Formulare. Diese Pruefungen gelten deshalb in der
-- Datenbank. Mehrfach ausfuehrbar. Bestehende Zeilen werden NICHT veraendert
-- oder geloescht (NOT VALID: gilt nur fuer neue und geaenderte Zeilen).

-- 1. Bilder: nur echte Bild-Datenadressen, keine Skript-Einschleusung
alter table proposals   drop constraint if exists proposals_image_chk;
alter table proposals   add  constraint proposals_image_chk
  check (image is null or (length(image) <= 1500000
    and image ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$')) not valid;

alter table task_images drop constraint if exists task_images_data_chk;
alter table task_images add  constraint task_images_data_chk
  check (length(data) <= 1500000
    and data ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$') not valid;

-- 2. Textlaengen und Wertebereiche der oeffentlich beschreibbaren Tabellen
alter table signups drop constraint if exists signups_grenzen_chk;
alter table signups add  constraint signups_grenzen_chk check (
  length(name) between 1 and 120 and length(coalesce(note,'')) <= 1000
  and adults between 0 and 50 and kids between 0 and 50
  and length(items::text) <= 20000 and length(tasks::text) <= 5000
  and length(fields::text) <= 5000 and length(materials::text) <= 5000) not valid;

alter table task_claims drop constraint if exists task_claims_grenzen_chk;
alter table task_claims add  constraint task_claims_grenzen_chk check (
  length(name) between 1 and 120 and length(task_id) <= 100) not valid;

alter table proposals drop constraint if exists proposals_grenzen_chk;
alter table proposals add  constraint proposals_grenzen_chk check (
  length(title) between 1 and 200 and length(coalesce(info,'')) <= 2000
  and length(coalesce(from_name,'')) <= 120 and needed between 1 and 99) not valid;

alter table feedback drop constraint if exists feedback_grenzen_chk;
alter table feedback add  constraint feedback_grenzen_chk check (
  length(coalesce(good,'')) <= 2000 and length(coalesce(better,'')) <= 2000
  and length(coalesce(from_name,'')) <= 120
  and (rating is null or rating between 1 and 5)) not valid;
