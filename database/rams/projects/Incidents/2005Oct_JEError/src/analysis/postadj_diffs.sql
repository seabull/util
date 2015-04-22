--
-- difference between labor and who_charged
--
spool postadj_diffs.log
column Labor format a40
column Charged format a40
select
        l.princ
        ,l.dist_vec Labor
        --,w.dist_vec Configured
        ,wc.dist_vec Charged
  from "YANGL@CS.CMU.EDU".oct_labor_dist_v l
        ,"YANGL@CS.CMU.EDU".jnl245_wcadj_dist_v wc
        --,oct_who_v w
 where l.princ=wc.princ
   --and l.princ=w.princ
   and l.princ not in (select princ from hostdb.who where charge_by='P')
   and l.dist_vec!=wc.dist_vec
   and l.princ!='biglou'
   --and l.dist_vec=w.dist_vec
/
spool off
