/*********************************************************************************/
/* BEST BUY CO, INC.                                                             */
/*********************************************************************************/
/* Modified by $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/NetBackup/Scripts/T38DBnTapeBkp.svl  $
** $Revision: 1.1 $	$Date: 2011/02/08 16:59:20 $
*/

/* Check for correct version of the SQL Server */
if (select @@version) like '%SQL Server for Windows NT 4%'
begin
	RAISERROR('This script is not for SQL Server 4.xx', 10, 127)
end

go
PRINT ''
go

select "
Start of script" = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DBnTapeBkp.sql  $, $Revision: 1.1 $'
go

PRINT ''
PRINT ''
PRINT ''
PRINT '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE master
GO

if @@ERROR <> 0 RAISERROR('Problems in sql script', 10, 127)
go


/*** Start script ***/
BEGIN TRANSACTION
DECLARE @ReturnCode INT 
DECLARE @ScheduleID INT
DECLARE @outfileName varchar(128)
DECLARE @scriptDir varchar(256)
DECLARE @machinename varchar(128)
DECLARE @instsrvname varchar(128)
--DECLARE @cmd nvarchar(4000)
SELECT @ReturnCode = 0     
/****** Object:  JobCategory [Database Engine Tuning Advisor]    Script Date: 03/17/2009 15:12:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END


if serverproperty('IsClustered')= 1
begin
    select @machinename = cast (serverproperty('MachineName') as varchar(128))
    select @instsrvname = cast (serverproperty('Servername')as varchar(128))
    select @scriptDir = '\\' + @machinename + '\t38app80.' + @instsrvname
end
else
	if (select serverproperty('InstanceName')) is not NULL 
	begin
		select @scriptDir = '\\%computername%\t38app80\' + cast (serverproperty('InstanceName') as varchar(128))
	end
	else 
	begin
		select @scriptDir = '\\%computername%\t38app80'
	end

select @outfileName = @scriptDir

PRINT ''
PRINT ''
PRINT '** output File Path  = '+@outfileName + ' **'
PRINT ''

-- Detach Schedule If Exists
SELECT @ScheduleID = s.schedule_id 
FROM msdb..sysjobschedules js join msdb..sysjobs j on js.job_id = j.job_id 
	join msdb..sysschedules s on s.schedule_id = js.schedule_id
WHERE j.name = N'T38DBnTapeBkp' and s.name = N'DBnTape_bkp'

IF @ScheduleID > 0
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_detach_schedule
		@job_name = 'T38DBnTapeBkp',
		@schedule_id = @ScheduleID
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

--Drop Job If Exists
if exists (select name from msdb.dbo.sysjobs where name = N'T38DBnTapeBkp')
begin
 exec @ReturnCode = msdb.dbo.sp_delete_job @job_name = N'T38DBnTapeBkp'
 IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
end

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'T38DBnTapeBkp', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job is the controller for standard nightly Database Backups, it will also request Veritas master servers to pull the data from disk onto tape.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


/****** Object:  Step [T38nxx46-T38bkpdb]    Script Date: 03/17/2009 15:12:15 ******/
select @outfileName = @scriptDir+'\t38log\T38bkpdb\t38DBnTapeBkp.1.out'
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'T38nxx46-T38bkpdb', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'msdb..sp_start_job ''T38Nxx46-T38dbbkp''', 
		@database_name=N'master', 
		@output_file_name=@outfileName , 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

select @outfileName = @scriptDir+'\t38log\T38bkpdb\t38DBnTapeBkp.2.out'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'wait for bkp to complete', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on 
Print ''****  Starting T38DBnTapeBkp_Step_2 SQL Agent Step at ''+cast(getdate() as varchar(22))+'' *****''
declare @JobID uniqueIdentifier, @tapeJobID uniqueIdentifier
declare @secs int
declare @runStat int
declare @scriptStartTime datetime;
declare @jobHistoryID int;
declare @sessionid int;
declare @backupJobName varchar(128);
declare @tapeJobName varchar(128);
declare @otp varchar(2048); 
--declare @tapeJobId int;
declare @tapeRunDate int, @tapeRunTime int;
set @backupJobName = ''T38Nxx46-T38dbbkp''; 
set @tapeJobName = ''T38DBnTapeBkp'';
set @secs  = 0;

