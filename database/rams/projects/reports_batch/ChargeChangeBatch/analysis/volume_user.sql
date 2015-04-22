
create or replace view ylj_wc238_v
as
	select
		wr.princ
		,wr.name
		,wr.charge_src
		,wr.sponsor
		,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=wc.account_id) account_id
		,wc.charge
		,wc.amount
		,wc.pct
		,wr.project
		,wr.subproject
		,wc.services
		,wc.journal_id
	  from hostdb.who_recorded wr
		,hostdb.who_charged_summary wc
	 where wr.id=wc.wr_id
	   and wc.journal_id=238
	order by wr.princ
		,account_id
		,pct
/
create or replace view ylj_wc239_v
as
	select
		wr.princ
		,wr.name
		,wr.charge_src
		,wr.sponsor
		,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=wc.account_id) account_id
		,wc.charge
		,wc.amount
		,wc.pct
		,wr.project
		,wr.subproject
		,wc.services
		,wc.journal_id
	  from hostdb.who_recorded wr
		,hostdb.who_charged_summary wc
	 where wr.id=wc.wr_id
	   and wc.journal_id=239
	order by wr.princ
		,account_id
		,pct
/

create or replace view ylj_wc238_agg_v
as
select
	princ
	,name
	,charge_src||':'||dist_vec dist_vec
	,services
	,sponsor
  from (
	select
		princ
		,name
		--,stragg(account_id||'@'||pct||'-'||amount) charges
		,case when row_number() over (partition by princ, name, services order by account_id)=1 then
			stragg(account_id||'@'||pct||'-'||amount) over (partition by princ, name order by account_id
								rows between unbounded preceding and unbounded following)
		end dist_vec
		,services
		,sponsor
		,decode(charge_src, 'P', 'Project', 'X', 'Residual', 'B','Manual','D','DefaultWOPrj','O','O','S','S','L') charge_src
	  from ylj_wc238_v
	)
 where dist_vec is not null
/

create or replace view ylj_wc239_agg_v
as
select
	princ
	,name
	,charge_src||':'||dist_vec dist_vec
	,services
	,sponsor
  from (
	select
		princ
		,name
		--,stragg(account_id||'@'||pct||'-'||amount) charges
		,case when row_number() over (partition by princ, name, services order by account_id)=1 then
			stragg(account_id||'@'||pct||'-'||amount) over (partition by princ, name order by account_id
								rows between unbounded preceding and unbounded following)
		end dist_vec
		,services
		,sponsor
		,decode(charge_src, 'P', 'Project', 'X', 'Residual', 'B','Manual','D','DefaultWOPrj','O','O','S','S','L') charge_src
	  from ylj_wc239_v
	)
 where dist_vec is not null
/

-- old
-- select	
-- 	princ
-- 	,name
-- 	-- ,stragg(account_id||'@'||pct||'-'||amount) charges
-- 	,stragg(account_id||'@'||pct||'-'||amount) over (partition by princ, name order by account_id)
-- 	,services
-- 	,sponsor
--   from 
-- 	(
-- 		select  /*+ no_unnest */
-- 			princ
-- 			,name
-- 			,account_id
-- 			,pct
-- 			,amount
-- 			,charge
-- 			,services
-- 			,sponsor
-- 		  from ylj_wc239_v
-- 		order by princ
-- 			,account_id
-- 			,pct
-- 			,services
-- 	)
-- group by princ
-- 	,name
-- 	,services
-- 	,sponsor
-- /
-- 
-- GRANT CREATE ANY TABLE TO "YANGL@CS.CMU.EDU";
-- grant create materialized view to "YANGL@CS.CMU.EDU";
-- grant query rewrite to "YANGL@CS.CMU.EDU";
-- GRANT COMMENT ANY TABLE TO "YANGL@CS.CMU.EDU";

