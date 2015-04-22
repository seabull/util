
insert into investigator
(nid,emp_num, princ, name)
(
	select
		pi_idseq.nextval
		,x.employee_number
		,x.princ
		,x.full_name
	  from 
	(	select
			unique
			u.employee_number
			,nvl(princ, 'unknown') princ
			,rtrim(u.full_name) full_name
		  from 
			hostdb.acl_projects p
			,hostdb.acl_users u
			,hostdb.name n
		 where
			p.employee_id = u.employee_id
		   and 
			(
				n.emp_num = u.employee_number
				or upper(n.name) = upper(u.full_name)
				or upper(n.name) = u.first_name||' '||u.last_name
			)
		   and n.pri=0
		   and rtrim(p.PROJECT_ROLE) not in (
						'*Business Manager'
						,'*Clerical Supprt'
						,'*Supporting Financial Analyst'
						,'Clerical Support'
						,'Customer Representative'
						,'Supporting Financial Analyst'
						,'Technical/Scientific Support'
						)
	) x
)
/

/*
insert into 
	ramsreport.investigator
(emp_num, princ, name)
values
('00000', 'kzm', 'Kelly Mullins')
/
*/
