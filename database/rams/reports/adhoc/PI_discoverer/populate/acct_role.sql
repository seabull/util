
insert into /*+ append */ acct_role
(nid, acct_id, emp_num, role)
(
	select
		acctrole_idseq.nextval
		,x.id
		,x.employee_number
		,x.project_role
	  from
	(
	select 
		unique
		 a.id
		, u.employee_number
		, p.project_role
		, rank() over (partition by a.id, u.employee_number order by p.project_role) rnk
	  from hostdb.acl_projects p
		, hostdb.accounts a
		, hostdb.acl_users u
		, hostdb.pta_status pta
	 where
		u.employee_id = p.employee_id
	   and  p.project_id = pta.project_id
	   and  a.project is not null
	   and  pta.pta = a.project||'-'||a.task||'-'||a.award
--	   and rtrim(p.PROJECT_ROLE) not in (
--					'*Business Manager'
--					,'*Clerical Supprt'
--					,'*Supporting Financial Analyst'
--					,'Clerical Support'
--					,'Customer Representative'
--					,'Supporting Financial Analyst'
--					,'Technical/Scientific Support'
--					)
	union
	select
		unique
		a.id
		, u.employee_number
		, 'Business Manager'
		, 1
	  from hostdb.accounts a
		, hostdb.acl_gl_orgs o
		, hostdb.acl_users u
	 where a.project is null
	   and u.employee_id = o.employee_id
	   and a.org = o.gl_org_number
	) x
   where rnk < 2
)
/
