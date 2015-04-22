-- $Header: c:\\Repository/database/rams/reports/adhoc/DetailY2D/wc_by_services_mv.sql,v 1.2 2006/05/17 14:50:28 yangl Exp $
--
-- grant select any table to "YANGL@CS.CMU.EDU";
-- grant create materialized view to "YANGL@CS.CMU.EDU";
set termout on
set feedback on
set linesize 120
--spool hc_by_services

create materialized view wc_by_services_y2d_mv
pctfree 0
tablespace costing_lg
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	*
  from (
select 
	id
	,service_id
	--,account_flag
	,journal
	,case when row_number() over (partition by journal, id, service_id order by acct)=1 then
		stragg(x.acct||'@'||pct) over (partition by journal, id, service_id order by acct 
					rows between unbounded preceding and unbounded following) 
	end dist_vec
  from (
	select
		wc.wr_id id
		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(wc.account_flag,'b','s','l','l','i','i',null),null) acct
		,wc.pct
		,wc.service_id
		,nvl(lower(wc.account_flag),'V') account_flag
		,wc.journal
	  from hostdb.who_charged wc
		,hostdb.accounts a
	 where
		wc.journal>=(select min(id) from hostdb.journals where post_date>=to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY'))
	    and wc.journal!=246
	   -- and wc.journal<237
	   and wc.account=a.id
	order by 
		journal
		, id
		, service_id
		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
		, pct
		, wc.account_flag
	) x
) xx
where xx.dist_vec is not null
/

create index wcbyservicesy2dmv_svcidx on wc_by_services_y2d_mv (service_id)
tablespace indx nologging;

--spool off
set termout on
set feedback on
set linesize 80
