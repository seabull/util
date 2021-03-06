-----------------BEGIN: Script to be run at Publisher 'DSD4DBAI\DF01'-----------------
use [MERDB009]
go

exec sp_addsubscription @publication = N'MERDB009-998', @subscriber = N'dst6db\tsq9', @destination_db = N'MERDB009', @subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @subscriber_type = 0, @backupdevicetype=N'disk', @backupdevicename = N'\\dsd4dbai\t38bkp\df01\MERDB009_log.bkp'
exec sp_addpushsubscription_agent @publication = N'MERDB009-998', @subscriber = N'dst6db\tsq9', @subscriber_db = N'MERDB009', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20060324, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

exec sp_addsubscription @publication = N'MERDB009-999', @subscriber = N'dst6db\tsq9', @destination_db = N'MERDB009', @subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @subscriber_type = 0, @backupdevicetype=N'disk', @backupdevicename = N'\\dsd4dbai\t38bkp\df01\MERDB009_log.bkp'
exec sp_addpushsubscription_agent @publication = N'MERDB009-999', @subscriber = N'dst6db\tsq9', @subscriber_db = N'MERDB009', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20060324, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

-----------------END: Script to be run at Publisher 'DSD4DBAI\DF01'-----------------