-- Note:
--	Oracle 9iR2 does not like subquery in MV definition.
--	To workaround, change the view ylj_wc238_v to use wc.account_id instead of subquery
--			when creating the MV
--		then, change ylj_wc238_v back to use subquery for account_string and refresh the MV.
--
--
-- create materialized view ylj_wc238_agg_mv
-- pctfree 0
-- tablespace costing_lg
-- parallel
-- build immediate
-- refresh complete on demand
-- disable query rewrite
-- as
-- select
-- 	*
--   from ylj_wc238_agg_v
-- /
-- 
-- create materialized view ylj_wc239_agg_mv
-- pctfree 0
-- tablespace costing_lg
-- parallel
-- build immediate
-- refresh complete on demand
-- disable query rewrite
-- as
-- select
-- 	*
--   from ylj_wc239_agg_v
-- /

exec dbms_mview.refresh('ylj_wc238_agg_mv');
exec dbms_mview.refresh('ylj_wc239_agg_mv');

--	select
--		wr.princ
--		,wr.name
--		,wr.charge_src
--			||':'||wc.account_id
--			||':'||wc.services
--			||':'||wc.charge
--			||'@'||wc.pct
--			||':'||wc.amount
--			||':'||wr.project
--			||':'||wr.subproject charges
--		,wr.sponsor
--	  from hostdb.who_recorded wr
--		,hostdb.who_charged_summary wc
--	 where wr.id=wc.wr_id
--	   and wc.journal_id=239
--	order by wr.princ
--		,account_id
--		,pct
--/
set pagesize 50000
set linesize 2000
set termout off
spool volume_user.lst
--select
--	count(distinct princ)
--  from
--(
--	select
--		unique
--		y1.princ
--		,y1.name
--		,y1.charge_src||':'||y1.account_id||'@'||y1.pct||':'||y1.amount||':"'||y1.services||'":'||y1.sponsor Chg_Jul
--		,y2.charge_src||':'||y2.account_id||'@'||y2.pct||':'||y2.amount||':"'||y2.services||'":'||y2.sponsor Chg_Aug
--	  from ylj_wc238_v y1
--		,ylj_wc239_v y2
--	 where
--		y1.princ=y2.princ
--)
--/
--
select
	princ
	||','||name
	||','||July
	||','||Aug
  from (
	select
		x.princ
		,'"'||x.name||'"' name
		,max(decode(Journal, 'Jul', '"'||x.charges||':'||services||'"')) July
		,max(decode(Journal, 'Aug', '"'||x.charges||':'||services||'"')) Aug
	  from (
		select
			y1.princ
			,y1.name
			,y1.charges
			,y1.services
			,'Jul' Journal
		  from ylj_wc238_agg_mv y1
		 where (y1.princ, y1.name, y1.charges, y1.services) not in (
				select
					y2.princ
					,y2.name
					,y2.charges
					,y2.services
				  from ylj_wc239_agg_mv y2
				)
		union all
		select
			y3.princ
			,y3.name
			,y3.charges
			,y3.services
			,'Aug'
		  from ylj_wc239_agg_mv y3
		 where (y3.princ, y3.name, y3.charges, y3.services) not in (
				select
					y4.princ
					,y4.name
					,y4.charges
					,y4.services
				  from ylj_wc238_agg_mv y4
				)
		) x
	group by x.princ
		, x.name
	order by x.princ
	)
/

--select
--	*
--  from
--(
--	select
--		unique
--		y1.princ
--		,y1.name
--		,y1.charge_src||':'||y1.account_id||'@'||y1.pct||':'||y1.amount||':"'||y1.services||'":'||y1.sponsor Chg_Jul
--		,y2.charge_src||':'||y2.account_id||'@'||y2.pct||':'||y2.amount||':"'||y2.services||'":'||y2.sponsor Chg_Aug
--	  from ylj_wc238_v y1
--		,ylj_wc239_v y2
--	 where
--		y1.princ=y2.princ
--)
--where
--	Chg_Jul<>Chg_Aug
--order by princ 
--/
spool off
set linesize 80
set termout on
