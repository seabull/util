/*********************************************************************************/
/* BEST BUY CO, INC.                                                             */
/*********************************************************************************/
/* Modified by $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/BackupAndRecovery/Scripts/T38SelectedDBFullBkp.svl  $
** $Revision: 1.1 $	$Date: 2011/02/08 16:59:20 $
*/

/* Check for correct version of the SQL Server */
IF ( SELECT @@version) LIKE '%SQL Server for Windows NT 4%'
BEGIN
	RAISERROR('This script is not for SQL Server 4.xx', 10, 127)
END
GO
PRINT ''
GO

SELECT "Start of script" = convert(varchar(8), getdate(), 1) + 
		' ' + convert(varchar(8), getdate(), 8) + 
		': $Workfile:   T38SelectedDBFullBkp.sql  $, $Revision: 1.1 $'
GO

PRINT ''
PRINT ''
PRINT ''
PRINT '<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE master
GO

IF @@ERROR <> 0 RAISERROR('Problems in sql script', 10, 127)
GO

/*** Start script ***/

BEGIN TRANSACTION
	DECLARE @JobId BINARY(16)  
	DECLARE @ReturnCode INT    
	SELECT @ReturnCode = 0     
	IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = N'Database Maintenance') < 1 
	  EXECUTE msdb.dbo.sp_add_category @name = N'Database Maintenance'

	-- Delete the job with the same name (IF it exists)
	SELECT @JobId = job_id FROM   msdb.dbo.sysjobs WHERE (name = N'T38SelectedDBFullBkp')       
	 
	IF (@JobId IS NOT NULL)    
	  BEGIN  
		-- Check IF the job is a multi-server job  
		IF (EXISTS (SELECT  * 
				  FROM    msdb.dbo.sysjobservers 
				  WHERE   (job_id = @JobId) AND (server_id <> 0))) 
		BEGIN 
		-- There is, so abort the script 
		RAISERROR (N'Unable to import job ''T38SelectedDBFullBkp'' since there is already a multi-server job with this name.', 16, 1) 
		GOTO QuitWithRollback  
		END 
		ELSE 
		-- Delete the [local] job 
		EXECUTE msdb.dbo.sp_delete_job @job_name = N'T38SelectedDBFullBkp' 
		SELECT @JobId = NULL
	END 
	
	BEGIN
		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'T38SelectedDBFullBkp', 
			@enabled=0, 
			@notify_level_eventlog=2, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Takes full backup of some databases i.e. backup of databases that are not in the exclude list and system databases. Configuration File used: T38SelectedDBFullBkp.cfg. Dependency: Need to be run xxx minutes before the differential tape backup job. Schedule should be same as the differential tape backup job.', 
			@category_name=N'Database Maintenance', 
			@owner_login_name=N'sa',
			@job_id = @JobId OUTPUT
			
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	
		-- Add the job steps
		DECLARE @runcmd	varchar(256), 
				@scriptDir	varchar(256),
				@serverOpt	varchar(256),
				@machinename	varchar(128),
				@instsrvname	varchar(128)

		IF SERVERPROPERTY('IsClustered')= 1
		BEGIN
			SELECT @machinename = CAST (SERVERPROPERTY('MachineName') as varchar(128))
			SELECT @instsrvname = CAST (SERVERPROPERTY('Servername')as varchar(128))
			SELECT @scriptDir = '\\' + @machinename + '\t38app80.' + @instsrvname
			SELECT @serverOpt = ' -S ' + @instsrvname + ' -c '+ @scriptDir + '\T38SelectedDBFullBkp.cfg' + ' -b db '
		END
		ELSE
		  IF (SELECT SERVERPROPERTY('InstanceName')) is not NULL 
		  BEGIN
			SELECT @scriptDir = '\\%computername%\t38app80\' + CAST (SERVERPROPERTY('InstanceName') as varchar(128))
			SELECT @serverOpt = ' -S .\' + CAST (SERVERPROPERTY('InstanceName') as varchar(128)) + ' -c '+ @scriptDir + '\T38SelectedDBFullBkp.cfg' + ' -b db '
		  END
		  ELSE 
		  BEGIN
			SELECT @scriptDir = '\\%computername%\t38app80'
			SELECT @serverOpt = ' -c '+ @scriptDir + '\T38SelectedDBFullBkp.cfg' + ' -b db '
		  END
		
		SELECT @runcmd = 'cmd /C perl ' + @scriptDir + '\T38bkp.pl' + @serverOpt
			
		
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				@job_id=@JobId,
				@step_name=N'selected_db_bkp', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=3, 
				@retry_interval=5, 
				@os_run_priority=0,
				@subsystem=N'CmdExec', 
				@command=@runcmd, 
				@flags=0
				
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		
		EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
				@job_id=@JobId,
				@name=N'selected_db_bkp', 
				@enabled=0, 
				@freq_type=8, 
				@freq_interval=118, 
				@freq_subday_type=1, 
				@freq_subday_interval=0, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=1, 
				@active_start_date=20001017, 
				@active_end_date=99991231, 
				@active_start_time=23000, 
				@active_end_time=235959

		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
/*** End script ***/

PRINT ''
GO
SELECT "End of script" = convert(varchar(8), getdate(), 1) + ' ' 
		+ convert(varchar(8), getdate(), 8) + ': $Workfile:   T38SelectedDBFullBkp.sql  $, $Revision: 1.1 $'
GO