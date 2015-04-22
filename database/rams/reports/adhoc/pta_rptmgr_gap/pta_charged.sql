
set termout off
set linesize 1000
set pagesize 50000
set heading off
--create view pta_charged_v as
--select
--	unique
--	a.acct_string
--	,p.pta
--  from accounts_str_gm_v a
--	,(
--	select
--		account
--	  from hostdb.host_charged hc
--	 where journal > ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--	union
--	select
--		account
--	  from hostdb.who_charged wc
--	 where journal > ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--	) c
--	,hostdb.pta_status p
-- where a.acct_string=p.pta(+)
--   and a.id=c.account
--/

--create view pta_charged_withflag_v
--as
--select
--	unique
--	a.acct_string
--	,p.pta
--	--,nvl(c.account_flag, 'Valid') flag
--	,decode(c.account_flag, null, 1, 'b', 2,'l',2,'L',2,'i',100,1000) flag
--	,(select trunc(post_date) from hostdb.journals where id=last_jnl) last_postdate
--	,p.proj_name
--	,(select 
--		u.full_name
--		||'('||u.user_name||')'
--	    from hostdb.acl_users u
--		,hostdb.acl_projects prj
--	   where u.employee_id=prj.employee_id
--	     and p.project_id=prj.project_id
--	     and prj.project_role like '%Investigator%'
--	     and rownum<2
--	) PI
--	,(select 
--		u.full_name
--		||'('||u.user_name||')'
--	    from hostdb.acl_users u
--		,hostdb.acl_projects prj
--	   where u.employee_id=prj.employee_id
--	     and p.project_id=prj.project_id
--	     and prj.project_role like '%Manager%'
--	     and rownum<2
--	) Manager
--  from accounts_str_gm_v a
--	,(
--	select 
--		unique
--		account
--		,account_flag
--		,max(last_jnl) last_jnl
--	  from 
--			(
--		select
--			unique
--			account
--			,account_flag
--			,max(journal) last_jnl
--		  from hostdb.host_charged hc
--		 where journal > 237 --  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--		 group by account, account_flag
--		union
--		select
--			unique
--			account
--			,account_flag
--			,max(journal) last_jnl
--		  from hostdb.who_charged wc
--		 where journal > 237 --  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--		 group by account, account_flag
--			)
--	group by account, account_flag
--	) c
--	,hostdb.pta_status p
--	--,hostdb.acl_users u
--	--,hostdb.acl_projects prj
-- --where a.acct_string=p.pta(+)
-- where a.acct_string=p.pta
--   and a.id=c.account
--   --and u.employee_id=prj.employee_id
--   --and p.project_id=prj.project_id
--   and a.acct_string not in (select rtrim(pta) from pta_rm)
--order by a.acct_string
--/

spool Charged_NotIn_RM.csv
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
	||',"'||decode(sum(flag), 1, 'Valid', 2, 'Limbo', 3, 'Limbo_and_Valid', sum(flag))||'"'
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
		,case when last_post_wc > last_post_hc then
			last_post_wc
		else
			last_post_hc
		end last_postdate
	  from 
	(
select
	unique
	a.acct_string
	,p.pta
	--,nvl(c.account_flag, 'Valid') flag
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
	,p.proj_name
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
  from accounts_str_gm_v a
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
	,hostdb.pta_status p
	--,hostdb.acl_users u
	--,hostdb.acl_projects prj
 where a.acct_string=p.pta(+)
 --where a.acct_string=p.pta
   and a.id=c.account
   --and u.employee_id=prj.employee_id
   --and p.project_id=prj.project_id
   and a.acct_string not in (select rtrim(pta) from pta_rm)
   --and a.acct_string not in (select rtrim(account_string) from hostdb.report_manager where account_id is not null)
order by a.acct_string
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
-- where flag='Valid'

-- Taking too long to execute
--select 
--	pta
--  from pta_rm
-- where pta not in (	select project||'-'||task||'-'||award 
--		 	  from hostdb.accounts a
--				,(
--				select
--					account
--				  from hostdb.host_charged hc
--				 where journal > 237
--					--  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--				union
--				select
--					account
--				  from hostdb.who_charged wc
--				 where journal > 237
--					--  ( select min(id) from hostdb.journals where post_date > to_date('01-JUL-2005', 'DD-MON-YYYY'))
--				) c
--			 where a.id=c.account
--			   and a.project is not null
--		)
--order by pta
--/

--spool foo
--select
--	pta.pta
--	,p.pta
--	,pta.proj_name
--	,( select count(*) 
--		  from hostdb.who_charged wc 
--			--hostdb.accounts a
--		 where wc.journal>237
--		   and account=(select id from hostdb.accounts where project||'-'||task||'-'||award=rtrim(p.pta))
--	) UserCharged
--	,( select count(*) 
--		  from hostdb.host_charged 
--		 where journal>237
--		   and account=(select id from hostdb.accounts where project||'-'||task||'-'||award=rtrim(p.pta)) 
--	) HostCharged
--  from hostdb.pta_status pta
--	,pta_rm p
-- where p.pta=pta.pta(+)
--/
--
--spool off
set linesize 80
set heading on
set termout on
