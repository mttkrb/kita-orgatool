-- Zeilenzahl je Tabelle im Schema public, eine Zeile je Tabelle: tabelle|anzahl
-- Wird vom Umzugsskript im alten und im neuen Projekt ausgeführt und verglichen.
select c.relname || '|' ||
       (xpath('/row/n/text()',
              query_to_xml(format('select count(*) as n from public.%I', c.relname),
                           false, true, '')))[1]::text
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
  and not exists (select 1 from pg_depend d
                  where d.classid = 'pg_class'::regclass and d.objid = c.oid and d.deptype = 'e')
order by 1;
