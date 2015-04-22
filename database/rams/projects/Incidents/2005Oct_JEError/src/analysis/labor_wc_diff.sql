set linesize 1000
column Labor format a60
column Charged format a60
spool labor_wc_diff.log
select
        l.princ
        ,l.dist_vec Labor
        --,w.dist_vec Configured
        ,wc.dist_vec Charged
  from oct_labor_dist_v l
        ,jnl245_wc_dist_v wc
        --,oct_who_v w
 where l.princ=wc.princ
   --and l.princ=w.princ
   and l.princ not in (select princ from hostdb.who where charge_by='P')
   and l.dist_vec!=wc.dist_vec
   and l.princ!='biglou'
   --and l.dist_vec=w.dist_vec
/
spool off
