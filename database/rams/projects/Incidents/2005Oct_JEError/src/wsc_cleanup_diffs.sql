set linesize 1000
spool user_diffs.lst
column dist_vec format a80
column Labor format a80
column Charged format a80
column Configured format a80
column princ format a8
-- diffs between wsc and labor
select
        l.princ
        ,l.dist_vec Labor
        ,w.dist_vec Charged
  from oct_labor_dist_v l
        ,oct_wsc_v w
 where l.princ=w.princ
   and l.dist_vec!=w.dist_vec
   and l.princ not in (select princ from hostdb.who where charge_by='P')
/

---- diffs between wc and labor
--select
--        l.princ
--        ,l.dist_vec Labor
--        --,w.dist_vec Configured
--        ,wc.dist_vec Charged
--  from oct_labor_dist_v l
--        ,jnl245_wc_dist_v wc
--        --,oct_who_v w
-- where l.princ=wc.princ
--   --and l.princ=w.princ
--   and l.princ not in (select princ from hostdb.who where charge_by='P')
--   and l.dist_vec!=wc.dist_vec
--   and l.princ!='biglou'
--   --and l.dist_vec=w.dist_vec
--/
--spool off
set linesize 80
