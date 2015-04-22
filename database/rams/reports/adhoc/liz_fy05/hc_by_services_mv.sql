set termout on
set feedback on
set linesize 120
--spool hc_by_services
create materialized view hc_by_services_fy0506_mv
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
		hc.hr_id id
		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(hc.account_flag,'b','s','l','l','i','i',null),null) acct
		,hc.pct
		,hc.service_id
		--,hc.account_flag
		,hc.journal
	  from hostdb.host_charged hc
		,hostdb.accounts a
	 where
		hc.journal > 204
	   --and hc.journal < 237
	   and hc.account=a.id
	order by 
		journal
		, id
		, service_id
		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
		, pct
		, hc.account_flag
	) x
) xx
where xx.dist_vec is not null
/

create index hcbyservicesfy0506mv_svcidx on hc_by_services_fy0506_mv (service_id)
tablespace indx nologging;

--spool off
set termout on
set feedback on
set linesize 80
