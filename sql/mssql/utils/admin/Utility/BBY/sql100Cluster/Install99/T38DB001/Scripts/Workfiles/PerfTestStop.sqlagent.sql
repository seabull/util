/*********************************************************************************/
/* BEST BUY CO, INC.                                                             */
/*********************************************************************************/
/* Modified by $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/Workfiles/PerfTestStop.sqlagent.svl  $
** $Revision: 1.1 $	$Date: 2011/02/08 17:10:24 $
*/

go
PRINT ''
go

select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   PerfTestStop.sqlagent.sql  $, $Revision: 1.1 $'
go

USE [msdb]
GO
/****** Object:  Job [PerfTestStop]    Script Date: 09/29/2006 10:36:53 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'PerfTestStop')
EXEC msdb.dbo.sp_delete_job @job_name=N'PerfTestStop', @delete_unused_schedule=1
USE [msdb]
GO
/****** Object:  Job [PerfTestStop]    Script Date: 09/29/2006 10:36:33 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/29/2006 10:36:33 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PerfTestStop', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
  		@description = N'This job runs activities after Performance test finished.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy Files]    Script Date: 09/29/2006 10:36:33 ******/

declare 
	@runcmd			nvarchar(max), 
	@scriptDir		nvarchar(256),
	@outfilename	nvarchar(256),
	@t38app80share	nvarchar(256),
	@t38app80path	nvarchar(256),
	@machinename	varchar(128),
	@instname		varchar(128),
	@instsrvname	varchar(128)

set @t38app80share = N't38app80'
select @machinename = cast (serverproperty('MachineName') as varchar(128))
select @instsrvname = cast (serverproperty('Servername')as varchar(128))
select @instname = cast (serverproperty('InstanceName') as varchar(128))

if serverproperty('IsClustered')= 1
begin
	select @scriptDir = N'\\' + @machinename + '\t38app80.' + @instsrvname
	set @t38app80share = N't38app80.' + @machinename
end
else
if (select serverproperty('InstanceName')) is not NULL 
begin
	select @scriptDir = N'\\%computername%\t38app80\' + cast (serverproperty('InstanceName') as varchar(128))
end
else 
begin
	select @scriptDir = N'\\%computername%\t38app80'
end

