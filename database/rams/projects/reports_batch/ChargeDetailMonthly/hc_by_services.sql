set termout on
set feedback on
set linesize 120
--spool hc_by_services
create table hc_by_services
(
	NID		number
		constraint hcbyservices_pk primary key
	,hid		number(6)
	,service_id	number(3)
	,journal	number(5)
	,dist_vec	varchar2(4000)
)
tablespace costing_lg
/

create sequence hc_by_services_seq 
	start with 1
	increment by 1
	nocycle
/

insert /*+ append */ into hc_by_services 
(NID, hid, service_id, journal, dist_vec)
select
	hc_by_services_seq.nextval
	,xx.*
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
		,hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(hc.account_flag,'b','s','l','l','i','i',null),null) acct
		,hc.pct
		,hc.service_id
		,nvl(lower(hc.account_flag),'V') account_flag
		,hc.journal
	  from hostdb.host_charged hc
		,hostdb.accounts a
	 where
		hc.journal>204
	   and hc.journal<237
	   and hc.account=a.id
	order by 
		journal
		, id
		, service_id
		,hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
		, pct
		, hc.account_flag
	) x
) xx
where xx.dist_vec is not null
/

create index hcbyservices_svc_idx on hc_by_services (service_id)
tablespace indx logging;

create index hcbyservices_jnl_idx on hc_by_services (journal)
tablespace indx logging;

create index hcbyservices_hid_idx on hc_by_services (hid)
tablespace indx logging;

/*
	,concat_all(concat_expr(x.acct||'@'||x.pct,',')) dist_vec
group by 
	 journal
	, id
	, service_id
	, account_flag
order by 
	journal
	,id
	,service_id
	,account_flag
/
*/
--spool off
set termout on
set feedback on
set linesize 80
