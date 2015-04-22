if (select object_id ('dbo.Util_innocuous_wait_types', 'V')) is not null
	drop view dbo.Util_innocuous_wait_types
go
if (select object_id ('dbo.Util_dm_os_waiting_tasks_filtered', 'V')) is not null
	drop view dbo.Util_dm_os_waiting_tasks_filtered
go
if (select object_id ('dbo.Util_dm_os_waiting_tasks_filtered2', 'V')) is not null
	drop view dbo.Util_dm_os_waiting_tasks_filtered2
go
if (select object_id ('dbo.Util_dm_os_wait_stats_filtered', 'V')) is not null
	drop view dbo.Util_dm_os_wait_stats_filtered 
go 
if (select object_id ('dbo.Util_current_statements_and_plans', 'V')) is not null
	drop view dbo.Util_current_statements_and_plans
go
if (select object_id ('dbo.Util_head_blockers', 'V')) is not null
	drop view dbo.Util_head_blockers
go
if (select object_id ('dbo.Util_head_blockers_with_directly_blocking_counts', 'V')) is not null
	drop view dbo.Util_head_blockers_with_directly_blocking_counts
go
if (select object_id ('dbo.Util_blocking_chain', 'V')) is not null
	drop view dbo.Util_blocking_chain
go
if (select object_id ('dbo.Util_current_statement', 'FN')) is not null
	drop function dbo.Util_current_statement 
go 
--if exists (select * from sys.schemas where name = 'amalgam')
--	drop schema amalgam
--go
--
--create schema amalgam
--go

create view dbo.Util_innocuous_wait_types 
as 
select 'BAD_PAGE_PROCESS' wait_type 
union 
select 'BROKER_TRANSMITTER' 
union 
select 'CHECKPOINT_QUEUE' 
union 
select 'DBMIRROR_EVENTS_QUEUE' 
union 
select 'LAZYWRITER_SLEEP' 
union 
select 'ONDEMAND_TASK_QUEUE' 
union 
select 'REQUEST_FOR_DEADLOCK_SEARCH' 
union 
select 'LOGMGR_QUEUE' 
union 
select 'KSOURCE_WAKEUP' 
union 
select 'SQLTRACE_BUFFER_FLUSH' 
union 
select 'BROKER_EVENTHANDLER' -- This one needs to be verified 
go

create view dbo.Util_dm_os_waiting_tasks_filtered
as
select * from sys.dm_os_waiting_tasks
where wait_type not in (select * from dbo.Util_innocuous_wait_types)
go

create view dbo.Util_dm_os_waiting_tasks_filtered2
as
select wt.*, 
	l.resource_description as additional_resource_description 
  from dbo.Util_dm_os_waiting_tasks_filtered wt 
left join sys.dm_tran_locks l
	on wt.resource_address = l.lock_owner_address
go

create view dbo.Util_dm_os_wait_stats_filtered as 
select * 
  from sys.dm_os_wait_stats 
 where wait_type not in (select * from dbo.Util_innocuous_wait_types) 
   and waiting_tasks_count <> 0
go

create function dbo.Util_current_statement (
	@dbid int,
	@object_id int,
	@encrypted bit,
	@sqltext text,
	@startoffset int,
	@endoffset int
)
returns nvarchar(4000)
as
begin
    return 	case @encrypted
		when 0 then substring (@sqltext, @startoffset / 2, 
							case @endoffset 
								when -1 then (datalength (@sqltext) - @startoffset) / 2
								when 0 then (datalength (@sqltext) - @startoffset) / 2 + 1
								else (@endoffset - @startoffset) / 2
							end)
			else N'Encrypted: dbid ' + 
				 convert (nvarchar(8), @dbid) + 
				 N' object_id ' + 
				 convert (nvarchar(16), @object_id)
		end
end
go

create view dbo.Util_current_statements_and_plans
as
select	task_address, 
		st.dbid,
		st.objectid,
		st.number,
		st.encrypted,
		dbo.Util_current_statement (
			st.dbid, 
			st.objectid, 
			st.encrypted, 
			st.text, 
			statement_start_offset, 
			statement_end_offset) as [current_stmt],
		case st.encrypted
			when 0 then text
			else N'Encrypted: dbid ' + 
				 convert (nvarchar(8), st.dbid) + 
				 N' object_id ' + 
				 convert (nvarchar(16), st.objectid)
		end as [current_batch],
		query_plan
from sys.dm_exec_requests er
	outer apply sys.dm_exec_sql_text (er.sql_handle) st
	outer apply sys.dm_exec_query_plan (er.plan_handle) qp
go

create view dbo.Util_head_blockers
as
select blocking_task_address as head_blocker_task_address, 
	   blocking_session_id as head_blocker_session_id from sys.dm_os_waiting_tasks where blocking_task_address is not null OR 
	  blocking_session_id is not null
except
select waiting_task_address, session_id
from sys.dm_os_waiting_tasks
where blocking_task_address is not null OR 
	  blocking_session_id is not null
go

create view dbo.Util_head_blockers_with_directly_blocking_counts
as
select  blocking_task_address, 
		blocking_session_id,
		count(*) directly_blocked_tasks
from sys.dm_os_waiting_tasks
where exists (select * 
			  from dbo.Util_head_blockers
			  where (head_blocker_task_address = blocking_task_address OR
						(head_blocker_task_address is null AND	
						 blocking_task_address is null)) AND
					(head_blocker_session_id = blocking_session_id OR
						(head_blocker_session_id is null AND
						 blocking_session_id is null)))
group by blocking_task_address, blocking_session_id
go

create view dbo.Util_blocking_chain
as
WITH BlockingChain (blocking_task_address, blocking_session_id,
					waiting_task_address, waiting_session_id, level,
					head_blocker_task_address, head_blocker_session_id) AS (
	SELECT head_blocker_task_address, head_blocker_session_id,
		   waiting_task_address, session_id, 0, 
		   head_blocker_task_address, head_blocker_session_id
	FROM dbo.Util_head_blockers hb 
    join sys.dm_os_waiting_tasks wt
		  ON (head_blocker_task_address = blocking_task_address OR
					(head_blocker_task_address is null AND	
					 blocking_task_address is null)) AND
				(head_blocker_session_id = blocking_session_id OR
					(head_blocker_session_id is null AND
					 blocking_session_id is null))
	UNION ALL
	SELECT wt.blocking_task_address, wt.blocking_session_id,
		   wt.waiting_task_address, wt.session_id, level + 1,
		   bc.head_blocker_task_address, bc.head_blocker_session_id		  
	FROM sys.dm_os_waiting_tasks wt 
    join BlockingChain bc
		  ON (bc.waiting_task_address = wt.blocking_task_address OR
					(bc.waiting_task_address is null AND	
					 wt.blocking_task_address is null)) AND
				(bc.waiting_session_id = wt.blocking_session_id OR
					(bc.waiting_session_id is null AND
					 wt.blocking_session_id is null))
)
SELECT *
FROM BlockingChain
go
