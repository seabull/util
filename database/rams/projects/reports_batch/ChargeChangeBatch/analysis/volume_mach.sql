
create or replace view hc_summary_v
as
	select
		hr.assetno
		,hr.hostname
		,hr.charge_src
		,hr.usrprinc
		,hr.prjprinc
		,hr.princ
		,hr.location
		,hr.os
		,hr.qual
		,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=hc.account_id) account_id
		-- ,hc.account_id
		,hc.charge
		,hc.amount
		,hc.pct
		,hr.project
		,hr.subproject
		,hc.services
		,hc.journal_id
	  from hostdb.host_recorded hr
		,hostdb.host_charged_summary hc
	 where hr.id=hc.hr_id
	   -- and hc.journal_id=238
/

create or replace view hc_summary_agg_v
as
select
	assetno
	,hostname
	,charge_src||':'||dist_vec charges
	,services
	,usrprinc
	,journal
  from (
	select
		assetno
		,hostname
		,case when row_number() over (partition by assetno, hostname, services order by account_id)=1 then
			stragg(account_id||'@'||pct||'-'||amount) over (partition by assetno, hostname order by account_id
								rows between unbounded preceding and unbounded following)
		end dist_vec
		,services
		,usrprinc
		,decode(charge_src, 'P', 'Project', 'X', 'Residual', 'B','Manual','D','DefaultWOPrj','O','O','S','S','L') charge_src
		,journal_id journal
	  from hc_summary_v
	 --where journal_id=238
	)
 where dist_vec is not null
/

-- 
-- GRANT CREATE ANY TABLE TO "YANGL@CS.CMU.EDU";
-- grant create materialized view to "YANGL@CS.CMU.EDU";
-- grant query rewrite to "YANGL@CS.CMU.EDU";
-- GRANT COMMENT ANY TABLE TO "YANGL@CS.CMU.EDU";

-- Note:
--      Oracle 9iR2 does not like subquery in MV definition.
--      To workaround, change the view hc_summary_v to use hc.account_id instead of subquery
--                      when creating the MV
--              then, change hc_summary_v back to use subquery for account_string and refresh the MV.
--
--
-- create materialized view hc238_agg_mv
-- pctfree 0
-- tablespace costing_lg
-- parallel
-- build immediate
-- refresh complete on demand
-- disable query rewrite
-- as
-- select
-- 	*
--   from hc_summary_agg_v
--  where journal=238
-- /
-- 
-- create materialized view hc239_agg_mv
-- pctfree 0
-- tablespace costing_lg
-- parallel
-- build immediate
-- refresh complete on demand
-- disable query rewrite
-- as
-- select
-- 	*
--   from hc_summary_agg_v
--  where journal=239
-- /

-- select
-- 	assetno
-- 	,hostname
-- 	,charge_src||':'||dist_vec dist_vec
-- 	,services
-- 	,usrprinc
--   from (
-- 	select
-- 		assetno
-- 		,hostname
-- 		,case when row_number() over (partition by assetno, hostname, services order by account_id)=1 then
-- 			stragg(account||'@'||pct||'-'||amount) over (partition by assetno, hostname order by account_id
-- 								rows between unbounded preceding and unbounded following)
-- 		end dist_vec
-- 		,services
-- 		,usrprinc
-- 		,decode(charge_src, 'P', 'Project', 'X', 'Residual', 'B','Manual','D','DefaultWOPrj','O','O','S','S','L') charge_src
-- 	  from 
-- 		(
-- 			select
-- 				hr.assetno
-- 				,hr.hostname
-- 				,hr.charge_src
-- 				,hr.usrprinc
-- 				,hr.prjprinc
-- 				,hr.princ
-- 				,hr.location
-- 				,hr.os
-- 				,hr.qual
-- 				,hc.account_id
-- 				,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=hc.account_id) account
-- 				,hc.charge
-- 				,hc.amount
-- 				,hc.pct
-- 				,hr.project
-- 				,hr.subproject
-- 				,hc.services
-- 				,hc.journal_id
-- 			  from hostdb.host_recorded hr
-- 				,hostdb.host_charged_summary hc
-- 			 where hr.id=hc.hr_id
-- 			   and hc.journal_id=239
-- 		)
-- 	)
--  where dist_vec is not null
-- /

exec dbms_mview.refresh('hc238_agg_mv');
exec dbms_mview.refresh('hc239_agg_mv');

set pagesize 50000
set linesize 2000
set termout off
spool volume_mach.lst
select
	assetno
	||','||hostname
	||','||July
	||','||Aug
  from (
	select
		x.assetno
		,'"'||x.hostname||'"' hostname
		,max(decode(Journal, 'Jul', '"'||x.charges||':'||services||'"')) July
		,max(decode(Journal, 'Aug', '"'||x.charges||':'||services||'"')) Aug
	  from (
		select
			y1.assetno
			,y1.hostname
			,y1.charges
			,y1.services
			,'Jul' Journal
		  from hc238_agg_mv y1
		 where (y1.assetno, y1.hostname, y1.charges, y1.services) not in (
				select
					y2.assetno
					,y2.hostname
					,y2.charges
					,y2.services
				  from hc239_agg_mv y2
				)
		union all
		select
			y3.assetno
			,y3.hostname
			,y3.charges
			,y3.services
			,'Aug'
		  from hc239_agg_mv y3
		 where (y3.assetno, y3.hostname, y3.charges, y3.services) not in (
				select
					y4.assetno
					,y4.hostname
					,y4.charges
					,y4.services
				  from hc238_agg_mv y4
				)
		) x
	group by x.assetno
		, x.hostname
	order by x.assetno
	)
/

spool off
set linesize 80
set termout on
