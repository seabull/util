/******************************************************************************/
/* Server SQL DBA System Support Database                                     */
/* SQL Server 'T38DB001' DATABASE                                             */
/*----------------------------------------------------------------------------*/
/* Created July 22, 2008 by Michael Royzman                                   */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.tbl.svl  $
** $Date: 2011/02/08 17:09:57 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.tbl.sql  $, $Revision: 1.1 $'
go

/*** Start script ***/

PRINT ''
PRINT ''
PRINT '<<<< T38DB001 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
PRINT ''
USE T38DB001
GO
if @@ERROR <> 0 RAISERROR('Problems in sql script', 21, 127)
go

/****** Object:  Table [dbo].[T38CONFIGPARAMETERS]    ******/

if exists (select * from sys.tables where name = 'T38CONFIGPARAMETERS')
begin
	PRINT 'Droping T38CONFIGPARAMETERS'
	DROP TABLE T38CONFIGPARAMETERS
end
PRINT 'Creating table T38CONFIGPARAMETERS'
CREATE TABLE T38CONFIGPARAMETERS (
	PARAMETER_ID	smallint identity (1,1) PRIMARY KEY,
	PARAMETER_NM	char(64)	not null UNIQUE,
	PARAMETER_VAL	sql_variant	not null,
	PARAMETER_DESC	varchar(256)	null
)
go

/****** Object:  Table [dbo].[T38mon_os_wait_stats]    ******/

if exists (select * from sys.tables where name = 'T38mon_os_wait_stats')
begin
	PRINT 'Droping T38mon_os_wait_stats'
	DROP TABLE T38mon_os_wait_stats
end
PRINT 'Creating table T38mon_os_wait_stats'
CREATE TABLE T38mon_os_wait_stats (
	[os_wait_stats_id]	int identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[wait_type] nvarchar(60) NOT NULL,
	[waiting_tasks_count] bigint NOT NULL,
	[wait_time_ms] bigint NOT NULL,
	[max_wait_time_ms] bigint NOT NULL,
	[signal_wait_time_ms] bigint NOT NULL
)
go

/****** Object:  Table [dbo].[T38mon_db_index_operational_stats]    ******/
if exists (select * from sys.tables where name = 'T38mon_db_index_operational_stats')
begin
	PRINT 'Droping T38mon_db_index_operational_stats'
	DROP TABLE T38mon_db_index_operational_stats
end
PRINT 'Creating table T38mon_db_index_operational_stats'
CREATE TABLE [dbo].[T38mon_db_index_operational_stats](
	[index_operational_stats_id]	bigint identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[database_name] sysname NULL,
	[object_name] sysname NULL,
	[index_name] sysname NULL,
	[database_id] smallint NOT NULL,
	[object_id] int NOT NULL,
	[index_id] int NOT NULL,
	[partition_number] int NOT NULL,
	[leaf_insert_count] bigint NOT NULL,
	[leaf_delete_count] bigint NOT NULL,
	[leaf_update_count] bigint NOT NULL,
	[leaf_ghost_count] bigint NOT NULL,
	[nonleaf_insert_count] bigint NOT NULL,
	[nonleaf_delete_count] bigint NOT NULL,
	[nonleaf_update_count] bigint NOT NULL,
	[leaf_allocation_count] bigint NOT NULL,
	[nonleaf_allocation_count] bigint NOT NULL,
	[leaf_page_merge_count] bigint NOT NULL,
	[nonleaf_page_merge_count] bigint NOT NULL,
	[range_scan_count] bigint NOT NULL,
	[singleton_lookup_count] bigint NOT NULL,
	[forwarded_fetch_count] bigint NOT NULL,
	[lob_fetch_in_pages] bigint NOT NULL,
	[lob_fetch_in_bytes] bigint NOT NULL,
	[lob_orphan_create_count] bigint NOT NULL,
	[lob_orphan_insert_count] bigint NOT NULL,
	[row_overflow_fetch_in_pages] bigint NOT NULL,
	[row_overflow_fetch_in_bytes] bigint NOT NULL,
	[column_value_push_off_row_count] bigint NOT NULL,
	[column_value_pull_in_row_count] bigint NOT NULL,
	[row_lock_count] bigint NOT NULL,
	[row_lock_wait_count] bigint NOT NULL,
	[row_lock_wait_in_ms] bigint NOT NULL,
	[page_lock_count] bigint NOT NULL,
	[page_lock_wait_count] bigint NOT NULL,
	[page_lock_wait_in_ms] bigint NOT NULL,
	[index_lock_promotion_attempt_count] bigint NOT NULL,
	[index_lock_promotion_count] bigint NOT NULL,
	[page_latch_wait_count] bigint NOT NULL,
	[page_latch_wait_in_ms] bigint NOT NULL,
	[page_io_latch_wait_count] bigint NOT NULL,
	[page_io_latch_wait_in_ms] bigint NOT NULL
)


