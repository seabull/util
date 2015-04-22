USE [msdb]
GO
/*
This is one time run, change the 
@active_start_date, active_start_time to new date and time
*/
if exists (select name from msdb..sysschedules where name = 'PerfTestStart')
begin
	print 'Deleting job schedule'
	exec msdb.dbo.sp_detach_schedule  @job_name=N'PerfTestStart', @schedule_name=N'PerfTestStart'
	exec msdb.dbo.sp_delete_schedule  @schedule_name=N'PerfTestStart'
end
go
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'PerfTestStart', @name=N'PerfTestStart', 
		@enabled=1, 
		@freq_type=1, 
		@freq_interval=1, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20090326, -- Change data 
		@active_start_time=133000, -- 13:30
		-- @active_start_time=095800, -- 9:58 am
		@active_end_date=99991231, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
