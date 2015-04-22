--
-- print PTAs (charged in FY05 and FY06) and key member info.
--
declare
	cursor pta_csr is
		select
			distinct
			pta.project_number
			,cursor(select pta from hostdb.pta_status pta2 where project_number=pta.project_number order by pta) ptas
			,cursor(select distinct
					--substr(rtrim(u.full_name),1, 32) full_name
					rtrim(u.full_name) full_name
					,rtrim(u.user_name) user_name
					--,substr(rtrim(p.project_role), 1, 30) project_role
					,rtrim(p.project_role) project_role
					,rtrim(pta.proj_name) project_name
			 	  from hostdb.acl_projects p
			 	        , hostdb.acl_users u
				 where pta.PROJECT_ID = p.project_id
				   and p.EMPLOYEE_ID = u.EMPLOYEE_ID
				order by  project_name, full_name, project_role
				) keymem
		from  hostdb.PTA_STATUS pta
		        --, hostdb.accounts a
			--,accounts_str_gm_v a
			,(	select
					distinct
                                        acct_string
					,project
				  from accounts_str_gm_v
				 where id in (  select account from hostdb.who_charged where journal>203
						union
                                		select account from hostdb.host_charged where journal>203
						)
                        ) a
		 where pta.project_number=a.project
		   --and pta.pta(+)=a.acct_string
		   and pta.pta=a.acct_string
		order by 
			project_number
			--pta
			--, project_name, full_name, project_role
			--,drank
		;

	l_project_number	hostdb.pta_status.project_number%type;
	type keymember is record (
		l_full_name		hostdb.acl_users.full_name%type
		,l_user_name		hostdb.acl_users.user_name%type
		,l_project_role		hostdb.acl_projects.project_role%type
		,l_project_name		hostdb.pta_status.proj_name%type
	);
	l_ptas_csr		sys_refcursor;
	l_keymem_csr		sys_refcursor;

	type keymember_t is table of keymember
		index by binary_integer;
	type pta_t is table of hostdb.pta_status.pta%type
		index by binary_integer;

	l_ptas		pta_t;
	l_keymem	keymember_t;
	fd	utl_file.file_type;
begin
	fd := utl_file.fopen('/usr/oracle/debug','pta.log', 'a');
	dbms_output.enable(1000000);
	open pta_csr;

	loop
		fetch pta_csr 
		--into l_project_number, l_ptas_csr, l_user_name, l_full_name, l_project_role, l_project_name
		into l_project_number, l_ptas_csr, l_keymem_csr
		;
		exit when pta_csr%notfound;
		
		-- show 
		--utl_file.put(fd, l_project_number||',,,,,,');
		
		fetch l_ptas_csr bulk collect into l_ptas;
		
		for indx in l_ptas.first .. l_ptas.last
		loop
			utl_file.put_line(fd, l_ptas(indx)||',,,,,');
		end loop;

		--dbms_output.put_line('post pta');
		fetch l_keymem_csr bulk collect into l_keymem;

		for indx in l_keymem.first .. l_keymem.last
		loop
			utl_file.put(fd, l_keymem(indx).l_full_name||',');
			utl_file.put(fd, ','||l_keymem(indx).l_user_name||',');
			utl_file.put(fd, l_keymem(indx).l_project_role||',');
			utl_file.put_line(fd, l_keymem(indx).l_project_name||',');
		end loop;
		-- close l_ptas_csr earlier will cause l_keymem_csr closed.
		if l_ptas_csr%isopen then
			close l_ptas_csr;
		end if;
		if l_keymem_csr%isopen then
			close l_keymem_csr;
		end if;
		--dbms_output.put_line('post keymem');
	end loop;
	utl_file.fflush(fd);
	utl_file.fclose(fd);

	close pta_csr;
exception
	when others then
		dbms_output.put_line('Error '||sqlcode||':'||sqlerrm);
		utl_file.fflush(fd);
		utl_file.fclose(fd);
		close pta_csr;
end;
.
--/
