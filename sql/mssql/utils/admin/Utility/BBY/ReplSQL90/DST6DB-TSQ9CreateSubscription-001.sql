-----------------BEGIN: Script to be run at Publisher 'DSD4DBAI\DF01'-----------------
use [MERDB009]
exec sp_addsubscription @publication = N'MERDB001-001', @subscriber = N'dst6db\tsq9', @destination_db = N'MERDB009', @subscription_type = N'Push', @sync_type = N'replication support only', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'MERDB001-001', @subscriber = N'dst6db\tsq9', @subscriber_db = N'MERDB009', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20060324, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'DSD4DBAI\DF01'-----------------

