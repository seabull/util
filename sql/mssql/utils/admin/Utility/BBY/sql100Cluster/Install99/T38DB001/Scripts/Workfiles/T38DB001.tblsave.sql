/******************************************************************************/
/* Server SQL DBA System Support Database                                     */
/* SQL Server 'T38DB001' DATABASE                                             */
/*----------------------------------------------------------------------------*/
/* Created July 22, 2008 by Michael Royzman                                   */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/Workfiles/T38DB001.tblsave.svl  $
** $Date: 2011/02/08 17:10:25 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.tblsave.sql  $, $Revision: 1.1 $'
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

/****** Object:  Table [dbo].[T38save_os_wait_stats]    ******/

if exists (select * from sys.tables where name = 'T38save_os_wait_stats')
begin
	PRINT 'Droping T38save_os_wait_stats'
	DROP TABLE T38save_os_wait_stats
end
PRINT 'Creating table T38save_os_wait_stats'
CREATE TABLE T38save_os_wait_stats (
	[os_wait_stats_id]	int identity (1,1) PRIMARY KEY,
	[run_ts] datetime NOT NULL,
	[wait_type] nvarchar(60) NOT NULL,
	[waiting_tasks_count] bigint NOT NULL,
	[wait_time_ms] bigint NOT NULL,
	[max_wait_time_ms] bigint NOT NULL,
	[signal_wait_time_ms] bigint NOT NULL
)
go

/****** Object:  Table [dbo].[T38save_db_index_operational_stats]    ******/
if exists (select * from sys.tables where name = 'T38save_db_index_operational_stats')
begin
	PRINT 'Droping T38save_db_index_operational_stats'
	DROP TABLE T38save_db_index_operational_stats
end
PRINT 'Creating table T38save_db_index_operational_stats'
CREATE TABLE [dbo].[T38save_db_index_operational_stats](
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

/****** Object:  Table [dbo].[T38save_index_usage_stats]    ******/
if exists (select * from sys.tables where name = 'T38save_index_usage_stats')
begin
	PRINT 'Droping T38save_index_usage_stats'
	DROP TABLE T38save_index_usage_stats
end
PRINT 'Creating table T38save_index_usage_stats'
CREATE TABLE [dbo].[T38save_index_usage_stats](
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

/****** Object:  Table [dbo].[T38save_io_virtual_file_stats]    ******/

if exists (select * from sys.tables where name = 'T38save_io_virtual_file_stats')
begin
	PRINT 'Droping T38save_io_virtual_file_stats'
	DROP TABLE T38save_io_virtual_file_stats
end
PRINT 'Creating table T38save_io_virtual_file_stats'
CREATE TABLE [dbo].[T38save_io_virtual_file_stats](
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



if exists (select * from sys.tables where name = 'T38save_exec_query_stats_by_cpu')
begin
	PRINT 'Droping T38save_exec_query_stats_by_cpu'
	DROP TABLE T38save_exec_query_stats_by_cpu
end
PRINT 'Creating table T38save_exec_query_stats_by_cpus'

CREATE TABLE [dbo].[T38save_exec_query_stats_by_cpu](
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


if exists (select * from sys.tables where name = 'T38save_exec_query_stats_by_duration')
begin
	PRINT 'Dropping T38save_exec_query_stats_by_duration'
	DROP TABLE T38save_exec_query_stats_by_duration
end
PRINT 'Creating table T38save_exec_query_stats_by_duration'

CREATE TABLE [dbo].[T38save_exec_query_stats_by_duration](
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




if exists (select * from sys.tables where name = 'T38save_exec_query_stats_by_io')
begin
	PRINT 'Dropping T38save_exec_query_stats_by_io'
	DROP TABLE T38save_exec_query_stats_by_io
end
PRINT 'Creating table T38save_exec_query_stats_by_io'


CREATE TABLE [dbo].[T38save_exec_query_stats_by_io](
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


/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.tblsave.sql  $, $Revision: 1.1 $'
go