--Get Current SessionID
select top 1  @sessionid = session_id  from msdb.dbo.syssessions order by agent_start_date desc

--Get paramaters for backup jobs
SELECT @scriptStartTime = coalesce(run_requested_date,getdate()) 
	   ,@tapeJobID = t1.job_id
	   ,@tapeRunDate = cast(convert(varchar(24), run_requested_date,112) as int) 
	   ,@tapeRunTime = cast(replace(convert(varchar(20), run_requested_date ,108),'':'','''') as int) 
FROM msdb.dbo.sysjobactivity t1 inner join msdb.dbo.sysjobs t2 
	 ON t1.job_id = t2.job_id 
WHERE t2.name =  @tapeJobName 
	  and t1.stop_execution_date is null 
	  and t1.session_id = @sessionid
	
if @scriptStartTime is null
	set @scriptStartTime = getDate();

select @JobID = job_id from msdb.dbo.sysjobs where name = @backupJobName;
print cast(getdate() as varchar(20))+'' - T38DBnTapeBkp started executing at: '' + cast(@scriptStartTime as varchar(20));

waitfor delay ''00:00:05''

--Added a034368 08/13/2009
Print ''''
Print ''---- PARAMETERS ----''
Print ''Session ID: '' +			IsNull(convert(varchar(100), @sessionid),		''NULL'')
Print ''Script Start Time: '' +	IsNull(convert(varchar(100), @scriptStartTime),	''NULL'')
Print ''Backup Valid If Started Later Than: '' + convert(varchar(100), dateadd(minute,-10,@scriptStartTime))
Print @tapeJobName + '' ID: '' +	IsNull(convert(varchar(100), @tapeJobID),		''NULL'')
Print ''Tape Run Date: '' +		IsNull(convert(varchar(100), @tapeRunDate),		''NULL'')
Print ''Tape Run Time: '' +		IsNull(convert(varchar(100), @tapeRunTime),		''NULL'')
Print @backupJobName + '' ID: '' +IsNull(convert(varchar(100), @JobID),			''NULL'')
Print ''''
--

select @otp=
	''---- EXECUTING JOB FOUND ----'' + char(13) +
	''SessionID : ''+coalesce(cast(session_id as varchar(10)),''NULL'')+char(13)+ 
	''JobID : ''+coalesce(cast(job_id as varchar(64)),''NULL'')+char(13)+ 
	''JobHistoryID : ''+coalesce(cast(job_history_id as varchar(64)),''NULL'')+char(13)+ 
	''RunRequestedDate : ''+coalesce(cast(run_requested_date as varchar(22)),''NULL'') + char(13)+ 
	''RunRequestedSource : ''+coalesce(cast(run_requested_source as  varchar(128)),''NULL'')+ char(13)+ 
	''QueuedDate : ''+coalesce(cast(queued_date as varchar(22)),''NULL'') + char(13)+ 
	''StartExecutionDate : ''+coalesce(cast(start_execution_date as varchar(22)),''NULL'')  
	--, @jobHistoryID = job_history_id -- This will only be assigned if we have a completed job for this session.  If the job is executing or hasn''t been executed yet for this session we get a null
from msdb.dbo.sysjobactivity where job_id = @JobID and run_requested_source is not null and stop_execution_date is null and session_id = @sessionid

print coalesce(@otp,''No executing backup job found for JobID: '' + cast(@JobID as varchar(64)));

Print ''''
Print ''******** Begin Waiting Job Completion ***********''

WHILE exists (select job_id from msdb.dbo.sysjobactivity where job_id = @JobID and run_requested_source is not null and stop_execution_date is null and session_id = @sessionid)
BEGIN
	declare @cnt varchar(6);
	select @cnt = cast(count(*) as varchar(6)) from msdb.dbo.sysjobactivity where job_id = @JobID and run_requested_source is not null and stop_execution_date is null and session_id = @sessionid
	print ''Number of currently executing steps for this Job: ''+@cnt;
	waitfor delay ''00:00:30''
	set @secs = @secs + 30
	print ''I have waited for :''+ cast(@secs  as varchar(64)) + '' Second(s)''
END

IF @secs >0
	print ''Job has completed running, checking status''	
ELSE 
	print ''Current execution of backup job was not found''
	
Print ''******** Done Waiting Job Completion ***********''
Print ''''

--DO WE NEED THIS ASSIGNMENT	(removing 10/13/2009 a034368 -- JobHistoryID is not needed)
--select top 1 @runStat = run_status from msdb.dbo.sysjobhistory where instance_id = @jobHistoryID

declare @runDateTime datetime;
select top 1 @otp =
''---- LAST KNOWN JOB EXECUTION ----'' + char(13) +
''InstanceID: ''+ cast(instance_id as varchar(10)) + char(13)+
''JobID: ''+cast(job_id as varchar(46)) + char(13) + 
''StepID: ''+cast( step_id as varchar(10)) + char(13) + 
''StepName: '' + step_name + char(13)+
''Message: ''+ message+char(13)+
''RunStatus: ''+cast( run_status as varchar(10)) + char(13)+
''RunDateTime: ''+cast(convert(datetime,stuff(stuff(cast(run_date as varchar(8)),5,0,''-''),8,0,''-'')+'' ''+stuff(stuff( Right(stuff(cast(run_time as varchar(6)),1,0,replicate(''0'',6)),6),3,0,'':''),6,0,'':'')) as varchar(22))+char(13)
 , @runDateTime = convert(datetime,stuff(stuff(cast(run_date as varchar(8)),5,0,''-''),8,0,''-'')+'' ''+stuff(stuff( Right(stuff(cast(run_time as varchar(6)),1,0,replicate(''0'',6)),6),3,0,'':''),6,0,'':''))
 , @runStat = run_status --Added a034368 10/13/2009
from msdb.dbo.sysjobhistory where job_id = @JobID and step_id = 0 order by run_date desc, run_time desc;

print ''*******  msdb.dbo.sysjobhistory output ****** ''
print coalesce(@otp,''No Job Outcome Found'')


IF  dateadd(minute,-10,@scriptStartTime) > @runDateTime
BEGIN
	EXEC sp_T38LOGERROR @error_level = 2, @application =''T38DBnTapeBkp_Step2'', @msg = ''The backup job started more than 10 minutes before the start of this script''
END

ELSE IF (@runStat = 0 ) 
BEGIN
	 EXEC sp_T38LOGERROR @error_level = 2, @application =''T38DBnTapeBkp_Step2'', @msg = ''The backup job was detected as failed''
END

ELSE IF (@runStat = 3 ) 
BEGIN
	EXEC sp_T38LOGERROR @error_level = 2, @application =''T38DBnTapeBkp_Step2'', @msg = ''The backup Job was canceled''
END

ELSE
	print ''Job completed without error''',
		@database_name=N'master', 
		@output_file_name=@outfileName , 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Object:  Step [T38n9400-T38initTapeBackup]    Script Date: 03/17/2009 15:12:15 ******/
select @outfileName = @scriptDir+'\t38log\T38bkpdb\t38DBnTapeBkp.3.out'
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'T38n9400-T38initTapeBackup', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'msdb..sp_start_job ''T38N9400-T38InitTapeBackup''', 
		@database_name=N'master', 
		@output_file_name=@outfileName, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

--Reattached Schedule If It Existed, Otherwise Attach Default
IF @ScheduleID > 0
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_attach_schedule 
	@job_name = N'T38DBnTapeBkp', @schedule_id = @ScheduleID
END
ELSE
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBnTape_bkp', @enabled=1, @freq_type=8, @freq_interval=9, @freq_subday_type=1, @freq_subday_interval=0, @freq_relative_interval=0, @freq_recurrence_factor=1, @active_start_date=20001017, @active_end_date=99991231, @active_start_time=30000, @active_end_time=235959

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) 
    ROLLBACK TRANSACTION
EndSave:

/*** End script ***/

PRINT ''
go

select "
End of script" = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DBnTapeBkp.sql  $, $Revision: 1.1 $'
go


