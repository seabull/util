set linesize 120
column princ format a8
column acct format a28
column name format a24
spool mmv.lst
select
	unique
	wsc.princ
	,(select account_string(funding, function, activity, org, entity, project, task, award, null, null) from hostdb.accounts where id=wsc.account) acct
	,wsc.pct
  from  hostdb.who_service_charge wsc
 where wsc.princ='mmv'
/

select
	period_last
	,princ
	,name
	,(select account_string(funding, function, activity, org, entity, project, task, award, null, null) from hostdb.accounts where id=l.account) acct
	,pct_orig
	,pct_norm
	,appointment
	,charge_src
  from hostdb.labor_recorded l
 where l.princ='mmv'
   and period_last=(select max(period_last) from hostdb.labor_recorded where princ='mmv')
/

select
	princ
	,w.dist
	,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) acct
	,d.pct
  from hostdb.who w
	,hostdb.dist d
	,hostdb.accounts a
 where princ='mmv'
   and w.dist=d.dist
   and d.account=a.id
order by princ
/

select
	wsc.princ
	,(select account_string(funding, function, activity, org, entity, project, task, award, null, null) from hostdb.accounts where id=wsc.account) acct
	,wsc.pct
	,wsc.aud_action
	,wsc.aud_ts
	,wsc.aud_change_id
  from aud_hostdb.who_service_charge wsc
 where wsc.princ='mmv'
order by aud_ts
/

select
	*
  from aud_hostdb.who
 where princ='mmv'
order by aud_change_id
/
spool off
set linesize 80
