
insert into accts
(acct_id, acct_str, type, flag)
select
	id
	,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)
	,decode(project, null, 'L', 'M')
	,a.flag
  from hostdb.accounts a
/
