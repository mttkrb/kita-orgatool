-- Fingerabdruck von Struktur und Rechten in den Schemas public und intern, eine Zeile je Merkmal.
-- Wird im alten und im neuen Projekt ausgeführt und verglichen. Enthält keine Daten,
-- nur Namen und Prüfsummen. Rechte nur für die Rollen, über die die Seiten zugreifen.
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
order by zeile;