set @runcmd = N'exec msdb..sp_start_job @job_name = ''t38trcstdstop''
exec T38DB001.dbo.USP_INS_db_index_operational_stats
INSERT INTO [T38DB001].[dbo].[T38save_db_index_operational_stats]
           ([run_ts]
           ,[database_name]
           ,[object_name]
           ,[index_name]
           ,[database_id]
           ,[object_id]
           ,[index_id]
           ,[partition_number]
           ,[leaf_insert_count]
           ,[leaf_delete_count]
           ,[leaf_update_count]
           ,[leaf_ghost_count]
           ,[nonleaf_insert_count]
           ,[nonleaf_delete_count]
           ,[nonleaf_update_count]
           ,[leaf_allocation_count]
           ,[nonleaf_allocation_count]
           ,[leaf_page_merge_count]
           ,[nonleaf_page_merge_count]
           ,[range_scan_count]
           ,[singleton_lookup_count]
           ,[forwarded_fetch_count]
           ,[lob_fetch_in_pages]
           ,[lob_fetch_in_bytes]
           ,[lob_orphan_create_count]
           ,[lob_orphan_insert_count]
           ,[row_overflow_fetch_in_pages]
           ,[row_overflow_fetch_in_bytes]
           ,[column_value_push_off_row_count]
           ,[column_value_pull_in_row_count]
           ,[row_lock_count]
           ,[row_lock_wait_count]
           ,[row_lock_wait_in_ms]
           ,[page_lock_count]
           ,[page_lock_wait_count]
           ,[page_lock_wait_in_ms]
           ,[index_lock_promotion_attempt_count]
           ,[index_lock_promotion_count]
           ,[page_latch_wait_count]
           ,[page_latch_wait_in_ms]
           ,[page_io_latch_wait_count]
           ,[page_io_latch_wait_in_ms])
     select
           run_ts
           ,database_name
           ,[object_name]
           ,index_name
           ,database_id
           ,[object_id]
           ,index_id
           ,partition_number
           ,leaf_insert_count
           ,leaf_delete_count
           ,leaf_update_count
           ,leaf_ghost_count
           ,nonleaf_insert_count
           ,nonleaf_delete_count
           ,nonleaf_update_count
           ,leaf_allocation_count
           ,nonleaf_allocation_count
           ,leaf_page_merge_count
           ,nonleaf_page_merge_count
           ,range_scan_count
           ,singleton_lookup_count
           ,forwarded_fetch_count
           ,lob_fetch_in_pages
           ,lob_fetch_in_bytes
           ,lob_orphan_create_count
           ,lob_orphan_insert_count
           ,row_overflow_fetch_in_pages
           ,row_overflow_fetch_in_bytes
           ,column_value_push_off_row_count
           ,column_value_pull_in_row_count
           ,row_lock_count
           ,row_lock_wait_count
           ,row_lock_wait_in_ms
           ,page_lock_count
           ,page_lock_wait_count
           ,page_lock_wait_in_ms
           ,index_lock_promotion_attempt_count
           ,index_lock_promotion_count
           ,page_latch_wait_count
           ,page_latch_wait_in_ms
           ,page_io_latch_wait_count
           ,page_io_latch_wait_in_ms
	from [T38DB001].[dbo].[T38mon_db_index_operational_stats]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_db_index_operational_stats)


exec T38DB001.dbo.USP_INS_exec_query_stats
INSERT INTO [T38DB001].[dbo].[T38save_exec_query_stats_by_cpu]
           ([run_ts]
           ,[avg_cpu]
           ,[query_text]
           ,[dbid]
           ,[dbname]
           ,[objectid]
           ,[query_plan]
	   ,[plan_generation_num]
	   ,[execution_count]
	   ,[last_execution_time]
	   ,[creation_time])
     select
           run_ts
           ,avg_cpu
           ,query_text
           ,dbid
           ,dbname
           ,objectid
           ,query_plan
	   ,plan_generation_num
	   ,execution_count
	   ,last_execution_time
	   ,creation_time
	from [T38DB001].[dbo].[T38mon_exec_query_stats_by_cpu]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_exec_query_stats_by_cpu)

INSERT INTO [T38DB001].[dbo].[T38save_exec_query_stats_by_duration]
           ([run_ts]
           ,[avg_duration]
           ,[query_text]
           ,[dbid]
           ,[dbname]
           ,[objectid]
           ,[query_plan]
	   ,[plan_generation_num]
	   ,[execution_count]
	   ,[last_execution_time]
	   ,[creation_time])
     SELECT
           run_ts
           ,avg_duration
           ,query_text
           ,dbid
           ,dbname
           ,objectid
           ,query_plan
	   ,plan_generation_num
	   ,execution_count
	   ,last_execution_time
	   ,creation_time
	from [T38DB001].[dbo].[T38mon_exec_query_stats_by_duration]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_exec_query_stats_by_duration)

INSERT INTO [T38DB001].[dbo].[T38save_exec_query_stats_by_io]
           ([run_ts]
           ,[avg_io]
           ,[query_text]
           ,[dbid]
           ,[dbname]
           ,[objectid]
           ,[query_plan]
	   ,[plan_generation_num]
	   ,[execution_count]
	   ,[last_execution_time]
	   ,[creation_time])
     SELECT
           run_ts
           ,avg_io
           ,query_text
           ,dbid
           ,dbname
           ,objectid
           ,query_plan
	   ,plan_generation_num
	   ,execution_count
	   ,last_execution_time
	   ,creation_time
	from [T38DB001].[dbo].[T38mon_exec_query_stats_by_io]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_exec_query_stats_by_io)


