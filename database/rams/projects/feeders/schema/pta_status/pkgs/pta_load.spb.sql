-- $Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/pkgs/pta_load.spb.sql,v 1.1 2006/04/26 19:32:31 yangl Exp $

create or replace package body hostdb.pta_load as

	procedure pta_status_populate
	is
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter pta_load.pta_status_populate');
		execute immediate 'truncate table pta_status';

		traceit.log(traceit.constDEBUGLEVEL_B, 'enter pta_load.pta_status_populate');
		insert into pta_status
			( pta ,extract_date ,project_id ,proj_name ,project_number
				,proj_start_date ,proj_completion_date
				,proj_closed_date ,proj_status_code ,task_number
				,task_completion_date ,task_charge_flag ,award_number
				,award_name ,award_start_date_active ,award_end_date_active
				,award_closed_date ,award_status
			)
			select	distinct
					pta
					,extract_date
					,l_today
					,constFlagActive
					,project_id
					,proj_name
					,project_number
					,proj_start_date
					,proj_completion_date
					,proj_closed_date
					,proj_status_code
					,task_number
					,task_completion_date
					,task_charge_flag
					,award_number
					,award_name
					,award_start_date_active
					,award_end_date_active
					,award_closed_date
					,award_status
			  --from pta_status p
			  from pta_status_xt p;
		traceit.log(traceit.constDEBUGLEVEL_B, '%s entries inserted into pta_status', SQL%ROWCOUNT);
		
		traceit.log(traceit.constDEBUGLEVEL_B, 'exit pta_load.pta_status_populate');
	end pta_status_populate;

	procedure pta_load is
	begin
		pta_load(false);
	end pta_load;

	procedure pta_load(p_flag IN boolean) is
		l_cnt	pls_integer;
		l_today	date := sysdate;
	begin
		traceit.log(traceit.constDEBUGLEVEL_B, 'enter pta_load.pta_load');

		if (p_flag) then
			l_cnt := 0;
			traceit.log(traceit.constDEBUGLEVEL_A, 'force load.');
		else
			select count(*)
			  into l_cnt
			  from pta_recorded
			 where last_active > trunc(sysdate-1);
			 --where last_active between trunc(sysdate-1) and trunc(sysdate+1);

			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s active entries found.' , l_cnt);
		end if;

		-- Do nothing if the data for today has been loaded.
		if l_cnt < 1 then
			update pta_recorded
			   set flag=constFlagHistory
			 where pta not in (
					select pta
					  from pta_status_xt
					  --from pta_status
					)
			;

			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s entries inactivated in pta_recorded'
					, SQL%ROWCOUNT);

			update pta_recorded
			   set flag=constFlagActive, last_active=trunc(sysdate)
			 where flag=constFlagHistory
			   and pta in (select pta from hostdb.pta_status_xt)
			;
			   --and pta in (select pta from hostdb.pta_status)

			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s entries updated in pta_recorded'
					, SQL%ROWCOUNT);

			/*
			merge into pta_recorded r
				using (select   distinct
						pta
						,extract_date
						,project_id
						,proj_name
						,project_number
						,proj_start_date
						,proj_completion_date
						,proj_closed_date
						,proj_status_code
						,task_number	
						,task_completion_date
						,task_charge_flag
						,award_number
						,award_name
						,award_start_date_active
						,award_end_date_active
						,award_closed_date
						,award_status
					 from pta_status p
					where pta not in (select pta from hostdb.pta_recorded where flag='A')
				) x
			on (r.pta = x.pta)
			when matched then
				update set r.flag=constFlagActive, r.last_active=trunc(x.extract_date)
			when not matched then
				insert ( 
					--id
					pta
					,last_active
					,creation_date
					,project_id
					,proj_name
					,project_number
					,proj_start_date
					,proj_completion_date
					,proj_closed_date
					,proj_status_code
					,task_number	
					,task_completion_date
					,task_charge_flag
					,award_number
					,award_name
					,award_start_date_active
					,award_end_date_active
					,award_closed_date
					,award_status
					)
				--values (ptarecorded_id_seq.nextval
				values (
					x.pta
					,x.extract_date
					,sysdate
					,x.project_id
					,x.proj_name
					,x.project_number
					,x.proj_start_date
					,x.proj_completion_date
					,x.proj_closed_date
					,x.proj_status_code
					,x.task_number	
					,x.task_completion_date
					,x.task_charge_flag
					,x.award_number
					,x.award_name
					,x.award_start_date_active
					,x.award_end_date_active
					,x.award_closed_date
					,x.award_status
					)
			;
			*/
			insert into pta_recorded
				(
					pta
					,last_active
					,creation_date
					,flag
					,project_id
					,proj_name
					,project_number
					,proj_start_date
					,proj_completion_date
					,proj_closed_date
					,proj_status_code
					,task_number
					,task_completion_date
					,task_charge_flag
					,award_number
					,award_name
					,award_start_date_active
					,award_end_date_active
					,award_closed_date
					,award_status
					)
			select	distinct
					pta
					,extract_date
					,l_today
					,constFlagActive
					,project_id
					,proj_name
					,project_number
					,proj_start_date
					,proj_completion_date
					,proj_closed_date
					,proj_status_code
					,task_number
					,task_completion_date
					,task_charge_flag
					,award_number
					,award_name
					,award_start_date_active
					,award_end_date_active
					,award_closed_date
					,award_status
			  --from pta_status p
			  from pta_status_xt p
			 where pta not in (select pta from hostdb.pta_recorded)
			;
			
			traceit.log(traceit.constDEBUGLEVEL_A
					, '%s new entries inserted in pta_recorded'
					, SQL%ROWCOUNT);

		else
			traceit.log(traceit.constDEBUGLEVEL_A, '%s entries already in pta_recorded. No load.', l_cnt);
		end if;

		traceit.log(traceit.constDEBUGLEVEL_B, 'exit pta_load.pta_load');
	end pta_load;

end pta_load;
/
show error
