/*********************************************************************************/
/* BEST BUY CO, INC.                                                             */
/*********************************************************************************/
/* Modified by $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/t38mon-exec_query_stats.sqlagent.svl  $
** $Revision: 1.1 $	$Date: 2011/02/08 17:09:57 $
*/

go
PRINT ''
go

select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   t38mon-exec_query_stats.sqlagent.sql  $, $Revision: 1.1 $'
go

USE [msdb]
GO
/****** Object:  Job [t38mon-exec_query_stats]    Script Date: 09/29/2006 10:36:53 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N't38mon-exec_query_stats')
EXEC msdb.dbo.sp_delete_job @job_name=N't38mon-exec_query_stats', @delete_unused_schedule=1
USE [msdb]
GO
/****** Object:  Job [t38mon-exec_query_stats]    Script Date: 09/29/2006 10:36:33 ******/
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N't38mon-exec_query_stats', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
  		@description = N'This job starts query stats collector.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy Files]    Script Date: 09/29/2006 10:36:33 ******/

declare 
	@runcmd			nvarchar(256), 
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
if (@instname is null) begin
	raiserror('This job does not work on default instance. Review command line for the job', 16, 127) with log
	GOTO QuitWithRollback
end

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

set @runcmd = N'exec T38DB001.dbo.USP_INS_exec_query_stats'

exec master.dbo.sp_T38share2phypath @sharename = @t38app80share, @phy_path = @t38app80path output
set @outfilename = N'' + @t38app80path + '\' + isnull(cast (serverproperty('InstanceName') as varchar(128)), '.') + N'\T38LOG\t38mon-exec_query_stats.log'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N't38mon-exec_query_stats', 
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @jobId, @name = N't38mon-exec_query_stats', 
	@enabled = 1, @freq_type = 4, 
	@active_start_date = 20051126, 
	@active_start_time = 1500, 
	@freq_interval = 1, 
	@freq_subday_type = 1, 
	@freq_subday_interval = 30, 
	@freq_relative_interval = 0, 
	@freq_recurrence_factor = 0, 
	@active_end_date = 99991231, 
	@active_end_time = 235959
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
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   t38mon-exec_query_stats.sqlagent.sql  $, $Revision: 1.1 $'
go
