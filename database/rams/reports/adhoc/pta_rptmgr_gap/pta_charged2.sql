set termout off
set linesize 1000
set pagesize 50000
set heading off
set feedback off

spool Charged_NotIn_RM2_&1..csv

select
	'Generated on,'
	||to_char(sysdate, 'Mon-DD-YYYY')
  from dual
/

select
	'acct_string'
	||',pta'
	||',PI Name (AndrewID)'
	||',Project or Business Manager'
	||',proj_name'
	||',Charge Flag'
	||',Last Post_Date'
  from dual
/
	--||',flag'
	--||',"'||flag||'"'
	--||',"'||decode(sum(flag), 1, 'Valid', 2, 'Limbo', 3, 'Limbo_and_Valid', sum(flag))||'"'
select
	unique
	acct_string
	||',"'||pta||'"'
	||',"'||PI||'"'
	||',"'||Manager||'"'
	||',"'||proj_name||'"'
	||',"'||decode(sum(flag), 1, 'V', 2, 'L', 3, 'LV', sum(flag))||'"'
	||',"'||last_postdate||'"'
  from 
(
	select
		unique
		x.pta
		,x.acct_string
		,x.PI
		,x.proj_name
		,x.Manager
		,flag
		,case when nvl(last_post_wc, to_date('JAN-01-1970', 'MON-DD-YYYY')) > nvl(last_post_hc, to_date('JAN-01-1970', 'MON-DD-YYYY')) then
			last_post_wc
		else
			last_post_hc
		end last_postdate
	  from 
	(
select
	unique
	acct_string
	,pta
	,decode(account_flag, null, 1, 'b', 2,'l',2,'L',2,'i',100,1000) flag
	,(select max(j.post_date) 
		from hostdb.journals j
			, hostdb.host_charged hc
		where j.id=hc.journal
		  and hc.account=account_id
	) last_post_hc
	,(select max(j.post_date) 
		from hostdb.journals j
			, hostdb.who_charged wc
		where j.id=wc.journal
		  and wc.account=account_id
	) last_post_wc
	,proj_name
	,(select 
		u.full_name
		||'('||u.user_name||')'
	    from hostdb.acl_users u
		,hostdb.acl_projects prj
	   where u.employee_id=prj.employee_id
	     and p.project_id=prj.project_id
	     and prj.project_role like '%Investigator%'
	     and rownum<2
	) PI
	,(select 
		u.full_name
		||'('||u.user_name||')'
	    from hostdb.acl_users u
		,hostdb.acl_projects prj
	   where u.employee_id=prj.employee_id
	     and p.project_id=prj.project_id
	     and prj.project_role like '%Manager%'
	     and rownum<2
	) Manager
  from pta_chargedflag_last_fy_v p
 where 
	p.account_id not in (select account_id from hostdb.account_manager_assigned)
order by acct_string
) x
)
group by
	acct_string
	,pta
	,PI
	,proj_name
	,Manager
	,last_postdate
/
spool off
set linesize 80
set heading on
set termout on
set feedback on
