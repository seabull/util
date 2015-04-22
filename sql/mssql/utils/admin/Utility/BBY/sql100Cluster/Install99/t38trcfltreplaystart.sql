/*********************************************************************************/
/* BEST BUY CO, INC.                                                             */
/*********************************************************************************/
/* Modified by $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/Applications/Utilities/t38trace/Install99/t38trcfltreplaystart.svl  $
** $Revision: 1.1 $	$Date: 2011/02/08 16:59:24 $
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
Start of script" = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   t38trcfltreplaystart.sql  $, $Revision: 1.1 $'
go


PRINT ''
PRINT ''
PRINT '<<<< master >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE master
GO

if @@ERROR <> 0 RAISERROR('Problems in sql script', 10, 127)
go


/*** Start script ***/

BEGIN TRANSACTION            
  DECLARE @JobID BINARY(16)  
  DECLARE @ReturnCode INT    
  SELECT @ReturnCode = 0     
IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = N'Database Maintenance') < 1 
  EXECUTE msdb.dbo.sp_add_category @name = N'Database Maintenance'

  -- Delete the job with the same name (if it exists)
  SELECT @JobID = job_id     
  FROM   msdb.dbo.sysjobs    
  WHERE (name = N't38trcfltreplaystart')       
  IF (@JobID IS NOT NULL)    
  BEGIN  
  -- Check if the job is a multi-server job  
  IF (EXISTS (SELECT  * 
              FROM    msdb.dbo.sysjobservers 
              WHERE   (job_id = @JobID) AND (server_id <> 0))) 
  BEGIN 
    -- There is, so abort the script 
    RAISERROR (N'Unable to import job ''t38trcfltreplaystart'' since there is already a multi-server job with this name.', 16, 1) 
    GOTO QuitWithRollback  
  END 
  ELSE 
    -- Delete the [local] job 
    EXECUTE msdb.dbo.sp_delete_job @job_name = N't38trcfltreplaystart' 
    SELECT @JobID = NULL
  END 

BEGIN 

  -- Add the job
  EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT , @job_name = N't38trcfltreplaystart', @owner_login_name = N'sa', @description = N'Start Replay SQL 9 trace with custom filter. Stop it with t38trcreplaystop job. $Revision: 1.1 $, $Workfile:   t38trcfltreplaystart.sql  $ ', @category_name = N'Database Maintenance', @enabled = 0, @notify_level_email = 0, @notify_level_page = 0, @notify_level_netsend = 0, @notify_level_eventlog = 2, @delete_level= 0
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the job steps
  declare @runcmd	varchar(256), 
          @scriptDir	varchar(256),
	  @serverOpt	varchar(256),
	  @machinename	varchar(128),
	  @instsrvname	varchar(128)

  if serverproperty('IsClustered')= 1
  begin
      select @machinename = cast (serverproperty('MachineName') as varchar(128))
      select @instsrvname = cast (serverproperty('Servername')as varchar(128))
      select @scriptDir = '\\' + @machinename + '\t38app80.' + @instsrvname
      select @serverOpt = ' -S ' + @instsrvname + ' -f ' + @scriptDir + '\t38filter.cfg' + ' ' + @scriptDir + '\t38trcreplay.cfg'
  end
  else
  if (select serverproperty('InstanceName')) is not NULL 
  begin
	select @scriptDir = '\\%computername%\t38app80\' + cast (serverproperty('InstanceName') as varchar(128))
	select @serverOpt = ' -S .\' + cast (serverproperty('InstanceName') as varchar(128)) + ' -f ' + @scriptDir + '\t38filter.cfg' + ' ' + @scriptDir + '\t38trcreplay.cfg'
  end
  else 
  begin
	select @scriptDir = '\\%computername%\t38app80'
	select @serverOpt = ' -f ' + @scriptDir + '\t38filter.cfg' + ' ' + @scriptDir + '\t38trcreplay.cfg'
  end
  select @runcmd = 'cmd /C perl ' + @scriptDir + '\t38trace.pl -l .replay' + @serverOpt

  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N't38trcfltreplaystart', @command = @runcmd, @database_name = N'', @server = N'', @database_user_name = N'', @subsystem = N'CmdExec', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 1, @on_fail_step_id = 0, @on_fail_action = 2
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
  EXECUTE @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1 

  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the job schedules
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID, @name = N't38trcfltreplaystart', @enabled = 1, @freq_type = 4, @active_start_date = 20001017, @active_start_time = 001500, @freq_interval = 1, @freq_subday_type = 1, @freq_subday_interval = 0, @freq_relative_interval = 0, @freq_recurrence_factor = 0, @active_end_date = 99991231, @active_end_time = 235959
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the Target Servers
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' 
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

END
COMMIT TRANSACTION          
GOTO   EndSave              
QuitWithRollback:
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
EndSave: 


/*** End script ***/

PRINT ''
go

select "
End of script" = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   t38trcfltreplaystart.sql  $, $Revision: 1.1 $'
go
