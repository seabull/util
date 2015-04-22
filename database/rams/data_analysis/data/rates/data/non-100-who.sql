set linesize 1000

spool non-100-who.log
select
        *
  from hostdb.who
 where charge_by is null
   --and pct not in (3.5, 100, 1, 5, 30, 60)
   and pct not in (100, 1, 5, 30, 60)
   and dist is not null
/

--select
--        w.princ
--        ,w.charge_by
--        ,w.pct
--        ,max(period_last)
--  from hostdb.tmcd_recorded t
--        ,hostdb.who w
-- where t.princ=w.princ
--   and w.dist is not null
--   and w.pct not in (100, 30, 60, 4)
--group by w.princ
--        ,w.charge_by
--        ,w.pct
--order by w.princ
--/

-- part-timers from tmcd_recorded
update hostdb.who
   set pct=4
 where charge_by is null
   and dist is not null
   and pct != 100
   and princ in (select princ from hostdb.tmcd_recorded where princ is not null)
/

--update hostdb.who
--   set pct=4
-- where charge_by is null
--   --and pct not in (3.5, 100, 1, 5, 30, 60)
--   and pct not in (100, 30, 60)
--   and dist is not null
--/

update hostdb.who
   set pct=4
 where pct=3.5
   and dist is not null
/

-- How do we charge NREC users?
update hostdb.who
   set pct=60
 where dist is not null
   and princ in (select princ from hostdb.who_attr where upper(notes) like '%NREC%')
/

spool off
set linesize 80
