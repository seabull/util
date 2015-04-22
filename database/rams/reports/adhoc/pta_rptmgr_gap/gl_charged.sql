
set termout off
set linesize 1000
set pagesize 50000
set heading off
spool gl_charged.csv
select
	'org'
	||',acct_string'
	||',andrew_name'
	||',Full Name'
	||',Charge Flag'
	||',Last Post_Date'
	||',EmployeeNum Post_Date'
  from dual
/
	--||',flag'
	--||',"'||flag||'"'
	--||',"'||decode(sum(flag), 1, 'Valid', 2, 'Limbo', 3, 'Limbo_and_Valid', sum(flag))||'"'
select 
	unique
	acct_string
select
	unique
	org
	||','||acct_string
	||',"'||user_name||'"'
	||',"'||full_name||'"'
	||',"'||decode(sum(flag), 1, 'Valid', 2, 'Limbo', 3, 'Limbo_and_Valid', sum(flag))||'"'
	||',"'||last_postdate||'"'
	||',"'||employee_number||'"'
--spool foo
--select
--	--count(unique org)
--	count(unique acct_string)
  from 
(
	select
		unique
		x.org
		,x.acct_string
		,x.flag
		,case when x.last_post_wc > x.last_post_hc then
			x.last_post_wc
		else
			x.last_post_hc
		end last_postdate
		,u.user_name
		,u.full_name
		,u.employee_number
	  from 
	(
select
	unique
	a.acct_string
	,a.org
	,decode(c.account_flag, null, 1, 'b', 2,'l',2,'L',2,'i',100,1000) flag
	,(select max(j.post_date) 
		from hostdb.journals j
			, hostdb.host_charged hc
		where j.id=hc.journal
		  and hc.account=a.id
	) last_post_hc
	,(select max(j.post_date) 
		from hostdb.journals j
			, hostdb.who_charged wc
		where j.id=wc.journal
		  and wc.account=a.id
	) last_post_wc
  from accounts_str_gl_v a
	-- I could use hostdb.journal table but that table does not have account_flag column
	,(
		select
			unique
			account
			,account_flag
		  from hostdb.host_charged hc
		 where journal > 237 --  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
		union
		select
			unique
			account
			,account_flag
		  from hostdb.who_charged wc
		 where journal > 237 --  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
	) c
 where a.id=c.account
order by a.acct_string
) x
	,hostdb.acl_gl_orgs p
	,hostdb.acl_users u
 where rtrim(p.gl_org_number)=rtrim(x.org)
   and u.employee_id=p.employee_id
)
group by
	org
	,acct_string
	,last_postdate
	,user_name
	,full_name
	,employee_number
/
spool off
set linesize 80
set heading on
set termout on
