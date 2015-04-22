USE [msdb]
GO
/*
This is one time run, change the 
@active_start_date, active_start_time to new date and time
*/
if exists (select name from msdb..sysschedules where name = 'PerfTestStop')
begin
	print 'Deleting job schedule'
	exec msdb.dbo.sp_detach_schedule  @job_name=N'PerfTestStop', @schedule_name=N'PerfTestStop'
	exec msdb.dbo.sp_delete_schedule  @schedule_name=N'PerfTestStop'
end
go
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'PerfTestStop', @name=N'PerfTestStop', 
		@enabled=1, 
		@freq_type=1, 
		@freq_interval=1, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20090323, 
		@active_start_time=150000, -- 3:00 pm
		-- @active_start_time=145800, -- 2:58 pm
		@active_end_date=99991231, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
