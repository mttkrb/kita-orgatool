-- =====================================================================
--  Kita-Orgatool – Neuinstallation
--
--  Einmal vollständig im SQL-Editor eines NEUEN, LEEREN Supabase-Projekts
--  ausführen (SQL Editor -> New query -> einfügen -> Run).
--  Anleitung: einrichtung/ANLEITUNG.md
--
--  Legt alle Tabellen, Funktionen, Policies, Rechte und Cron-Aufträge an und
--  erzeugt ein neues Orga-Passwort. Das Ergebnis unten zeigt das Passwort
--  genau einmal: sofort in den Passwortsafe des Vereins übernehmen.
--
--  Läuft in einer Transaktion: Bei einem Fehler wird nichts angelegt.
--  Enthält keine Daten.
--
--  Erzeugt am 2026-10-19 11:24 mit einrichtung/vorlage-erzeugen.sh
--  aus einem Projekt mit Postgres 17. Nicht von Hand ändern.
-- =====================================================================

begin;

do $$
begin
  if to_regclass('public.events') is not null then
    raise exception 'In diesem Projekt gibt es schon Tabellen des Orgatools. Die Neuinstallation ist nur für leere Projekte. Für Updates die migration-Dateien nehmen.';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 1. Erweiterungen (die meisten bringt Supabase schon mit)
-- ---------------------------------------------------------------------
create extension if not exists pg_stat_statements with schema extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists supabase_vault with schema vault;
create extension if not exists "uuid-ossp" with schema extensions;

-- ---------------------------------------------------------------------
-- 2. Tabellen, Funktionen, Policies, Trigger
-- ---------------------------------------------------------------------
--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Debian 17.11-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: intern; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA intern;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    title text NOT NULL,
    event_date text,
    event_time text,
    place text,
    intro text,
    categories jsonb DEFAULT '[]'::jsonb NOT NULL,
    tasks jsonb DEFAULT '[]'::jsonb NOT NULL,
    fields jsonb DEFAULT '[]'::jsonb NOT NULL,
    ask_people boolean DEFAULT true NOT NULL,
    retention_note text,
    archived boolean DEFAULT false NOT NULL,
    template_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    people jsonb DEFAULT '{}'::jsonb NOT NULL,
    event_on date,
    visibility jsonb DEFAULT '{}'::jsonb NOT NULL,
    signup_from date,
    signup_until date,
    signup_released boolean DEFAULT true NOT NULL,
    retention_days integer DEFAULT 14 NOT NULL,
    mandatory boolean DEFAULT false NOT NULL,
    expected_families integer,
    payment jsonb DEFAULT '{}'::jsonb NOT NULL,
    checkin boolean DEFAULT false NOT NULL,
    CONSTRAINT events_payment_groesse CHECK (((jsonb_typeof(payment) = 'object'::text) AND (octet_length((payment)::text) <= 4000)))
);


--
-- Name: signups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    adults integer DEFAULT 1 NOT NULL,
    kids integer DEFAULT 0 NOT NULL,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    tasks jsonb DEFAULT '[]'::jsonb NOT NULL,
    fields jsonb DEFAULT '{}'::jsonb NOT NULL,
    materials jsonb DEFAULT '[]'::jsonb NOT NULL,
    note text,
    token text DEFAULT encode(extensions.gen_random_bytes(8), 'hex'::text) NOT NULL,
    status text DEFAULT 'zusage'::text NOT NULL
);


--
-- Name: anmeldung_betrag(public.signups, public.events); Type: FUNCTION; Schema: intern; Owner: -
--

CREATE FUNCTION intern.anmeldung_betrag(s public.signups, e public.events) RETURNS numeric
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $_$
  select case when s.status = 'absage' then 0::numeric else round(
      case when case when e.people ? 'adults' then coalesce((e.people->'adults'->>'on')::boolean, false)
                     else e.ask_people end
           then s.adults * greatest(0, coalesce(nullif(e.payment->>'adults', '')::numeric, 0)) else 0 end
    + case when case when e.people ? 'kids' then coalesce((e.people->'kids'->>'on')::boolean, false)
                     else e.ask_people end
           then s.kids * greatest(0, coalesce(nullif(e.payment->>'kids', '')::numeric, 0)) else 0 end
    + coalesce((
        select sum(
          least(coalesce(nullif(nullif(f->>'max', ''), '0')::numeric, 99),
                greatest(0, floor(case when (s.fields->>(f->>'label')) ~ '^\s*[0-9]+([.][0-9]+)?\s*$'
                                       then (s.fields->>(f->>'label'))::numeric else 0 end)))
          * greatest(0, coalesce(nullif(f->>'price', '')::numeric, 0)))
        from jsonb_array_elements(coalesce(e.fields, '[]'::jsonb)) f
        where f->>'type' = 'order'), 0), 2) end;
