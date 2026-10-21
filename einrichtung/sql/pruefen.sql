-- =====================================================================
--  Kita-Orgatool – Neuinstallation prüfen
--
--  Nach neuinstallation.sql im SQL-Editor ausführen. Jede Zeile beginnt mit
--  OK, FEHLT, ZUVIEL oder GEFAHR. Bei GEFAHR die Seiten nicht freigeben.
--
--  Vergleicht Tabellen, Spalten, Policies, Funktionen und Rechte mit dem
--  Projekt, aus dem die Vorlage stammt (nur Namen und Prüfsummen).
--  Erzeugt am 2026-10-19 11:24 mit einrichtung/vorlage-erzeugen.sh. Nicht von Hand ändern.
-- =====================================================================

with soll(zeile) as (values
  ('constraint|attendance|attendance_hours_check|a8f18308e334a207ec837fd32f9b933a'),
  ('constraint|attendance|attendance_pkey|bb2d9f516ed16aa3cde9bf4ac58421b2'),
  ('constraint|attendance|attendance_signup_id_fkey|8c31f1baa0dbe7e688211e79bf5c5b0d'),
  ('constraint|attendance|attendance_source_check|3d79a8e7a43d903f32a6c51124f7fadf'),
  ('constraint|checkin_codes|checkin_codes_code_check|07a751f536d586467e8a4278af0e4a1e'),
  ('constraint|checkin_codes|checkin_codes_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|checkin_codes|checkin_codes_pkey|cdfe71aaf47969fdd98aa3fde969c2ae'),
  ('constraint|events|events_payment_groesse|037179f4cd19a455bbdba5e147bc81b2'),
  ('constraint|events|events_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|events|events_slug_key|d94b85ea8a98ec24f91c9ebedac31e6a'),
  ('constraint|events|events_template_id_fkey|4b642e39fe7ff8609d5a2d7f2c4633bb'),
  ('constraint|feedback|feedback_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|feedback|feedback_grenzen_chk|c44417ae416b80a963f8069ebfba15ec'),
  ('constraint|feedback|feedback_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|orga_keys|orga_keys_pkey|141268dbb7754d3e862d23ec2f0927fe'),
  ('constraint|payments|payments_amount_check|ed3e44b788fad947da678f64ddbb5e92'),
  ('constraint|payments|payments_pkey|bb2d9f516ed16aa3cde9bf4ac58421b2'),
  ('constraint|payments|payments_signup_id_fkey|8c31f1baa0dbe7e688211e79bf5c5b0d'),
  ('constraint|planning|planning_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|planning|planning_pkey|cdfe71aaf47969fdd98aa3fde969c2ae'),
  ('constraint|proposals|proposals_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|proposals|proposals_grenzen_chk|4cb80ce44c747f38b65ffa3f834ca589'),
  ('constraint|proposals|proposals_image_chk|331c0e05415b7914d4b53369c0e3579e'),
  ('constraint|proposals|proposals_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|signups|signups_grenzen_chk|6a42ac02db276d802f369dc04771522e'),
  ('constraint|signups|signups_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|task_claims|task_claims_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|task_claims|task_claims_grenzen_chk|45d67103709a62f863dd58b234402ac2'),
  ('constraint|task_claims|task_claims_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|task_images|task_images_data_chk|44f3bbfd995a19ebf956bd0c2f992f60'),
  ('constraint|task_images|task_images_event_id_fkey|9d87ad85a21f29ae5578906cd0536a94'),
  ('constraint|task_images|task_images_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('constraint|templates|templates_payment_groesse|037179f4cd19a455bbdba5e147bc81b2'),
  ('constraint|templates|templates_pkey|795f8aa19bf8004d0e6d2e4a0dc930e3'),
  ('funktionsrecht|anmeldungen_oeffentlich(text[])|anon|EXECUTE'),
  ('funktionsrecht|checkin(uuid,text,text,boolean)|anon|EXECUTE'),
  ('funktionsrecht|checkin_status(uuid,text)|anon|EXECUTE'),
  ('funktionsrecht|daten_aufraeumen()|PUBLIC|EXECUTE'),
  ('funktionsrecht|daten_aufraeumen()|anon|EXECUTE'),
  ('funktionsrecht|intern.hat_zahlung(uuid)|anon|EXECUTE'),
  ('funktionsrecht|is_orga()|PUBLIC|EXECUTE'),
  ('funktionsrecht|is_orga()|anon|EXECUTE'),
  ('funktionsrecht|rls_auto_enable()|PUBLIC|EXECUTE'),
  ('funktion|anmeldungen_oeffentlich(text[])|17b13444ddb394a6726f7d107fa7d749'),
  ('funktion|checkin(uuid,text,text,boolean)|4a35deef2de50e27c80d8b6e1a7653da'),
  ('funktion|checkin_pruefen(uuid,text)|98716b4915514b6f36e416718da013b7'),
  ('funktion|checkin_status(uuid,text)|54b2536325e3c637b4842f1bc294c678'),
  ('funktion|daten_aufraeumen()|2a94e6b41fb8d7c1061814f5b163e3f7'),
  ('funktion|intern.anmeldung_betrag(signups,events)|7e3bfa522e81dca8b48e5de8f039c1c3'),
  ('funktion|intern.hat_zahlung(uuid)|f84d29bfc8d31d5389ff3c7b487b1b8c'),
  ('funktion|intern.kurzname(text)|82cbd41994394d7db0241add4a07946f'),
  ('funktion|is_orga()|167ecb2e5952832adff7c58732c823f2'),
  ('funktion|rls_auto_enable()|6998ea6b4c2480f5d2e34b5dcf3f8d36'),
  ('index|attendance|attendance_pkey|a85b45591315d36ba226af82f169f23a'),
  ('index|checkin_codes|checkin_codes_pkey|09cc31d5f240530f5277d913155feddc'),
  ('index|events|events_pkey|246140ed37b0df04b471c7497b018d6f'),
  ('index|events|events_slug_key|bb55e2a18ce7791402c382d3dfeceb50'),
  ('index|feedback|feedback_event_idx|2665680be22810f8efc3e05f57a0c2b1'),
  ('index|feedback|feedback_pkey|d57fff3920fa0b3c6b6807bed50f1c6c'),
  ('index|orga_keys|orga_keys_pkey|7cef06b154e1308cd169cf67edecf4fd'),
  ('index|payments|payments_pkey|021a7397a1abfa5350400ea005394881'),
  ('index|planning|planning_pkey|1f53ac1a1046ca99f6ac356ec23ba54e'),
  ('index|proposals|proposals_event_idx|bbd233bef7783a7f6440f424642182fc'),
  ('index|proposals|proposals_pkey|a56ebeee24096136d42032e2bdb767b1'),
  ('index|signups|signups_pkey|7cdc6cb4a46fece1780ee6bf28bf6808'),
  ('index|task_claims|task_claims_event_idx|ddcb702c21a8ef6381e7230a38f15dde'),
  ('index|task_claims|task_claims_pkey|fc1133fc1d759984f0523ce17ed4195d'),
  ('index|task_images|task_images_event_idx|cc6f2a740ff2d74a1bedaf33e55d0f89'),
  ('index|task_images|task_images_pkey|4b35bffd76121339786c89a8433a9155'),
  ('index|templates|templates_pkey|d0eadfe8b2910f72e6e7d4c0e7d39121'),
  ('policy|attendance|anwesenheit nur orga|PERMISSIVE|ALL|anon|c8a0f3bb715a4f0bedea7100099941b2|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|checkin_codes|checkin codes nur orga|PERMISSIVE|ALL|anon|c8a0f3bb715a4f0bedea7100099941b2|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|events|events aendern|PERMISSIVE|UPDATE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|events|events anlegen|PERMISSIVE|INSERT|anon|-|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|events|events lesen|PERMISSIVE|SELECT|anon|b326b5062b2f0e69046810717534cb09|-'),
  ('policy|events|events loeschen|PERMISSIVE|DELETE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|feedback|feedback geben|PERMISSIVE|INSERT|anon|-|b326b5062b2f0e69046810717534cb09'),
  ('policy|feedback|feedback lesen|PERMISSIVE|SELECT|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|feedback|feedback loeschen|PERMISSIVE|DELETE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|payments|zahlungen nur orga|PERMISSIVE|ALL|anon|c8a0f3bb715a4f0bedea7100099941b2|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|planning|planung|PERMISSIVE|ALL|anon|c8a0f3bb715a4f0bedea7100099941b2|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|proposals|vorschlaege aendern|PERMISSIVE|UPDATE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|proposals|vorschlaege lesen|PERMISSIVE|SELECT|anon|432b985ab15c40361ddbc6de9973919a|-'),
  ('policy|proposals|vorschlaege loeschen|PERMISSIVE|DELETE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|proposals|vorschlag einreichen|PERMISSIVE|INSERT|anon|-|b326b5062b2f0e69046810717534cb09'),
  ('policy|signups|anmelden|PERMISSIVE|SELECT|anon|3d4bb3deed7a6003b3cfcfb44e1ad09d|-'),
  ('policy|signups|anmeldung neu|PERMISSIVE|INSERT|anon|-|b326b5062b2f0e69046810717534cb09'),
  ('policy|signups|eigene aendern|PERMISSIVE|UPDATE|anon|091e7a5790dcbacc9673464ef3e68833|-'),
  ('policy|signups|eigene loeschen|PERMISSIVE|DELETE|anon|d7951426dce0eb11b4fc4fd7dbb108be|-'),
  ('policy|task_claims|aufgaben aendern|PERMISSIVE|UPDATE|anon|b326b5062b2f0e69046810717534cb09|-'),
  ('policy|task_claims|aufgaben belegen|PERMISSIVE|INSERT|anon|-|b326b5062b2f0e69046810717534cb09'),
  ('policy|task_claims|aufgaben freigeben|PERMISSIVE|DELETE|anon|b326b5062b2f0e69046810717534cb09|-'),
  ('policy|task_claims|aufgaben lesen|PERMISSIVE|SELECT|anon|b326b5062b2f0e69046810717534cb09|-'),
  ('policy|task_images|bilder anlegen|PERMISSIVE|INSERT|anon|-|c8a0f3bb715a4f0bedea7100099941b2'),
  ('policy|task_images|bilder lesen|PERMISSIVE|SELECT|anon|b326b5062b2f0e69046810717534cb09|-'),
  ('policy|task_images|bilder loeschen|PERMISSIVE|DELETE|anon|c8a0f3bb715a4f0bedea7100099941b2|-'),
  ('policy|templates|vorlagen|PERMISSIVE|ALL|anon|c8a0f3bb715a4f0bedea7100099941b2|c8a0f3bb715a4f0bedea7100099941b2'),
  ('recht|attendance|anon|DELETE'),
  ('recht|attendance|anon|INSERT'),
  ('recht|attendance|anon|SELECT'),
  ('recht|attendance|anon|UPDATE'),
  ('recht|attendance|service_role|MAINTAIN'),
  ('recht|attendance|service_role|REFERENCES'),
  ('recht|attendance|service_role|TRIGGER'),
  ('recht|attendance|service_role|TRUNCATE'),
  ('recht|checkin_codes|anon|DELETE'),
  ('recht|checkin_codes|anon|INSERT'),
  ('recht|checkin_codes|anon|SELECT'),
  ('recht|checkin_codes|anon|UPDATE'),
  ('recht|checkin_codes|service_role|MAINTAIN'),
  ('recht|checkin_codes|service_role|REFERENCES'),
  ('recht|checkin_codes|service_role|TRIGGER'),
  ('recht|checkin_codes|service_role|TRUNCATE'),
  ('recht|events|anon|DELETE'),
  ('recht|events|anon|INSERT'),
  ('recht|events|anon|MAINTAIN'),
  ('recht|events|anon|REFERENCES'),
  ('recht|events|anon|SELECT'),
  ('recht|events|anon|TRIGGER'),
  ('recht|events|anon|TRUNCATE'),
  ('recht|events|anon|UPDATE'),
  ('recht|events|authenticated|MAINTAIN'),
  ('recht|events|authenticated|REFERENCES'),
  ('recht|events|authenticated|TRIGGER'),
  ('recht|events|authenticated|TRUNCATE'),
  ('recht|events|service_role|MAINTAIN'),
  ('recht|events|service_role|REFERENCES'),
  ('recht|events|service_role|TRIGGER'),
  ('recht|events|service_role|TRUNCATE'),
  ('recht|feedback|anon|DELETE'),
  ('recht|feedback|anon|INSERT'),
  ('recht|feedback|anon|MAINTAIN'),
  ('recht|feedback|anon|REFERENCES'),
  ('recht|feedback|anon|SELECT'),
  ('recht|feedback|anon|TRIGGER'),
  ('recht|feedback|anon|TRUNCATE'),
  ('recht|feedback|anon|UPDATE'),
  ('recht|feedback|authenticated|MAINTAIN'),
  ('recht|feedback|authenticated|REFERENCES'),
  ('recht|feedback|authenticated|TRIGGER'),
  ('recht|feedback|authenticated|TRUNCATE'),
  ('recht|feedback|service_role|MAINTAIN'),
  ('recht|feedback|service_role|REFERENCES'),
  ('recht|feedback|service_role|TRIGGER'),
  ('recht|feedback|service_role|TRUNCATE'),
  ('recht|orga_keys|anon|DELETE'),
  ('recht|orga_keys|anon|INSERT'),
  ('recht|orga_keys|anon|MAINTAIN'),
  ('recht|orga_keys|anon|REFERENCES'),
  ('recht|orga_keys|anon|SELECT'),
  ('recht|orga_keys|anon|TRIGGER'),
  ('recht|orga_keys|anon|TRUNCATE'),
  ('recht|orga_keys|anon|UPDATE'),
  ('recht|orga_keys|authenticated|MAINTAIN'),
  ('recht|orga_keys|authenticated|REFERENCES'),
  ('recht|orga_keys|authenticated|TRIGGER'),
  ('recht|orga_keys|authenticated|TRUNCATE'),
  ('recht|orga_keys|service_role|MAINTAIN'),
  ('recht|orga_keys|service_role|REFERENCES'),
  ('recht|orga_keys|service_role|TRIGGER'),
  ('recht|orga_keys|service_role|TRUNCATE'),
  ('recht|payments|anon|DELETE'),
  ('recht|payments|anon|INSERT'),
  ('recht|payments|anon|SELECT'),
  ('recht|payments|anon|UPDATE'),
  ('recht|payments|service_role|MAINTAIN'),
  ('recht|payments|service_role|REFERENCES'),
  ('recht|payments|service_role|TRIGGER'),
  ('recht|payments|service_role|TRUNCATE'),
  ('recht|planning|anon|DELETE'),
  ('recht|planning|anon|INSERT'),
  ('recht|planning|anon|MAINTAIN'),
  ('recht|planning|anon|REFERENCES'),
  ('recht|planning|anon|SELECT'),
  ('recht|planning|anon|TRIGGER'),
  ('recht|planning|anon|TRUNCATE'),
  ('recht|planning|anon|UPDATE'),
  ('recht|planning|authenticated|MAINTAIN'),
  ('recht|planning|authenticated|REFERENCES'),
  ('recht|planning|authenticated|TRIGGER'),
  ('recht|planning|authenticated|TRUNCATE'),
  ('recht|planning|service_role|MAINTAIN'),
  ('recht|planning|service_role|REFERENCES'),
  ('recht|planning|service_role|TRIGGER'),
  ('recht|planning|service_role|TRUNCATE'),
  ('recht|proposals|anon|DELETE'),
  ('recht|proposals|anon|INSERT'),
  ('recht|proposals|anon|MAINTAIN'),
  ('recht|proposals|anon|REFERENCES'),
  ('recht|proposals|anon|SELECT'),
  ('recht|proposals|anon|TRIGGER'),
  ('recht|proposals|anon|TRUNCATE'),
  ('recht|proposals|anon|UPDATE'),
  ('recht|proposals|authenticated|MAINTAIN'),
  ('recht|proposals|authenticated|REFERENCES'),
  ('recht|proposals|authenticated|TRIGGER'),
  ('recht|proposals|authenticated|TRUNCATE'),
  ('recht|proposals|service_role|MAINTAIN'),
  ('recht|proposals|service_role|REFERENCES'),
  ('recht|proposals|service_role|TRIGGER'),
  ('recht|proposals|service_role|TRUNCATE'),
  ('recht|signups|anon|DELETE'),
  ('recht|signups|anon|INSERT'),
  ('recht|signups|anon|MAINTAIN'),
  ('recht|signups|anon|REFERENCES'),
  ('recht|signups|anon|TRIGGER'),
  ('recht|signups|anon|TRUNCATE'),
  ('recht|signups|anon|UPDATE'),
  ('recht|signups|authenticated|MAINTAIN'),
  ('recht|signups|authenticated|REFERENCES'),
  ('recht|signups|authenticated|TRIGGER'),
  ('recht|signups|authenticated|TRUNCATE'),
  ('recht|signups|service_role|MAINTAIN'),
  ('recht|signups|service_role|REFERENCES'),
  ('recht|signups|service_role|TRIGGER'),
  ('recht|signups|service_role|TRUNCATE'),
  ('recht|task_claims|anon|DELETE'),
  ('recht|task_claims|anon|INSERT'),
  ('recht|task_claims|anon|MAINTAIN'),
  ('recht|task_claims|anon|REFERENCES'),
  ('recht|task_claims|anon|SELECT'),
  ('recht|task_claims|anon|TRIGGER'),
  ('recht|task_claims|anon|TRUNCATE'),
  ('recht|task_claims|anon|UPDATE'),
  ('recht|task_claims|authenticated|MAINTAIN'),
  ('recht|task_claims|authenticated|REFERENCES'),
  ('recht|task_claims|authenticated|TRIGGER'),
  ('recht|task_claims|authenticated|TRUNCATE'),
  ('recht|task_claims|service_role|MAINTAIN'),
  ('recht|task_claims|service_role|REFERENCES'),
  ('recht|task_claims|service_role|TRIGGER'),
  ('recht|task_claims|service_role|TRUNCATE'),
  ('recht|task_images|anon|DELETE'),
  ('recht|task_images|anon|INSERT'),
  ('recht|task_images|anon|MAINTAIN'),
  ('recht|task_images|anon|REFERENCES'),
  ('recht|task_images|anon|SELECT'),
  ('recht|task_images|anon|TRIGGER'),
  ('recht|task_images|anon|TRUNCATE'),
  ('recht|task_images|anon|UPDATE'),
  ('recht|task_images|authenticated|MAINTAIN'),
  ('recht|task_images|authenticated|REFERENCES'),
  ('recht|task_images|authenticated|TRIGGER'),
  ('recht|task_images|authenticated|TRUNCATE'),
  ('recht|task_images|service_role|MAINTAIN'),
  ('recht|task_images|service_role|REFERENCES'),
  ('recht|task_images|service_role|TRIGGER'),
  ('recht|task_images|service_role|TRUNCATE'),
  ('recht|templates|anon|DELETE'),
  ('recht|templates|anon|INSERT'),
  ('recht|templates|anon|MAINTAIN'),
  ('recht|templates|anon|REFERENCES'),
  ('recht|templates|anon|SELECT'),
  ('recht|templates|anon|TRIGGER'),
  ('recht|templates|anon|TRUNCATE'),
  ('recht|templates|anon|UPDATE'),
  ('recht|templates|authenticated|MAINTAIN'),
  ('recht|templates|authenticated|REFERENCES'),
  ('recht|templates|authenticated|TRIGGER'),
  ('recht|templates|authenticated|TRUNCATE'),
  ('recht|templates|service_role|MAINTAIN'),
  ('recht|templates|service_role|REFERENCES'),
  ('recht|templates|service_role|TRIGGER'),
  ('recht|templates|service_role|TRUNCATE'),
  ('schemarecht|intern|anon|USAGE'),
  ('spaltenrecht|events.checkin|anon|INSERT'),
  ('spaltenrecht|events.checkin|anon|SELECT'),
  ('spaltenrecht|events.checkin|anon|UPDATE'),
  ('spaltenrecht|events.payment|anon|INSERT'),
  ('spaltenrecht|events.payment|anon|SELECT'),
  ('spaltenrecht|events.payment|anon|UPDATE'),
  ('spaltenrecht|signups.adults|anon|SELECT'),
  ('spaltenrecht|signups.created_at|anon|SELECT'),
  ('spaltenrecht|signups.event|anon|SELECT'),
  ('spaltenrecht|signups.fields|anon|SELECT'),
  ('spaltenrecht|signups.id|anon|SELECT'),
  ('spaltenrecht|signups.items|anon|SELECT'),
  ('spaltenrecht|signups.kids|anon|SELECT'),
  ('spaltenrecht|signups.materials|anon|SELECT'),
  ('spaltenrecht|signups.name|anon|SELECT'),
  ('spaltenrecht|signups.note|anon|SELECT'),
  ('spaltenrecht|signups.status|anon|SELECT'),
  ('spaltenrecht|signups.tasks|anon|SELECT'),
  ('spaltenrecht|templates.payment|anon|INSERT'),
  ('spaltenrecht|templates.payment|anon|SELECT'),
  ('spaltenrecht|templates.payment|anon|UPDATE'),
  ('spalte|attendance.checked_in_at|timestamp with time zone|notnull=false|-'),
  ('spalte|attendance.checked_out_at|timestamp with time zone|notnull=false|-'),
  ('spalte|attendance.hours|numeric(4,2)|notnull=false|-'),
  ('spalte|attendance.signup_id|uuid|notnull=true|-'),
  ('spalte|attendance.source|text|notnull=true|29ef562089583d89dd207ed4e51b4932'),
  ('spalte|checkin_codes.code|text|notnull=true|fffdb2fbd2909eff10760eafde03fb58'),
  ('spalte|checkin_codes.event_id|uuid|notnull=true|-'),
  ('spalte|events.archived|boolean|notnull=true|68934a3e9455fa72420237eb05902327'),
  ('spalte|events.ask_people|boolean|notnull=true|b326b5062b2f0e69046810717534cb09'),
  ('spalte|events.categories|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|events.checkin|boolean|notnull=true|68934a3e9455fa72420237eb05902327'),
  ('spalte|events.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|events.event_date|text|notnull=false|-'),
  ('spalte|events.event_on|date|notnull=false|-'),
  ('spalte|events.event_time|text|notnull=false|-'),
  ('spalte|events.expected_families|integer|notnull=false|-'),
  ('spalte|events.fields|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|events.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|events.intro|text|notnull=false|-'),
  ('spalte|events.mandatory|boolean|notnull=true|68934a3e9455fa72420237eb05902327'),
  ('spalte|events.payment|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|events.people|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|events.place|text|notnull=false|-'),
  ('spalte|events.retention_days|integer|notnull=true|aab3238922bcc25a6f606eb525ffdc56'),
  ('spalte|events.retention_note|text|notnull=false|-'),
  ('spalte|events.signup_from|date|notnull=false|-'),
  ('spalte|events.signup_released|boolean|notnull=true|b326b5062b2f0e69046810717534cb09'),
  ('spalte|events.signup_until|date|notnull=false|-'),
  ('spalte|events.slug|text|notnull=true|-'),
  ('spalte|events.tasks|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|events.template_id|uuid|notnull=false|-'),
  ('spalte|events.title|text|notnull=true|-'),
  ('spalte|events.visibility|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|feedback.better|text|notnull=false|-'),
  ('spalte|feedback.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|feedback.event_id|uuid|notnull=true|-'),
  ('spalte|feedback.from_name|text|notnull=false|-'),
  ('spalte|feedback.good|text|notnull=false|-'),
  ('spalte|feedback.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|feedback.rating|integer|notnull=false|-'),
  ('spalte|orga_keys.label|text|notnull=false|-'),
  ('spalte|orga_keys.secret|text|notnull=true|-'),
  ('spalte|payments.amount|numeric(8,2)|notnull=true|cfcd208495d565ef66e7dff9f98764da'),
  ('spalte|payments.paid_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|payments.signup_id|uuid|notnull=true|-'),
  ('spalte|planning.checklist|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|planning.event_id|uuid|notnull=true|-'),
  ('spalte|planning.review|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|planning.shopping|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|planning.updated_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|proposals.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|proposals.event_id|uuid|notnull=true|-'),
  ('spalte|proposals.from_name|text|notnull=false|-'),
  ('spalte|proposals.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|proposals.image|text|notnull=false|-'),
  ('spalte|proposals.info|text|notnull=false|-'),
  ('spalte|proposals.needed|integer|notnull=true|c81e728d9d4c2f636f067f89cc14862c'),
  ('spalte|proposals.note|text|notnull=false|-'),
  ('spalte|proposals.status|text|notnull=true|388211735e59825b90f128cbd8028c1f'),
  ('spalte|proposals.title|text|notnull=true|-'),
  ('spalte|signups.adults|integer|notnull=true|c4ca4238a0b923820dcc509a6f75849b'),
  ('spalte|signups.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|signups.event|text|notnull=true|-'),
  ('spalte|signups.fields|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|signups.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|signups.items|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|signups.kids|integer|notnull=true|cfcd208495d565ef66e7dff9f98764da'),
  ('spalte|signups.materials|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|signups.name|text|notnull=true|-'),
  ('spalte|signups.note|text|notnull=false|-'),
  ('spalte|signups.status|text|notnull=true|b612a1180103d361f58484b5b6671097'),
  ('spalte|signups.tasks|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|signups.token|text|notnull=true|2f6b8c6d3180ab06661adaf6c78f8662'),
  ('spalte|task_claims.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|task_claims.done|boolean|notnull=true|68934a3e9455fa72420237eb05902327'),
  ('spalte|task_claims.event_id|uuid|notnull=true|-'),
  ('spalte|task_claims.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|task_claims.name|text|notnull=true|-'),
  ('spalte|task_claims.task_id|text|notnull=true|-'),
  ('spalte|task_images.caption|text|notnull=false|-'),
  ('spalte|task_images.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|task_images.data|text|notnull=true|-'),
  ('spalte|task_images.event_id|uuid|notnull=true|-'),
  ('spalte|task_images.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|task_images.task_id|text|notnull=true|-'),
  ('spalte|templates.categories|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|templates.checklist|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|templates.created_at|timestamp with time zone|notnull=true|75230039beb12ce952f24927f2bfa2f2'),
  ('spalte|templates.description|text|notnull=false|-'),
  ('spalte|templates.fields|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|templates.id|uuid|notnull=true|f3b72bb359a50b640590970a2ab8e514'),
  ('spalte|templates.name|text|notnull=true|-'),
  ('spalte|templates.payment|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|templates.people|jsonb|notnull=true|f3db357cf4f4a03883484fa3281a056c'),
  ('spalte|templates.shopping|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('spalte|templates.tasks|jsonb|notnull=true|8b4b2df56ad0773943ef9179742da01b'),
  ('tabelle|attendance|r|rls=true'),
  ('tabelle|checkin_codes|r|rls=true'),
  ('tabelle|events|r|rls=true'),
  ('tabelle|feedback|r|rls=true'),
  ('tabelle|orga_keys|r|rls=true'),
  ('tabelle|payments|r|rls=true'),
  ('tabelle|planning|r|rls=true'),
  ('tabelle|proposals|r|rls=true'),
  ('tabelle|signups|r|rls=true'),
  ('tabelle|task_claims|r|rls=true'),
  ('tabelle|task_images|r|rls=true'),
  ('tabelle|templates|r|rls=true'))
, ist(zeile) as (
  with tab as (
    select c.oid, c.relname, c.relkind, c.relowner, c.relacl, c.relrowsecurity
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p', 'v', 'm', 'S')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_class'::regclass and d.objid = c.oid and d.deptype = 'e')
  ),
  fn as (
    select p.oid, p.proowner, p.proacl
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'intern')
      and p.prokind in ('f', 'p')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
  ),
  rollen(name) as (values ('anon'), ('authenticated'), ('service_role'), ('PUBLIC'))
  select zeile from (
    -- Tabellen und ob Row Level Security an ist
    select 'tabelle|' || relname || '|' || relkind::text || '|rls=' || relrowsecurity as zeile
    from tab
    union all
    -- Spalten mit Typ, Pflichtfeld und Standardwert
    select 'spalte|' || t.relname || '.' || a.attname || '|' || format_type(a.atttypid, a.atttypmod)
           || '|notnull=' || a.attnotnull || '|' || coalesce(md5(pg_get_expr(ad.adbin, ad.adrelid)), '-')
    from tab t
    join pg_attribute a on a.attrelid = t.oid and a.attnum > 0 and not a.attisdropped
    left join pg_attrdef ad on ad.adrelid = a.attrelid and ad.adnum = a.attnum
    where t.relkind <> 'S'
    union all
    -- Rechte auf ganze Tabellen
    select 'recht|' || t.relname || '|' || coalesce(ro.rolname, 'PUBLIC') || '|' || x.privilege_type
    from tab t
    cross join lateral aclexplode(coalesce(t.relacl,
        acldefault(case when t.relkind = 'S' then 's' else 'r' end::"char", t.relowner))) x
    left join pg_roles ro on ro.oid = x.grantee
    where coalesce(ro.rolname, 'PUBLIC') in (select name from rollen)
    union all
    -- Rechte auf einzelne Spalten (z. B. signups ohne token)
    select 'spaltenrecht|' || t.relname || '.' || a.attname || '|' || coalesce(ro.rolname, 'PUBLIC')
           || '|' || x.privilege_type
    from tab t
    join pg_attribute a on a.attrelid = t.oid and a.attnum > 0 and not a.attisdropped
                       and a.attacl is not null
    cross join lateral aclexplode(a.attacl) x
    left join pg_roles ro on ro.oid = x.grantee
    where coalesce(ro.rolname, 'PUBLIC') in (select name from rollen)
    union all
    -- Policies
    select 'policy|' || tablename || '|' || policyname || '|' || permissive || '|' || cmd || '|'
           || array_to_string(roles, ',') || '|' || coalesce(md5(qual), '-') || '|'
           || coalesce(md5(with_check), '-')
    from pg_policies
    where schemaname = 'public'
    union all
    -- Schlüssel, Fremdschlüssel, Prüfungen. Klammern zählen nicht: Prüfungen mit NOT VALID
    -- kommen als Text aus der Sicherung, und Postgres fasst verschachtelte AND dabei zusammen.
    select 'constraint|' || t.relname || '|' || co.conname || '|'
           || md5(translate(pg_get_constraintdef(co.oid), '()', ''))
    from tab t
    join pg_constraint co on co.conrelid = t.oid
    union all
    select 'index|' || t.relname || '|' || i.relname || '|' || md5(pg_get_indexdef(i.oid))
    from tab t
    join pg_index x on x.indrelid = t.oid
    join pg_class i on i.oid = x.indexrelid
    union all
    select 'trigger|' || t.relname || '|' || tg.tgname || '|' || md5(pg_get_triggerdef(tg.oid))
    from tab t
    join pg_trigger tg on tg.tgrelid = t.oid and not tg.tgisinternal
    union all
    -- Rechte auf das Schema intern (public verwaltet Supabase selbst)
    select 'schemarecht|' || n.nspname || '|' || coalesce(ro.rolname, 'PUBLIC') || '|' || x.privilege_type
    from pg_namespace n
    cross join lateral aclexplode(coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))) x
    left join pg_roles ro on ro.oid = x.grantee
    where n.nspname = 'intern' and coalesce(ro.rolname, 'PUBLIC') in (select name from rollen)
    union all
    -- Funktionen wie is_orga(), daten_aufraeumen() und intern.hat_zahlung()
    select 'funktion|' || f.oid::regprocedure::text || '|' || md5(pg_get_functiondef(f.oid))
    from fn f
    union all
    select 'funktionsrecht|' || f.oid::regprocedure::text || '|' || coalesce(ro.rolname, 'PUBLIC')
           || '|' || x.privilege_type
    from fn f
    cross join lateral aclexplode(coalesce(f.proacl, acldefault('f'::"char", f.proowner))) x
    left join pg_roles ro on ro.oid = x.grantee
    where coalesce(ro.rolname, 'PUBLIC') in (select name from rollen)
  ) z
  order by zeile
), fehlt as (
  select zeile from soll except select zeile from ist
), zuviel as (
  select zeile from ist except select zeile from soll
)
select ergebnis from (
  select 1 as nr, 'FEHLT: ' || zeile as ergebnis from fehlt
  union all
  select 2, 'ZUVIEL: ' || zeile from zuviel
  union all
  select 3, 'OK: Tabellen, Spalten, Policies, Funktionen und Rechte wie in der Vorlage'
  where not exists (select 1 from fehlt) and not exists (select 1 from zuviel)
  union all
  select 4, case when has_column_privilege('anon', 'public.signups', 'token', 'SELECT')
                 then 'GEFAHR: signups.token ist für jeden lesbar'
                 else 'OK: signups.token ist gesperrt' end
  union all
  select 5, case when has_table_privilege('anon', 'public.orga_keys', 'SELECT')
                 then 'GEFAHR: orga_keys ist für jeden lesbar'
                 else 'OK: orga_keys ist gesperrt' end
  union all
  select 6, case when (select count(*) from public.orga_keys) > 0
                 then 'OK: Orga-Passwort angelegt'
                 else 'FEHLT: kein Orga-Passwort in orga_keys' end
) z
order by nr, ergebnis;
