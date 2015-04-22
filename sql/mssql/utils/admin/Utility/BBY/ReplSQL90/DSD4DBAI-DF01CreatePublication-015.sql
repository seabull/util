-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'MERDB009', @optname = N'publish', @value = N'true'
GO

-- Adding the transactional publication
use [MERDB009]
exec sp_addpublication @publication = N'MERDB009-015', @description = N'Transactional publication of database ''MERDB009'' from Publisher ''DSD4DBAI\DF01''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'true', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO


exec sp_addpublication_snapshot @publication = N'MERDB009-015', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1


use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_assortment', @source_owner = N'dbo', @source_object = N'ix_eia_assortment', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_assortment', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_assortment', @del_cmd = N'CALL sp_MSdel_dboix_eia_assortment', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_assortment'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_assortment_product', @source_owner = N'dbo', @source_object = N'ix_eia_assortment_product', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_assortment_product', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_assortment_product', @del_cmd = N'CALL sp_MSdel_dboix_eia_assortment_product', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_assortment_product'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_cluster', @source_owner = N'dbo', @source_object = N'ix_eia_cluster', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_cluster', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_cluster', @del_cmd = N'CALL sp_MSdel_dboix_eia_cluster', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_cluster'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_cluster_key', @source_owner = N'dbo', @source_object = N'ix_eia_cluster_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_cluster_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_cluster_key', @del_cmd = N'CALL sp_MSdel_dboix_eia_cluster_key', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_cluster_key'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_cluster_product_key', @source_owner = N'dbo', @source_object = N'ix_eia_cluster_product_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_cluster_product_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_cluster_product_key', @del_cmd = N'CALL sp_MSdel_dboix_eia_cluster_product_key', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_cluster_product_key'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_cluster_store', @source_owner = N'dbo', @source_object = N'ix_eia_cluster_store', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_cluster_store', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_cluster_store', @del_cmd = N'CALL sp_MSdel_dboix_eia_cluster_store', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_cluster_store'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_eia_project', @source_owner = N'dbo', @source_object = N'ix_eia_project', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_eia_project', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_eia_project', @del_cmd = N'CALL sp_MSdel_dboix_eia_project', @upd_cmd = N'SCALL sp_MSupd_dboix_eia_project'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_flr_floorplan', @source_owner = N'dbo', @source_object = N'ix_flr_floorplan', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_floorplan', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_floorplan', @del_cmd = N'CALL sp_MSdel_dboix_flr_floorplan', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_floorplan'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_flr_floorplan_key', @source_owner = N'dbo', @source_object = N'ix_flr_floorplan_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_floorplan_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_floorplan_key', @del_cmd = N'CALL sp_MSdel_dboix_flr_floorplan_key', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_floorplan_key'
GO





use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_flr_project', @source_owner = N'dbo', @source_object = N'ix_flr_project', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_project', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_project', @del_cmd = N'CALL sp_MSdel_dboix_flr_project', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_project'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_flr_project_floorplan', @source_owner = N'dbo', @source_object = N'ix_flr_project_floorplan', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_project_floorplan', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_project_floorplan', @del_cmd = N'CALL sp_MSdel_dboix_flr_project_floorplan', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_project_floorplan'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_flr_segment', @source_owner = N'dbo', @source_object = N'ix_flr_segment', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_flr_segment', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_flr_segment', @del_cmd = N'CALL sp_MSdel_dboix_flr_segment', @upd_cmd = N'SCALL sp_MSupd_dboix_flr_segment'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_divider', @source_owner = N'dbo', @source_object = N'ix_spc_divider', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_divider', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_divider', @del_cmd = N'CALL sp_MSdel_dboix_spc_divider', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_divider'
GO





use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_peg', @source_owner = N'dbo', @source_object = N'ix_spc_peg', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_peg', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_peg', @del_cmd = N'CALL sp_MSdel_dboix_spc_peg', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_peg'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_planogram_key', @source_owner = N'dbo', @source_object = N'ix_spc_planogram_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_planogram_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_planogram_key', @del_cmd = N'CALL sp_MSdel_dboix_spc_planogram_key', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_planogram_key'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_point3d', @source_owner = N'dbo', @source_object = N'ix_spc_point3d', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_point3d', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_point3d', @del_cmd = N'CALL sp_MSdel_dboix_spc_point3d', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_point3d'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_product_key', @source_owner = N'dbo', @source_object = N'ix_spc_product_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_product_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_product_key', @del_cmd = N'CALL sp_MSdel_dboix_spc_product_key', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_product_key'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_project', @source_owner = N'dbo', @source_object = N'ix_spc_project', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_project', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_project', @del_cmd = N'CALL sp_MSdel_dboix_spc_project', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_project'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_spc_project_planogram', @source_owner = N'dbo', @source_object = N'ix_spc_project_planogram', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_spc_project_planogram', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_spc_project_planogram', @del_cmd = N'CALL sp_MSdel_dboix_spc_project_planogram', @upd_cmd = N'SCALL sp_MSupd_dboix_spc_project_planogram'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_str_store', @source_owner = N'dbo', @source_object = N'ix_str_store', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_str_store', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_str_store', @del_cmd = N'CALL sp_MSdel_dboix_str_store', @upd_cmd = N'SCALL sp_MSupd_dboix_str_store'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_str_store_floorplan', @source_owner = N'dbo', @source_object = N'ix_str_store_floorplan', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_str_store_floorplan', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_str_store_floorplan', @del_cmd = N'CALL sp_MSdel_dboix_str_store_floorplan', @upd_cmd = N'SCALL sp_MSupd_dboix_str_store_floorplan'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_str_store_key', @source_owner = N'dbo', @source_object = N'ix_str_store_key', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_str_store_key', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_str_store_key', @del_cmd = N'CALL sp_MSdel_dboix_str_store_key', @upd_cmd = N'SCALL sp_MSupd_dboix_str_store_key'
GO





use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_sys_list_data', @source_owner = N'dbo', @source_object = N'ix_sys_list_data', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_sys_list_data', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_sys_list_data', @del_cmd = N'CALL sp_MSdel_dboix_sys_list_data', @upd_cmd = N'SCALL sp_MSupd_dboix_sys_list_data'
GO




use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_sys_list_hdr', @source_owner = N'dbo', @source_object = N'ix_sys_list_hdr', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_sys_list_hdr', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_sys_list_hdr', @del_cmd = N'CALL sp_MSdel_dboix_sys_list_hdr', @upd_cmd = N'SCALL sp_MSupd_dboix_sys_list_hdr'
GO


use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_sys_settings', @source_owner = N'dbo', @source_object = N'ix_sys_settings', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_sys_settings', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_sys_settings', @del_cmd = N'CALL sp_MSdel_dboix_sys_settings', @upd_cmd = N'SCALL sp_MSupd_dboix_sys_settings'
GO


use [MERDB009]
exec sp_addarticle @publication = N'MERDB009-015', @article = N'ix_sys_status', @source_owner = N'dbo', @source_object = N'ix_sys_status', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ix_sys_status', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboix_sys_status', @del_cmd = N'CALL sp_MSdel_dboix_sys_status', @upd_cmd = N'SCALL sp_MSupd_dboix_sys_status'
GO




