-- grant select any table to "YANGL@CS.CMU.EDU";
-- grant create materialized view to "YANGL@CS.CMU.EDU";
set termout on
set feedback on
set linesize 120
--spool hc_by_services
create materialized view wc_by_services_fy0506_mv
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
		wc.journal>204
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

create index wcbyservicesfy0506mv_svcidx on wc_by_services_fy0506_mv (service_id)
tablespace indx nologging;

--spool off
set termout on
set feedback on
set linesize 80