$_$;


--
-- Name: hat_zahlung(uuid); Type: FUNCTION; Schema: intern; Owner: -
--

CREATE FUNCTION intern.hat_zahlung(p_signup uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (select 1 from payments where signup_id = p_signup);
$$;


--
-- Name: kurzname(text); Type: FUNCTION; Schema: intern; Owner: -
--

CREATE FUNCTION intern.kurzname(p_name text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public'
    AS $$
  select case when coalesce(array_length(t, 1), 0) < 2 then t[1]
              else t[1] || ' ' || left(t[array_length(t, 1)], 1) || '.' end
  from (select regexp_split_to_array(btrim(p_name), '\s+') as t) x;
$$;


--
-- Name: anmeldungen_oeffentlich(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.anmeldungen_oeffentlich(p_events text[]) RETURNS TABLE(event text, adults integer, kids integer, items jsonb, tasks jsonb, status text, name text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select s.event,
         case when s.status = 'absage' then 0 else s.adults end,
         case when s.status = 'absage' then 0 else s.kids end,
         case when s.status = 'absage' then '[]'::jsonb else s.items end,
         case when s.status = 'absage' then '[]'::jsonb else s.tasks end,
         s.status,
         case when s.status <> 'absage'
               and (coalesce(e.visibility ->> 'itemNames', 'true') <> 'false'
                    or coalesce(e.visibility ->> 'taskNames', 'true') <> 'false')
              then intern.kurzname(s.name) end
  from signups s
  join events e on e.slug = s.event
  where s.event = any (p_events[1:50])
  order by s.created_at;
$$;


--
-- Name: checkin(uuid, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.checkin(p_signup uuid, p_token text, p_code text, p_out boolean DEFAULT false) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  a record;
  heute date := (now() at time zone 'Europe/Berlin')::date;
  r attendance%rowtype;
begin
  select * into a from checkin_pruefen(p_signup, p_token);
  if not found then
    return json_build_object('ok', false, 'fehler', 'anmeldung');
  end if;
  if not a.aktiv then
    return json_build_object('ok', false, 'fehler', 'aus');
  end if;
  if not exists (select 1 from checkin_codes c
                 where c.event_id = a.event_id and c.code = p_code) then
    return json_build_object('ok', false, 'fehler', 'code');
  end if;
  if a.event_on is null or a.event_on <> heute then
    return json_build_object('ok', false, 'fehler', 'tag');
  end if;
  if not p_out and exists (select 1 from signups s
                           where s.id = a.signup_id and s.status = 'absage') then
    return json_build_object('ok', false, 'fehler', 'absage');
  end if;

  if p_out then
    update attendance set checked_out_at = now()
     where attendance.signup_id = a.signup_id and checked_in_at is not null
    returning * into r;
    if not found then
      return json_build_object('ok', false, 'fehler', 'nicht_da');
    end if;
  else
    insert into attendance (signup_id, checked_in_at, source)
    values (a.signup_id, now(), 'qr')
    on conflict (signup_id) do update
      set checked_in_at = coalesce(attendance.checked_in_at, excluded.checked_in_at)
    returning * into r;
  end if;
  return json_build_object('ok', true, 'checked_in_at', r.checked_in_at,
                           'checked_out_at', r.checked_out_at);
end $$;


--
-- Name: checkin_pruefen(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.checkin_pruefen(p_signup uuid, p_token text) RETURNS TABLE(signup_id uuid, event_id uuid, event_on date, aktiv boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select s.id, e.id, e.event_on, e.checkin
  from signups s join events e on e.slug = s.event
  where s.id = p_signup and s.token = p_token and length(coalesce(p_token,'')) between 8 and 64;
$$;


--
-- Name: checkin_status(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.checkin_status(p_signup uuid, p_token text) RETURNS json
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  a record;
  r attendance%rowtype;
begin
  select * into a from checkin_pruefen(p_signup, p_token);
  if not found then
    return json_build_object('ok', false, 'fehler', 'anmeldung');
  end if;
  select * into r from attendance where attendance.signup_id = a.signup_id;
  return json_build_object('ok', true, 'checked_in_at', r.checked_in_at,
                           'checked_out_at', r.checked_out_at);
end $$;


--
-- Name: daten_aufraeumen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.daten_aufraeumen() RETURNS TABLE(was text, anzahl integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
declare
  namen_tage constant int := 60;
  n int;
  ev record;
begin
  if not (is_orga() or current_user in ('postgres','supabase_admin','cron_job')) then
    raise exception 'nicht berechtigt';
  end if;

  for ev in
    select e.id, e.slug
    from events e
    where e.event_on is not null
      and e.event_on < current_date - coalesce(e.retention_days, 14)
      and exists (select 1 from signups s where s.event = e.slug)
  loop
    insert into planning (event_id, checklist, review)
    values (ev.id, '[]'::jsonb, '{}'::jsonb)
    on conflict (event_id) do nothing;

    update planning p
    set review = coalesce(p.review, '{}'::jsonb) || jsonb_build_object(
      'zahlen', jsonb_build_object(
        'stand',       to_char(now(), 'YYYY-MM-DD'),
        'anmeldungen', (select count(*) from signups s where s.event = ev.slug),
        'erwachsene',  (select coalesce(sum(s.adults),0) from signups s where s.event = ev.slug),
        'kinder',      (select coalesce(sum(s.kids),0)   from signups s where s.event = ev.slug),
        'kategorien',  coalesce((
          select jsonb_object_agg(k.cat, k.menge) from (
            select i->>'cat' as cat,
                   sum(coalesce(nullif(i->>'qty','')::int, 1)) as menge
            from signups s, jsonb_array_elements(s.items) i
            where s.event = ev.slug and i->>'cat' is not null
            group by 1) k), '{}'::jsonb),
        'aufgaben',    coalesce((
          select jsonb_object_agg(a.tid, a.anzahl) from (
            select t.value #>> '{}' as tid, count(*) as anzahl
            from signups s, jsonb_array_elements(s.tasks) t
            where s.event = ev.slug
            group by 1) a), '{}'::jsonb),
        'anwesend',    (select count(*) from attendance a join signups s on s.id = a.signup_id
                         where s.event = ev.slug),
        'stunden',     (select round(coalesce(sum(coalesce(a.hours,
                           extract(epoch from (a.checked_out_at - a.checked_in_at)) / 3600)), 0)::numeric, 2)
                         from attendance a join signups s on s.id = a.signup_id where s.event = ev.slug)
      ),
      'geld', coalesce(p.review->'geld', '{}'::jsonb) || jsonb_build_object(
        'einnahmen',   (select coalesce(sum(intern.anmeldung_betrag(s, e)), 0)
                         from signups s join events e on e.slug = s.event where s.event = ev.slug),
        'bezahlt',     (select coalesce(sum(z.amount), 0) from payments z join signups s on s.id = z.signup_id
                         where s.event = ev.slug),
        'stand',       to_char(now(), 'YYYY-MM-DD')
      ))
    where p.event_id = ev.id;
  end loop;

  delete from signups s
  where not exists (select 1 from events e where e.slug = s.event);
  get diagnostics n = row_count;
  was := 'verwaiste Anmeldungen'; anzahl := n; return next;

  delete from signups s
  using events e
  where e.slug = s.event
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14);
  get diagnostics n = row_count;
  was := 'abgelaufene Anmeldungen'; anzahl := n; return next;

  delete from task_claims c
  using events e
  where e.id = c.event_id
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14);
  get diagnostics n = row_count;
  was := 'abgelaufene Aufgabenzusagen'; anzahl := n; return next;

  -- NEU: archivieren, sobald die Frist abgelaufen ist und keine Namen mehr da sind
  update events e
  set archived = true
  where e.archived = false
    and e.event_on is not null
    and e.event_on < current_date - coalesce(e.retention_days, 14)
    and not exists (select 1 from signups s where s.event = e.slug);
  get diagnostics n = row_count;
  was := 'archivierte Veranstaltungen'; anzahl := n; return next;

  update feedback f set from_name = null
  from events e
  where e.id = f.event_id and f.from_name is not null
    and e.event_on is not null and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Rueckmeldungen'; anzahl := n; return next;

  update proposals p set from_name = null
  from events e
  where e.id = p.event_id and p.from_name is not null
    and e.event_on is not null and e.event_on < current_date - namen_tage;
  get diagnostics n = row_count;
  was := 'anonymisierte Meldungen'; anzahl := n; return next;

  return;
end;
$$;


--
-- Name: is_orga(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_orga() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from orga_keys k
    where k.secret = current_setting('request.headers', true)::json ->> 'x-orga-key'
  );
$$;


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance (
    signup_id uuid NOT NULL,
    checked_in_at timestamp with time zone,
    checked_out_at timestamp with time zone,
    hours numeric(4,2),
    source text DEFAULT 'qr'::text NOT NULL,
    CONSTRAINT attendance_hours_check CHECK (((hours IS NULL) OR ((hours >= (0)::numeric) AND (hours <= (24)::numeric)))),
    CONSTRAINT attendance_source_check CHECK ((source = ANY (ARRAY['qr'::text, 'orga'::text])))
);


--
-- Name: checkin_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkin_codes (
    event_id uuid NOT NULL,
    code text DEFAULT translate(encode(extensions.gen_random_bytes(9), 'base64'::text), '+/'::text, '-_'::text) NOT NULL,
    CONSTRAINT checkin_codes_code_check CHECK (((length(code) >= 8) AND (length(code) <= 40)))
);


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    rating integer,
    good text,
    better text,
    from_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: orga_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orga_keys (
    secret text NOT NULL,
    label text
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    signup_id uuid NOT NULL,
    amount numeric(8,2) DEFAULT 0 NOT NULL,
    paid_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payments_amount_check CHECK (((amount >= (0)::numeric) AND (amount < (100000)::numeric)))
);


--
-- Name: planning; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning (
    event_id uuid NOT NULL,
    checklist jsonb DEFAULT '[]'::jsonb NOT NULL,
    review jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    shopping jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: proposals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    title text NOT NULL,
    info text,
    needed integer DEFAULT 2 NOT NULL,
    from_name text,
    image text,
    status text DEFAULT 'neu'::text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: task_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_claims (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    task_id text NOT NULL,
    name text NOT NULL,
    done boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: task_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    task_id text NOT NULL,
    caption text,
    data text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    categories jsonb DEFAULT '[]'::jsonb NOT NULL,
    tasks jsonb DEFAULT '[]'::jsonb NOT NULL,
    fields jsonb DEFAULT '[]'::jsonb NOT NULL,
    checklist jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    people jsonb DEFAULT '{}'::jsonb NOT NULL,
    shopping jsonb DEFAULT '[]'::jsonb NOT NULL,
    payment jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT templates_payment_groesse CHECK (((jsonb_typeof(payment) = 'object'::text) AND (octet_length((payment)::text) <= 4000)))
);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (signup_id);


--
-- Name: checkin_codes checkin_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkin_codes
    ADD CONSTRAINT checkin_codes_pkey PRIMARY KEY (event_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: events events_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_slug_key UNIQUE (slug);


--
-- Name: feedback feedback_grenzen_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.feedback
    ADD CONSTRAINT feedback_grenzen_chk CHECK (((length(COALESCE(good, ''::text)) <= 2000) AND (length(COALESCE(better, ''::text)) <= 2000) AND (length(COALESCE(from_name, ''::text)) <= 120) AND ((rating IS NULL) OR ((rating >= 1) AND (rating <= 5))))) NOT VALID;


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: orga_keys orga_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orga_keys
    ADD CONSTRAINT orga_keys_pkey PRIMARY KEY (secret);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (signup_id);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (event_id);


--
-- Name: proposals proposals_grenzen_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.proposals
    ADD CONSTRAINT proposals_grenzen_chk CHECK ((((length(title) >= 1) AND (length(title) <= 200)) AND (length(COALESCE(info, ''::text)) <= 2000) AND (length(COALESCE(from_name, ''::text)) <= 120) AND ((needed >= 1) AND (needed <= 99)))) NOT VALID;


--
-- Name: proposals proposals_image_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.proposals
    ADD CONSTRAINT proposals_image_chk CHECK (((image IS NULL) OR ((length(image) <= 1500000) AND (image ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$'::text)))) NOT VALID;


--
-- Name: proposals proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_pkey PRIMARY KEY (id);


--
-- Name: signups signups_grenzen_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.signups
    ADD CONSTRAINT signups_grenzen_chk CHECK ((((length(name) >= 1) AND (length(name) <= 120)) AND (length(COALESCE(note, ''::text)) <= 1000) AND ((adults >= 0) AND (adults <= 50)) AND ((kids >= 0) AND (kids <= 50)) AND (length((items)::text) <= 20000) AND (length((tasks)::text) <= 5000) AND (length((fields)::text) <= 5000) AND (length((materials)::text) <= 5000))) NOT VALID;


--
-- Name: signups signups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signups
    ADD CONSTRAINT signups_pkey PRIMARY KEY (id);


--
-- Name: task_claims task_claims_grenzen_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.task_claims
    ADD CONSTRAINT task_claims_grenzen_chk CHECK ((((length(name) >= 1) AND (length(name) <= 120)) AND (length(task_id) <= 100))) NOT VALID;


--
-- Name: task_claims task_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_claims
    ADD CONSTRAINT task_claims_pkey PRIMARY KEY (id);


--
-- Name: task_images task_images_data_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.task_images
    ADD CONSTRAINT task_images_data_chk CHECK (((length(data) <= 1500000) AND (data ~ '^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$'::text))) NOT VALID;


--
-- Name: task_images task_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_images
    ADD CONSTRAINT task_images_pkey PRIMARY KEY (id);


--
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: feedback_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX feedback_event_idx ON public.feedback USING btree (event_id);


--
-- Name: proposals_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX proposals_event_idx ON public.proposals USING btree (event_id, status);


--
-- Name: task_claims_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_claims_event_idx ON public.task_claims USING btree (event_id);


--
-- Name: task_images_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_images_event_idx ON public.task_images USING btree (event_id);


--
-- Name: attendance attendance_signup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_signup_id_fkey FOREIGN KEY (signup_id) REFERENCES public.signups(id) ON DELETE CASCADE;


--
-- Name: checkin_codes checkin_codes_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkin_codes
    ADD CONSTRAINT checkin_codes_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: events events_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.templates(id) ON DELETE SET NULL;


--
-- Name: feedback feedback_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: payments payments_signup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_signup_id_fkey FOREIGN KEY (signup_id) REFERENCES public.signups(id) ON DELETE CASCADE;


--
-- Name: planning planning_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: proposals proposals_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: task_claims task_claims_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_claims
    ADD CONSTRAINT task_claims_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: task_images task_images_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_images
    ADD CONSTRAINT task_images_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: signups anmelden; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY anmelden ON public.signups FOR SELECT TO anon USING ((public.is_orga() OR (token = ((current_setting('request.headers'::text, true))::json ->> 'x-entry-token'::text))));


--
-- Name: signups anmeldung neu; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anmeldung neu" ON public.signups FOR INSERT TO anon WITH CHECK (true);


--
-- Name: attendance anwesenheit nur orga; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anwesenheit nur orga" ON public.attendance TO anon USING (public.is_orga()) WITH CHECK (public.is_orga());


--
-- Name: attendance; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

--
-- Name: task_claims aufgaben aendern; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "aufgaben aendern" ON public.task_claims FOR UPDATE TO anon USING (true);


--
-- Name: task_claims aufgaben belegen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "aufgaben belegen" ON public.task_claims FOR INSERT TO anon WITH CHECK (true);


--
-- Name: task_claims aufgaben freigeben; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "aufgaben freigeben" ON public.task_claims FOR DELETE TO anon USING (true);


--
-- Name: task_claims aufgaben lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "aufgaben lesen" ON public.task_claims FOR SELECT TO anon USING (true);


--
-- Name: task_images bilder anlegen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "bilder anlegen" ON public.task_images FOR INSERT TO anon WITH CHECK (public.is_orga());


--
-- Name: task_images bilder lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "bilder lesen" ON public.task_images FOR SELECT TO anon USING (true);


--
-- Name: task_images bilder loeschen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "bilder loeschen" ON public.task_images FOR DELETE TO anon USING (public.is_orga());


--
-- Name: checkin_codes checkin codes nur orga; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "checkin codes nur orga" ON public.checkin_codes TO anon USING (public.is_orga()) WITH CHECK (public.is_orga());


--
-- Name: checkin_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.checkin_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: signups eigene aendern; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "eigene aendern" ON public.signups FOR UPDATE TO anon USING (((token = ((current_setting('request.headers'::text, true))::json ->> 'x-entry-token'::text)) OR public.is_orga()));


--
-- Name: signups eigene loeschen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "eigene loeschen" ON public.signups FOR DELETE TO anon USING ((public.is_orga() OR ((token = ((current_setting('request.headers'::text, true))::json ->> 'x-entry-token'::text)) AND (NOT intern.hat_zahlung(id)))));


--
-- Name: events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

--
-- Name: events events aendern; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "events aendern" ON public.events FOR UPDATE TO anon USING (public.is_orga());


--
-- Name: events events anlegen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "events anlegen" ON public.events FOR INSERT TO anon WITH CHECK (public.is_orga());


--
-- Name: events events lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "events lesen" ON public.events FOR SELECT TO anon USING (true);


--
-- Name: events events loeschen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "events loeschen" ON public.events FOR DELETE TO anon USING (public.is_orga());


--
-- Name: feedback; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: feedback feedback geben; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "feedback geben" ON public.feedback FOR INSERT TO anon WITH CHECK (true);


--
-- Name: feedback feedback lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "feedback lesen" ON public.feedback FOR SELECT TO anon USING (public.is_orga());


--
-- Name: feedback feedback loeschen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "feedback loeschen" ON public.feedback FOR DELETE TO anon USING (public.is_orga());


--
-- Name: orga_keys; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.orga_keys ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: planning; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.planning ENABLE ROW LEVEL SECURITY;

--
-- Name: planning planung; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY planung ON public.planning TO anon USING (public.is_orga()) WITH CHECK (public.is_orga());


--
-- Name: proposals; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.proposals ENABLE ROW LEVEL SECURITY;

--
-- Name: signups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.signups ENABLE ROW LEVEL SECURITY;

--
-- Name: task_claims; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: task_images; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_images ENABLE ROW LEVEL SECURITY;

--
-- Name: templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

--
-- Name: templates vorlagen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vorlagen ON public.templates TO anon USING (public.is_orga()) WITH CHECK (public.is_orga());


--
-- Name: proposals vorschlaege aendern; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "vorschlaege aendern" ON public.proposals FOR UPDATE TO anon USING (public.is_orga());


--
-- Name: proposals vorschlaege lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "vorschlaege lesen" ON public.proposals FOR SELECT TO anon USING ((public.is_orga() OR (status <> 'abgelehnt'::text)));


--
-- Name: proposals vorschlaege loeschen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "vorschlaege loeschen" ON public.proposals FOR DELETE TO anon USING (public.is_orga());


--
-- Name: proposals vorschlag einreichen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "vorschlag einreichen" ON public.proposals FOR INSERT TO anon WITH CHECK (true);


--
-- Name: payments zahlungen nur orga; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "zahlungen nur orga" ON public.payments TO anon USING (public.is_orga()) WITH CHECK (public.is_orga());


--
-- PostgreSQL database dump complete
--



-- ---------------------------------------------------------------------
-- 3. Rechte
--    Supabase gibt neuen Tabellen von sich aus alle Rechte für anon, damit
--    wäre unter anderem signups.token für jeden lesbar. Deshalb erst alle
--    Rechte entfernen, dann genau die Rechte der Vorlage setzen.
-- ---------------------------------------------------------------------
do $$
declare
  o record;
begin
  for o in
    select c.oid::regclass as name, c.relkind
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('public', 'intern')
      and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_class'::regclass and d.objid = c.oid and d.deptype = 'e')
  loop
    if o.relkind = 'S' then
      execute format('revoke all on sequence %s from anon, authenticated, service_role', o.name);
    else
      execute format('revoke all on table %s from anon, authenticated, service_role', o.name);
    end if;
  end loop;

  for o in
    select p.oid::regprocedure as name
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'intern')
      and p.prokind in ('f', 'p')
      and not exists (select 1 from pg_depend d
                      where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
  loop
    execute format('revoke all on routine %s from anon, authenticated, service_role', o.name);
  end loop;
end $$;

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Debian 17.11-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: SCHEMA intern; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA intern TO anon;


--
-- Name: TABLE events; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.events TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.events TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.events TO service_role;


--
-- Name: COLUMN events.payment; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(payment),INSERT(payment),UPDATE(payment) ON TABLE public.events TO anon;


--
-- Name: COLUMN events.checkin; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(checkin),INSERT(checkin),UPDATE(checkin) ON TABLE public.events TO anon;


--
-- Name: TABLE signups; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.signups TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.signups TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.signups TO service_role;


--
-- Name: COLUMN signups.id; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(id) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.event; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(event) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.created_at; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(created_at) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.name; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(name) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.adults; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(adults) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.kids; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(kids) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(items) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.tasks; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(tasks) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.fields; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(fields) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.materials; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(materials) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.note; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(note) ON TABLE public.signups TO anon;


--
-- Name: COLUMN signups.status; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(status) ON TABLE public.signups TO anon;


--
-- Name: FUNCTION anmeldung_betrag(s public.signups, e public.events); Type: ACL; Schema: intern; Owner: -
--

REVOKE ALL ON FUNCTION intern.anmeldung_betrag(s public.signups, e public.events) FROM PUBLIC;


--
-- Name: FUNCTION hat_zahlung(p_signup uuid); Type: ACL; Schema: intern; Owner: -
--

REVOKE ALL ON FUNCTION intern.hat_zahlung(p_signup uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION intern.hat_zahlung(p_signup uuid) TO anon;


--
-- Name: FUNCTION kurzname(p_name text); Type: ACL; Schema: intern; Owner: -
--

REVOKE ALL ON FUNCTION intern.kurzname(p_name text) FROM PUBLIC;


--
-- Name: FUNCTION anmeldungen_oeffentlich(p_events text[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.anmeldungen_oeffentlich(p_events text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.anmeldungen_oeffentlich(p_events text[]) TO anon;


--
-- Name: FUNCTION checkin(p_signup uuid, p_token text, p_code text, p_out boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.checkin(p_signup uuid, p_token text, p_code text, p_out boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.checkin(p_signup uuid, p_token text, p_code text, p_out boolean) TO anon;


--
-- Name: FUNCTION checkin_pruefen(p_signup uuid, p_token text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.checkin_pruefen(p_signup uuid, p_token text) FROM PUBLIC;


--
-- Name: FUNCTION checkin_status(p_signup uuid, p_token text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.checkin_status(p_signup uuid, p_token text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.checkin_status(p_signup uuid, p_token text) TO anon;


--
-- Name: FUNCTION daten_aufraeumen(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.daten_aufraeumen() TO anon;


--
-- Name: FUNCTION is_orga(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.is_orga() TO anon;


--
-- Name: TABLE attendance; Type: ACL; Schema: public; Owner: -
--

GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.attendance TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.attendance TO anon;


--
-- Name: TABLE checkin_codes; Type: ACL; Schema: public; Owner: -
--

GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.checkin_codes TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.checkin_codes TO anon;


--
-- Name: TABLE feedback; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.feedback TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.feedback TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.feedback TO service_role;


--
-- Name: TABLE orga_keys; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.orga_keys TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.orga_keys TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.orga_keys TO service_role;


--
-- Name: TABLE payments; Type: ACL; Schema: public; Owner: -
--

GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.payments TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.payments TO anon;


--
-- Name: TABLE planning; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.planning TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.planning TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.planning TO service_role;


--
-- Name: TABLE proposals; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.proposals TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.proposals TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.proposals TO service_role;


--
-- Name: TABLE task_claims; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.task_claims TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.task_claims TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.task_claims TO service_role;


--
-- Name: TABLE task_images; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.task_images TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.task_images TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.task_images TO service_role;


--
-- Name: TABLE templates; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.templates TO anon;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.templates TO authenticated;
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE public.templates TO service_role;


--
-- Name: COLUMN templates.payment; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(payment),INSERT(payment),UPDATE(payment) ON TABLE public.templates TO anon;


--
-- PostgreSQL database dump complete
--



-- ---------------------------------------------------------------------
-- 5. Orga-Passwort
-- ---------------------------------------------------------------------
create temporary table neues_orga_passwort as
  select translate(encode(extensions.gen_random_bytes(24), 'base64'), '+/', '-_') as passwort;
insert into public.orga_keys (secret, label)
  select passwort, 'Orgateam' from pg_temp.neues_orga_passwort;

commit;

-- Schnittstelle die neuen Tabellen sofort bekannt machen
notify pgrst, 'reload schema';

-- Das neue Orga-Passwort. Erscheint nur hier und nur jetzt.
select passwort as "Orga-Passwort – jetzt in den Passwortsafe übernehmen"
from pg_temp.neues_orga_passwort;
