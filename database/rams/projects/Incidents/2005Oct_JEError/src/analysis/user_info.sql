spool user_info.lst
prompt config in who
select
	w.princ
	,d.dist
	,d.account
	,d.pct
	,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=d.account) acct
  from hostdb.who w
	,hostdb.dist d
 where princ='yke'
   and w.dist=d.dist
/

prompt charge in wsc
select 
	unique
	princ
	,account
	,pct
	,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=wsc.account) acct
  from hostdb.who_service_charge wsc
 where princ='yke'
/

select
	unique
	wr_id
	,account 
	,journal
	,(select post_date from hostdb.journals where id=journal) post_date
  from hostdb.who_charged 
 where 
	--journal=245 
   --and 
	wr_id in (select id from hostdb.who_recorded where princ='yke')
order by journal
/

spool off
