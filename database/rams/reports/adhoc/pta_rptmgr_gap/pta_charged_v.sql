
--set termout off
set linesize 1000
set pagesize 50000
--set heading off

create or replace view journals_last_fy_v
as
select
        "ID","POST_DATE","JOURNAL_TYPE_FLAG","JE_IN_PROCESS_FLAG"
  from hostdb.journals
 where post_date >= to_date('01-JUL-'||to_char(add_months(sysdate,-6), 'YYYY'), 'DD-MON-YYYY')
/

create or replace view accts_added_curr_fy_v
as
select
        id
        , project, task, award
        , funding, function, activity, org, entity
  from aud_hostdb.accounts
 where aud_action='I'
   and aud_ts >= to_date('01-JUL-'||to_char(add_months(sysdate,-6), 'YYYY'), 'DD-MON-YYYY')
/

create or replace view accts_charged_last_fy_v
as
select
	account
  from hostdb.host_charged hc
 where journal > ( select max(id) from journals_last_fy_v )
union
select
	account
  from hostdb.who_charged wc
 where journal > ( select max(id) from journals_last_fy_v )
/

create or replace view accts_chargedflag_last_fy_v
as
select
	unique
	account
	,account_flag
	,max(journal) last_jnl
  from hostdb.host_charged hc
 where journal IN ( select id from journals_last_fy_v )
 group by account, account_flag
union
select
	unique
	account
	,account_flag
	,max(journal) last_jnl
  from hostdb.who_charged wc
 where journal IN ( select id from journals_last_fy_v )
 group by account, account_flag
/

create or replace view pta_charged_last_fy_v as
select
	unique
	a.acct_string
	,a.id account_id
	,p.pta
	,p.proj_name
	,p.project_id
  from accounts_str_gm_v a
	,accts_charged_last_fy_v c
	,hostdb.pta_status p
 where a.acct_string=p.pta(+)
   and a.id=c.account
/

create or replace view pta_chargedflag_last_fy_v as
select
	unique
	a.acct_string
	,p.pta
	,a.id account_id
	,c.account_flag
	,c.last_jnl
	,p.proj_name
	,p.project_id
  from accounts_str_gm_v a
	,accts_chargedflag_last_fy_v c
	,hostdb.pta_status p
 where a.acct_string=p.pta(+)
   and a.id=c.account
/
set linesize 80
set heading on
set termout on