GO

/****** Object:  Table [dbo].[T38mon_index_usage_stats]    ******/
if exists (select * from sys.tables where name = 'T38mon_index_usage_stats')
begin
	PRINT 'Droping T38mon_index_usage_stats'
	DROP TABLE T38mon_index_usage_stats
end
PRINT 'Creating table T38mon_index_usage_stats'
CREATE TABLE [dbo].[T38mon_index_usage_stats](
	[index_usage_stats_id]	bigint identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[database_name] sysname NULL,
	[object_name] sysname NULL,
	[index_name] sysname NULL,
	[database_id] smallint NOT NULL,
	[object_id] int NOT NULL,
	[index_id] int NOT NULL,
	[user_seeks] bigint NOT NULL,
	[user_scans] bigint NOT NULL,
	[user_lookups] bigint NOT NULL,
	[user_updates] bigint NOT NULL,
	[last_user_seek] datetime NULL,
	[last_user_scan] datetime NULL,
	[last_user_lookup] datetime NULL,
	[last_user_update] datetime NULL,
	[system_seeks] bigint NOT NULL,
	[system_scans] bigint NOT NULL,
	[system_lookups] bigint NOT NULL,
	[system_updates] bigint NOT NULL,
	[last_system_seek] datetime NULL,
	[last_system_scan] datetime NULL,
	[last_system_lookup] datetime NULL,
	[last_system_update] datetime NULL
)

GO

/****** Object:  Table [dbo].[T38mon_io_virtual_file_stats]    ******/

if exists (select * from sys.tables where name = 'T38mon_io_virtual_file_stats')
begin
	PRINT 'Droping T38mon_io_virtual_file_stats'
	DROP TABLE T38mon_io_virtual_file_stats
end
PRINT 'Creating table T38mon_io_virtual_file_stats'
CREATE TABLE [dbo].[T38mon_io_virtual_file_stats](
	[file_stats_id]	int identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[database_name] sysname NULL,
	[logical_name] sysname NOT NULL,
	[physical_name] nvarchar(260) NOT NULL,
	[database_id] smallint NOT NULL,
	[file_id] smallint NOT NULL,
	[sample_ms] int NOT NULL,
	[num_of_reads] bigint NOT NULL,
	[num_of_writes] bigint NOT NULL,
	[num_of_bytes_read] bigint NOT NULL,
	[num_of_bytes_written] bigint NOT NULL,
	[io_stall_read_ms] bigint NOT NULL,
	[io_stall_write_ms] bigint NOT NULL,
	[size_on_disk_bytes] bigint NOT NULL,
	[file_handle] varbinary(8) NOT NULL
)

GO



if exists (select * from sys.tables where name = 'T38mon_exec_query_stats_by_cpu')
begin
	PRINT 'Droping T38mon_exec_query_stats_by_cpu'
	DROP TABLE T38mon_exec_query_stats_by_cpu
end
PRINT 'Creating table T38mon_exec_query_stats_by_cpus'