exec T38DB001.dbo.USP_INS_index_usage_stats
INSERT INTO [T38DB001].[dbo].[T38save_index_usage_stats]
           ([run_ts]
           ,[database_name]
           ,[object_name]
           ,[index_name]
           ,[database_id]
           ,[object_id]
           ,[index_id]
           ,[user_seeks]
           ,[user_scans]
           ,[user_lookups]
           ,[user_updates]
           ,[last_user_seek]
           ,[last_user_scan]
           ,[last_user_lookup]
           ,[last_user_update]
           ,[system_seeks]
           ,[system_scans]
           ,[system_lookups]
           ,[system_updates]
           ,[last_system_seek]
           ,[last_system_scan]
           ,[last_system_lookup]
           ,[last_system_update])
     SELECT
           run_ts
           ,database_name
           ,[object_name]
           ,index_name
           ,database_id
           ,[object_id]
           ,index_id
           ,user_seeks
           ,user_scans
           ,user_lookups
           ,user_updates
           ,last_user_seek
           ,last_user_scan
           ,last_user_lookup
           ,last_user_update
           ,system_seeks
           ,system_scans
           ,system_lookups
           ,system_updates
           ,last_system_seek
           ,last_system_scan
           ,last_system_lookup
           ,last_system_update
	from [T38DB001].[dbo].[T38mon_index_usage_stats]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_index_usage_stats)

exec T38DB001.dbo.USP_INS_io_virtual_file_stats
INSERT INTO [T38DB001].[dbo].[T38save_io_virtual_file_stats]
           ([run_ts]
           ,[database_name]
           ,[logical_name]
           ,[physical_name]
           ,[database_id]
           ,[file_id]
           ,[sample_ms]
           ,[num_of_reads]
           ,[num_of_writes]
           ,[num_of_bytes_read]
           ,[num_of_bytes_written]
           ,[io_stall_read_ms]
           ,[io_stall_write_ms]
           ,[size_on_disk_bytes]
           ,[file_handle])
     SELECT
           run_ts
           ,database_name
           ,logical_name
           ,physical_name
           ,database_id
           ,[file_id]
           ,sample_ms
           ,num_of_reads
           ,num_of_writes
           ,num_of_bytes_read
           ,num_of_bytes_written
           ,io_stall_read_ms
           ,io_stall_write_ms
           ,size_on_disk_bytes
           ,file_handle
	from [T38DB001].[dbo].[T38mon_io_virtual_file_stats]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_io_virtual_file_stats)

exec T38DB001.dbo.USP_INS_os_wait_stats
INSERT INTO [T38DB001].[dbo].[T38save_os_wait_stats]
           ([run_ts]
           ,[wait_type]
           ,[waiting_tasks_count]
           ,[wait_time_ms]
           ,[max_wait_time_ms]
           ,[signal_wait_time_ms])
     SELECT
           run_ts
           ,wait_type
           ,waiting_tasks_count
           ,wait_time_ms
           ,max_wait_time_ms
           ,signal_wait_time_ms
	from [T38DB001].[dbo].[T38mon_os_wait_stats]
	where run_ts = 
	(select max(run_ts) from T38DB001.dbo.T38mon_os_wait_stats)
'

exec master.dbo.sp_T38share2phypath @sharename = @t38app80share, @phy_path = @t38app80path output
set @outfilename = N'' + @t38app80path + '\' + isnull(cast (serverproperty('InstanceName') as varchar(128)), '.') + N'\T38LOG\PerfTestStop.log'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PerfTestStop', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2,
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@runcmd,
		@output_file_name=@outfilename,
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION

GOTO EndSave
QuitWithRollback:
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

/*** End script ***/

PRINT ''
go

select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   PerfTestStop.sqlagent.sql  $, $Revision: 1.1 $'
go
