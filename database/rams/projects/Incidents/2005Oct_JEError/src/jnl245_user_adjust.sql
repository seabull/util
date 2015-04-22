drop table jnl245_user_adj;
create table jnl245_user_adj as
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
grant select on jnl245_user_adj to HOSTDB;

--	select
--		l.princ
--		,l.dist_vec Labor_dist
--		,w.dist_vec Configured_dist
--		,wsc.dist_vec Charged_dist
--	  from oct_labor_dist_v l
--		,oct_wsc_v wsc
--		,oct_who_v w
--	 where l.princ=w.princ
--	   and l.princ=wsc.princ
--	   and l.princ not in (select princ from hostdb.who where charge_by='P')
--	   and l.dist_vec!=wsc.dist_vec
--	   and l.dist_vec=w.dist_vec;