CREATE TABLE [dbo].[T38mon_exec_query_stats_by_cpu](
	[exec_query_stats_by_cpu_id] [int] IDENTITY(1,1) NOT NULL,
	[run_ts] [datetime] NOT NULL,
	[avg_cpu] [bigint] NULL,
	[query_text] [nvarchar](max) NULL,
	[dbid] [smallint] NULL,
	[dbname] [nvarchar](128) NULL,
	[objectid] [int] NULL,
	[query_plan] [nvarchar](max) NULL,
	[plan_generation_num] [bigint] NULL,
	[execution_count] [bigint] NULL, 
	[last_execution_time] [datetime] NULL,
	[creation_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[exec_query_stats_by_cpu_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]
) ON [Group00]

GO


if exists (select * from sys.tables where name = 'T38mon_exec_query_stats_by_duration')
begin
	PRINT 'Dropping T38mon_exec_query_stats_by_duration'
	DROP TABLE T38mon_exec_query_stats_by_duration
end
PRINT 'Creating table T38mon_exec_query_stats_by_duration'

CREATE TABLE [dbo].[T38mon_exec_query_stats_by_duration](
	[exec_query_stats_by_duration_id] [int] IDENTITY(1,1) NOT NULL,
	[run_ts] [datetime] NOT NULL,
	[avg_duration] [bigint] NULL,
	[query_text] [nvarchar](max) NULL,
	[dbid] [smallint] NULL,
	[dbname] [nvarchar](128) NULL,
	[objectid] [int] NULL,
	[query_plan] [nvarchar](max) NULL,
	[plan_generation_num] [bigint] NULL,
	[execution_count] [bigint] NULL, 
	[last_execution_time] [datetime] NULL,
	[creation_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[exec_query_stats_by_duration_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]
) ON [Group00]

GO




if exists (select * from sys.tables where name = 'T38mon_exec_query_stats_by_io')
begin
	PRINT 'Dropping T38mon_exec_query_stats_by_io'
	DROP TABLE T38mon_exec_query_stats_by_io
end
PRINT 'Creating table T38mon_exec_query_stats_by_io'


CREATE TABLE [dbo].[T38mon_exec_query_stats_by_io](
	[exec_query_stats_by_io_id] [int] IDENTITY(1,1) NOT NULL,
	[run_ts] [datetime] NOT NULL,
	[avg_io] [bigint] NULL,
	[query_text] [nvarchar](max) NULL,
	[dbid] [smallint] NULL,
	[dbname] [nvarchar](128) NULL,
	[objectid] [int] NULL,
	[query_plan] [nvarchar](max) NULL,
	[plan_generation_num] [bigint] NULL,
	[execution_count] [bigint] NULL, 
	[last_execution_time] [datetime] NULL,
	[creation_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[exec_query_stats_by_io_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Group00]
) ON [Group00]
GO

if exists (select * from sys.tables where name = 'T38mon_os_waiting_tasks')
begin
	PRINT 'Dropping T38mon_os_waiting_tasks'
	DROP TABLE T38mon_os_waiting_tasks
end
PRINT 'Creating table T38mon_os_waiting_tasks'


CREATE TABLE [dbo].[T38mon_os_waiting_tasks](
	[os_waiting_tasks_id]	int identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[waiting_task_address] [varbinary](8) NOT NULL,	-- sys.dm_os_waiting_tasks w
	[waiting_task_session_id] [smallint] NULL,	-- sys.dm_os_waiting_tasks w
	[exec_context_id] [int] NULL,	-- sys.dm_os_waiting_tasks w
	[wait_duration_ms] [bigint] NULL,	-- sys.dm_os_waiting_tasks w
	[wait_type] [nvarchar](60) NULL,	-- sys.dm_os_waiting_tasks w
	[resource_address] [varbinary](8) NULL,	-- sys.dm_os_waiting_tasks w
	[blocking_task_address] [varbinary](8) NULL,	-- sys.dm_os_waiting_tasks w
	[blocking_session_id] [smallint] NULL,	-- sys.dm_os_waiting_tasks w
	[blocking_exec_context_id] [int] NULL,	-- sys.dm_os_waiting_tasks w
	[resource_description] [nvarchar](1024) NULL,	-- sys.dm_os_waiting_tasks w
	[session_session_id] [smallint] NOT NULL,	-- sys.dm_exec_sessions s
	[host_name] [nvarchar](128) NULL,	-- sys.dm_exec_sessions s
	[program_name] [nvarchar](128) NULL,	-- sys.dm_exec_sessions s
	[sql_text] [varchar](512) NULL,	-- sys.dm_exec_sql_text (r.sql_handle) t
	[dbid] [smallint] NULL,	-- sys.dm_exec_sql_text (r.sql_handle) t
	[objectid] [int] NULL,	-- sys.dm_exec_sql_text (r.sql_handle) t
	[login_time] [datetime] NOT NULL,	-- sys.dm_exec_sessions s
	[host_process_id] [int] NULL,	-- sys.dm_exec_sessions s
	[client_version] [int] NULL,	-- sys.dm_exec_sessions s
	[client_interface_name] [nvarchar](32) NULL,	-- sys.dm_exec_sessions s
	[security_id] [varbinary](85) NOT NULL,	-- sys.dm_exec_sessions s
	[login_name] [nvarchar](128) NOT NULL,	-- sys.dm_exec_sessions s
	[nt_domain] [nvarchar](128) NULL,	-- sys.dm_exec_sessions s
	[nt_user_name] [nvarchar](128) NULL,	-- sys.dm_exec_sessions s
	[status] [nvarchar](30) NOT NULL,	-- sys.dm_exec_sessions s
	[cpu_time] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[memory_usage] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[total_scheduled_time] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[total_elapsed_time] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[last_request_start_time] [datetime] NOT NULL,	-- sys.dm_exec_sessions s
	[last_request_end_time] [datetime] NULL,	-- sys.dm_exec_sessions s
	[reads] [bigint] NOT NULL,	-- sys.dm_exec_sessions s
	[writes] [bigint] NOT NULL,	-- sys.dm_exec_sessions s
	[logical_reads] [bigint] NOT NULL,	-- sys.dm_exec_sessions s
	[text_size] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[transaction_isolation_level] [smallint] NOT NULL,	-- sys.dm_exec_sessions s
	[row_count] [bigint] NOT NULL,	-- sys.dm_exec_sessions s
	[prev_error] [int] NOT NULL,	-- sys.dm_exec_sessions s
	[original_security_id] [varbinary](85) NOT NULL,	-- sys.dm_exec_sessions s
	[original_login_name] [nvarchar](128) NOT NULL	-- sys.dm_exec_sessions s
)
GO

if exists (select * from sys.tables where name = 'T38mon_os_schedulers')
begin
	PRINT 'Dropping T38mon_os_schedulers'
	DROP TABLE [T38mon_os_schedulers]
end
PRINT 'Creating table T38mon_os_schedulers'


GO
CREATE TABLE [dbo].[T38mon_os_schedulers](
	[os_waiting_tasks_id]	int identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[scheduler_address] [varbinary](8) NOT NULL,
	[parent_node_id] [int] NOT NULL,
	[scheduler_id] [int] NOT NULL,
	[cpu_id] [smallint] NOT NULL,
	[status] [nvarchar](60) NOT NULL,
	[is_online] [bit] NOT NULL,
	[is_idle] [bit] NOT NULL,
	[preemptive_switches_count] [int] NOT NULL,
	[context_switches_count] [int] NOT NULL,
	[idle_switches_count] [int] NOT NULL,
	[current_tasks_count] [int] NOT NULL,
	[runnable_tasks_count] [int] NOT NULL,
	[current_workers_count] [int] NOT NULL,
	[active_workers_count] [int] NOT NULL,
	[work_queue_count] [bigint] NOT NULL,
	[pending_disk_io_count] [int] NOT NULL,
	[load_factor] [int] NOT NULL,
	[yield_count] [int] NOT NULL,
	[last_timer_activity] [bigint] NOT NULL,
	[failed_to_create_worker] [bit] NULL,
	[active_worker_address] [varbinary](8) NULL,
	[memory_object_address] [varbinary](8) NOT NULL,
	[task_memory_object_address] [varbinary](8) NOT NULL
)
GO

/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.tbl.sql  $, $Revision: 1.1 $'
go
