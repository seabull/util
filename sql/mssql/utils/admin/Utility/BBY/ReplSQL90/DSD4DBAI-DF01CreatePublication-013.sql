-- Enabling the replication database
--use master
--exec sp_replicationdboption @dbname = N'MERDB009', @optname = N'publish', @value = N'true'
--GO

-- Adding the transactional publication
use [MERDB009]
exec sp_addpublication @publication = N'MERDB009-013', @description = N'Transactional publication of database ''MERDB009'' from Publisher ''DSD4DBAI\DF01''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'true', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO


exec sp_addpublication_snapshot @publication = N'MERDB009-013', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1


use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-013', @article = N'ix_spc_drawing', @source_owner = N'dbo', @source_object = N'ix_spc_drawing', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_drawing', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_drawing', @del_cmd = N'CALL sp_MSdel_dboix_spc_drawing', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_drawing'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-013', @article = N'ix_flr_point3d', @source_owner = N'dbo', @source_object = N'ix_flr_point3d', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_point3d', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_point3d', @del_cmd = N'CALL sp_MSdel_dboix_flr_point3d', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_point3d'
GO

