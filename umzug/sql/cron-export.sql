-- Schreibt die aktiven pg_cron-Aufträge dieser Datenbank als SQL, das sie im neuen
-- Projekt wieder anlegt. cron.schedule mit Namen ersetzt einen gleichnamigen Auftrag,
-- das Einspielen lässt sich also wiederholen.
select case
         when jobname is null then format('select cron.schedule(%L, %L);', schedule, command)
         else format('select cron.schedule(%L, %L, %L);', jobname, schedule, command)
       end
from cron.job
where active and database = current_database()
order by jobid;
