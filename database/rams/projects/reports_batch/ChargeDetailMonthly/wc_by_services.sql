set termout on
set feedback on
set linesize 120
--spool hc_by_services
/*
create table wc_by_services
(
	NID		number
		constraint wcbyservices_pk primary key
	,wid		number(6)
	,service_id	number(3)
	,journal	number(5)
	,dist_vec	varchar2(4000)
)
tablespace costing_lg
/

create sequence wc_by_services_seq 
	start with 1
	increment by 1
	nocycle
/
*/

insert /*+ append */ into wc_by_services 
(NID, wid, service_id, journal, dist_vec)
select
	wc_by_services_seq.nextval
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
		wc.wr_id id
		,hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(wc.account_flag,'b','s','l','l','i','i',null),null) acct
		,wc.pct
		,wc.service_id
		,nvl(lower(wc.account_flag),'V') account_flag
		,wc.journal
	  from hostdb.who_charged wc
		,hostdb.accounts a
	 where
		wc.journal>204
	   and wc.journal<237
	   and wc.account=a.id
	order by 
		journal
		, id
		, service_id
		,hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
		, pct
		, wc.account_flag
	) x
) xx
where xx.dist_vec is not null
/

create index wcbyservices_svc_idx on wc_by_services (service_id)
tablespace indx logging;

create index wcbyservices_jnl_idx on wc_by_services (journal)
tablespace indx logging;

create index wcbyservices_wid_idx on wc_by_services (wid)
tablespace indx logging;

--spool off
set termout on
set feedback on
set linesize 80
