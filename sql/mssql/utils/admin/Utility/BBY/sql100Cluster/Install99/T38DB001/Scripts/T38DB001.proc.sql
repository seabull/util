/******************************************************************************/
/* Server SQL DBA System Support Database                                     */
/* SQL Server 'T38DB001' DATABASE                                             */
/*----------------------------------------------------------------------------*/
/* Created July 22, 2008 by Michael Royzman                                   */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.proc.svl  $
** $Date: 2011/02/08 17:09:57 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.proc.sql  $, $Revision: 1.1 $'
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

----------------------------------------
-- USP_INS_db_index_operational_stats --
----------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_db_index_operational_stats') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_db_index_operational_stats'
	drop procedure [dbo].USP_INS_db_index_operational_stats
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_db_index_operational_stats'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_db_index_operational_stats table.
-- =============================================
CREATE PROCEDURE USP_INS_db_index_operational_stats 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_db_index_operational_stats';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [T38DB001].[dbo].[T38mon_db_index_operational_stats]
           ([run_ts]
           ,[database_name]
           ,[object_name]
           ,[index_name]
           ,[database_id]
           ,[object_id]
           ,[index_id]
           ,[partition_number]
           ,[leaf_insert_count]
           ,[leaf_delete_count]
           ,[leaf_update_count]
           ,[leaf_ghost_count]
           ,[nonleaf_insert_count]
           ,[nonleaf_delete_count]
           ,[nonleaf_update_count]
           ,[leaf_allocation_count]
           ,[nonleaf_allocation_count]
           ,[leaf_page_merge_count]
           ,[nonleaf_page_merge_count]
           ,[range_scan_count]
           ,[singleton_lookup_count]
           ,[forwarded_fetch_count]
           ,[lob_fetch_in_pages]
           ,[lob_fetch_in_bytes]
           ,[lob_orphan_create_count]
           ,[lob_orphan_insert_count]
           ,[row_overflow_fetch_in_pages]
           ,[row_overflow_fetch_in_bytes]
           ,[column_value_push_off_row_count]
           ,[column_value_pull_in_row_count]
           ,[row_lock_count]
           ,[row_lock_wait_count]
           ,[row_lock_wait_in_ms]
           ,[page_lock_count]
           ,[page_lock_wait_count]
           ,[page_lock_wait_in_ms]
           ,[index_lock_promotion_attempt_count]
           ,[index_lock_promotion_count]
           ,[page_latch_wait_count]
           ,[page_latch_wait_in_ms]
           ,[page_io_latch_wait_count]
           ,[page_io_latch_wait_in_ms])
	select @run_ts as run_ts
		, db_name(os.database_id) as database_name
		, NULL as object_name 
		, NULL as index_name
		, os.database_id
		, os.object_id
		, os.index_id
		, os.partition_number
		, os.leaf_insert_count
		, os.leaf_delete_count
		, os.leaf_update_count
		, os.leaf_ghost_count
		, os.nonleaf_insert_count
		, os.nonleaf_delete_count
		, os.nonleaf_update_count
		, os.leaf_allocation_count
		, os.nonleaf_allocation_count
		, os.leaf_page_merge_count
		, os.nonleaf_page_merge_count
		, os.range_scan_count
		, os.singleton_lookup_count
		, os.forwarded_fetch_count
		, os.lob_fetch_in_pages
		, os.lob_fetch_in_bytes
		, os.lob_orphan_create_count
		, os.lob_orphan_insert_count
		, os.row_overflow_fetch_in_pages
		, os.row_overflow_fetch_in_bytes
		, os.column_value_push_off_row_count
		, os.column_value_pull_in_row_count
		, os.row_lock_count
		, os.row_lock_wait_count
		, os.row_lock_wait_in_ms
		, os.page_lock_count
		, os.page_lock_wait_count
		, os.page_lock_wait_in_ms
		, os.index_lock_promotion_attempt_count
		, os.index_lock_promotion_count
		, os.page_latch_wait_count
		, os.page_latch_wait_in_ms
		, os.page_io_latch_wait_count
		, os.page_io_latch_wait_in_ms
	from sys.dm_db_index_operational_stats(null, null, null, null) os
	where 
		os.database_id > 4 and (
		os.row_lock_wait_in_ms > 0
		or os.page_lock_wait_in_ms > 0
		or os.index_lock_promotion_attempt_count > 0
		or os.index_lock_promotion_count > 0
		or os.page_latch_wait_in_ms > 0
		or os.page_io_latch_wait_in_ms > 0
	)
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_index_operational_stats'

	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_index_operational_stats parameter in T38CONFIGPARAMETERS table.', 
	 		16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_db_index_operational_stats] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO

----------------------------------------
-- USP_INS_index_usage_stats --
----------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_index_usage_stats') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_index_usage_stats'
	drop procedure [dbo].USP_INS_index_usage_stats
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_index_usage_stats'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_index_usage_stats table.
-- =============================================
CREATE PROCEDURE USP_INS_index_usage_stats 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_index_usage_stats';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [T38DB001].[dbo].[T38mon_index_usage_stats]
           ([run_ts]
           ,[database_name]
           ,[object_name]
           ,[index_name]
           ,[database_id]
           ,[object_id]
           ,[index_id]
           ,[user_seeks]
           ,[user_scans]
           ,[user_lookups]
           ,[user_updates]
           ,[last_user_seek]
           ,[last_user_scan]
           ,[last_user_lookup]
           ,[last_user_update]
           ,[system_seeks]
           ,[system_scans]
           ,[system_lookups]
           ,[system_updates]
           ,[last_system_seek]
           ,[last_system_scan]
           ,[last_system_lookup]
           ,[last_system_update])
	select 
		@run_ts as run_ts
		, db_name(database_id) as database_name
		, NULL as object_name
		, NULL as index_name
		, database_id
		, object_id
		,index_id
		,user_seeks
		,user_scans
		,user_lookups
		,user_updates
		,last_user_seek
		,last_user_scan
		,last_user_lookup
		,last_user_update
		,system_seeks
		,system_scans
		,system_lookups
		,system_updates
		,last_system_seek
		,last_system_scan
		,last_system_lookup
		,last_system_update
	from sys.dm_db_index_usage_stats with (nolock)
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_index_usage_stats'
	
	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_index_usage_stats parameter in T38CONFIGPARAMETERS table.',
			16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_index_usage_stats] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO

-----------------------------------
-- USP_INS_io_virtual_file_stats --
-----------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_io_virtual_file_stats') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_io_virtual_file_stats'
	drop procedure [dbo].USP_INS_io_virtual_file_stats
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_io_virtual_file_stats'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_io_virtual_file_stats table.
-- =============================================
CREATE PROCEDURE USP_INS_io_virtual_file_stats 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_io_virtual_file_stats';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [dbo].[T38mon_io_virtual_file_stats]
			   ([run_ts]
			   ,[database_name]
			   ,[logical_name]
			   ,[physical_name]
			   ,[database_id]
			   ,[file_id]
			   ,[sample_ms]
			   ,[num_of_reads]
			   ,[num_of_writes]
			   ,[num_of_bytes_read]
			   ,[num_of_bytes_written]
			   ,[io_stall_read_ms]
			   ,[io_stall_write_ms]
			   ,[size_on_disk_bytes]
			   ,[file_handle])
	SELECT 	   
		@run_ts as run_ts
      		,db_name(s.[database_id]) as database_name
      		,m.[name] as logical_name
      		,m.[physical_name]
      		,s.[database_id] 
      		,s.[file_id]
      		,s.[sample_ms]
      		,s.[num_of_reads]  
      		,s.[num_of_writes]
      		,s.[num_of_bytes_read] 
      		,s.[num_of_bytes_written]    
      		,s.[io_stall_read_ms]
      		,s.[io_stall_write_ms]
      		,s.[size_on_disk_bytes]
      		,s.[file_handle]
		FROM sys.dm_io_virtual_file_stats(NULL,NULL) s
		JOIN sys.master_files m
      		ON    s.[database_id] = m.[database_id]
      		AND   s.[file_id] = m.[file_id]
		
		set @nhors2keep = NULL;
		select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
		where PARAMETER_NM = 'MAXHOURS2KEEP:T38_virtual_file_stats'
		
		if (@nhors2keep is null )
		begin
			RAISERROR ('Cannot find MAXHOURS2KEEP:T38_virtual_file_stats parameter in T38CONFIGPARAMETERS table.', 
		 		16, -- Severity.
		 		1 -- State.
	 		);
		end
		set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
		execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_io_virtual_file_stats] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO

-----------------------------------
-- USP_INS_os_wait_stats --
-----------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_os_wait_stats') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_os_wait_stats'
	drop procedure [dbo].USP_INS_os_wait_stats
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_os_wait_stats'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_os_wait_stats table.
-- =============================================
CREATE PROCEDURE USP_INS_os_wait_stats 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_os_wait_stats';

BEGIN TRY	
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [T38DB001].[dbo].[T38mon_os_wait_stats]
           ([run_ts]
           ,[wait_type]
           ,[waiting_tasks_count]
           ,[wait_time_ms]
           ,[max_wait_time_ms]
           ,[signal_wait_time_ms])
     select
		@run_ts as run_ts
		,wait_type
		,waiting_tasks_count
		,wait_time_ms
		,max_wait_time_ms
		,signal_wait_time_ms
		from sys.dm_os_wait_stats
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_os_wait_stats'
	
	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_os_wait_stats in T38CONFIGPARAMETERS table.', 
	 		16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_os_wait_stats] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO


----------------------------------------
-- USP_INS_exec_query_stats --
----------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_exec_query_stats') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_exec_query_stats'
	drop procedure [dbo].USP_INS_exec_query_stats
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_exec_query_stats'
go

-- ========================================================
-- Author:		a792661-a
-- Create date: 7/24/08
-- Description:	Populate tables:
--					dbo.T38mon_exec_query_stats_by_cpu
--					dbo.T38mon_exec_query_stats_by_duration
--					dbo.T38mon_exec_query_stats_by_io
-- ========================================================
CREATE PROCEDURE [dbo].[USP_INS_exec_query_stats]
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @nrows		int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_exec_query_stats';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	set @nrows = NULL;
	select @nrows  = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'GETNTOPROWS:T38_exec_query_stats'

	if (@nrows is null) set @nrows = 25
	
	-- I/O stats
	insert into [T38DB001].dbo.T38mon_exec_query_stats_by_io
           ([run_ts], 
			[avg_io], 
			[query_text], 
			[dbid], 
			[dbname], 
			[objectid], 
			[query_plan],
			[plan_generation_num],
			[execution_count],
			[last_execution_time],
			[creation_time])
	select top (@nrows)
			@run_ts as run_ts,
			(qs.total_logical_reads + qs.total_logical_writes)/qs.execution_count as [avg io],
			ltrim(substring(qt.text,qs.statement_start_offset/2,
                  (case when qs.statement_end_offset = -1
                     then len(convert(nvarchar(max), qt.text)) * 2
                     else qs.statement_end_offset
					end -qs.statement_start_offset)/2)) as query_text,
			qt.dbid, 
			dbname=db_name(qt.dbid),
			qt.objectid,
			qp.query_plan,
			qs.plan_generation_num as [plan_generation_num],
			qs.execution_count as [execution_count],
			qs.last_execution_time as [last_execution_time],
			qs.creation_time as [creation_time]
	from sys.dm_exec_query_stats qs 
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
	cross apply sys.dm_exec_text_query_plan(qs.plan_handle,qs.statement_start_offset, qs.statement_end_offset) as qp 
	where (qt.dbid is null or qt.dbid not in (32767, 4, 1)) 
	order by  [avg io] desc

	-- CPU stats
	insert into [T38DB001].dbo.T38mon_exec_query_stats_by_cpu
           ([run_ts], 
			[avg_cpu], 
			[query_text], 
			[dbid], 
			[dbname], 
			[objectid], 
			[query_plan],
			[plan_generation_num],
			[execution_count],
			[last_execution_time],
			[creation_time])
	select top (@nrows)
			@run_ts as run_ts,
			 (qs.total_worker_time)/qs.execution_count as [avg cpu],
			 LTRIM(substring(qt.text,qs.statement_start_offset/2,
					  (case when qs.statement_end_offset = -1
						 then len(convert(nvarchar(max), qt.text)) * 2
						 else qs.statement_end_offset
						end -qs.statement_start_offset)/2)) as query_text,
			  qt.dbid, 
			  dbname=db_name(qt.dbid),
			  qt.objectid,
			  qp.query_plan,
			  qs.plan_generation_num as [plan_generation_num],
			  qs.execution_count as [execution_count],
			  qs.last_execution_time as [last_execution_time],
			  qs.creation_time as [creation_time] 
	from sys.dm_exec_query_stats qs 
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
	cross apply sys.dm_exec_text_query_plan(qs.plan_handle,qs.statement_start_offset, qs.statement_end_offset) as qp 
	where (qt.dbid IS NULL or qt.dbid NOT IN (32767, 4, 1)) 
	order by  [avg cpu] desc

	-- Duration stats
	insert into [T38DB001].dbo.T38mon_exec_query_stats_by_duration
           ([run_ts], 
			[avg_duration], 
			[query_text], 
			[dbid], 
			[dbname], 
			[objectid], 
			[query_plan],
			[plan_generation_num],
			[execution_count],
			[last_execution_time],
			[creation_time])
	select top (@nrows)
			@run_ts as run_ts,
			 (qs.total_elapsed_time)/qs.execution_count as [avg time],
			 LTRIM(substring(qt.text,qs.statement_start_offset/2,
					  (case when qs.statement_end_offset = -1
						 then len(convert(nvarchar(max), qt.text)) * 2
						 else qs.statement_end_offset
						end -qs.statement_start_offset)/2)) as query_text,
			  qt.dbid, 
			  dbname=db_name(qt.dbid),
			  qt.objectid,
			  qp.query_plan,
			  qs.plan_generation_num as [plan_generation_num],
			  qs.execution_count as [execution_count],
			  qs.last_execution_time as [last_execution_time],
			  qs.creation_time as [creation_time]
	from sys.dm_exec_query_stats qs 
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
	cross apply sys.dm_exec_text_query_plan(qs.plan_handle,qs.statement_start_offset, qs.statement_end_offset) as qp 
	where (qt.dbid IS NULL or qt.dbid NOT IN (32767, 4, 1)) 
	order by  [avg time] desc

	-- Age-out statistics data based on a stored parameter	
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_exec_query_stats'
	
	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_exec_query_stats parameter in T38CONFIGPARAMETERS table.', 
	 		16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg

	delete [dbo].[T38mon_exec_query_stats_by_io] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
	delete [dbo].[T38mon_exec_query_stats_by_cpu] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
	delete [dbo].[T38mon_exec_query_stats_by_duration] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;

set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END

GO

/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.proc.sql  $, $Revision: 1.1 $'
go

------------------------------
-- USP_INS_os_waiting_tasks --
------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_os_waiting_tasks') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_os_waiting_tasks'
	drop procedure [dbo].USP_INS_os_waiting_tasks
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_os_waiting_tasks'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_os_waiting_tasks table.
-- =============================================
CREATE PROCEDURE USP_INS_os_waiting_tasks 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_os_waiting_tasks';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [T38DB001].[dbo].[T38mon_os_waiting_tasks]
           ([run_ts]
           ,[waiting_task_address]
           ,[waiting_task_session_id]
           ,[exec_context_id]
           ,[wait_duration_ms]
           ,[wait_type]
           ,[resource_address]
           ,[blocking_task_address]
           ,[blocking_session_id]
           ,[blocking_exec_context_id]
           ,[resource_description]
           ,[session_session_id]
           ,[host_name]
           ,[program_name]
           ,[sql_text]
           ,[dbid]
           ,[objectid]
           ,[login_time]
           ,[host_process_id]
           ,[client_version]
           ,[client_interface_name]
           ,[security_id]
           ,[login_name]
           ,[nt_domain]
           ,[nt_user_name]
           ,[status]
           ,[cpu_time]
           ,[memory_usage]
           ,[total_scheduled_time]
           ,[total_elapsed_time]
           ,[last_request_start_time]
           ,[last_request_end_time]
           ,[reads]
           ,[writes]
           ,[logical_reads]
           ,[text_size]
           ,[transaction_isolation_level]
           ,[row_count]
           ,[prev_error]
           ,[original_security_id]
           ,[original_login_name])
	SELECT  @run_ts, 
			w.waiting_task_address, 
			w.session_id as waiting_task_session_id, 
			w.exec_context_id, 
			w.wait_duration_ms, 
			w.wait_type, 
			w.resource_address, 
			w.blocking_task_address, 
			w.blocking_session_id, 
			w.blocking_exec_context_id, 
			w.resource_description,
			s.session_id as session_session_id, 
			s.host_name, 
			s.program_name, 
			cast (t.text as varchar(512)) as sql_text,
			t.dbid, 
			t.objectid,
			s.login_time, 
			s.host_process_id, 
			s.client_version, 
			s.client_interface_name, 
			s.security_id, 
			s.login_name, 
			s.nt_domain, 
			s.nt_user_name, 
			s.status, 
			s.cpu_time, 
			s.memory_usage, 
			s.total_scheduled_time, 
			s.total_elapsed_time, 
			s.last_request_start_time, 
			s.last_request_end_time, 
			s.reads, 
			s.writes, 
			s.logical_reads, 
			s.text_size,  
			s.transaction_isolation_level, 
			s.row_count, 
			s.prev_error, 
			s.original_security_id, 
			s.original_login_name
	FROM sys.dm_os_waiting_tasks w
	INNER JOIN sys.dm_exec_sessions s ON
					w.session_id  = s.session_id 
	LEFT OUTER JOIN sys.dm_exec_requests r ON
					s.session_id = r.session_id
	OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
	WHERE s.is_user_process = 1
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_os_waiting_tasks'

	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_os_waiting_tasks parameter in T38CONFIGPARAMETERS table.', 
	 		16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_os_waiting_tasks] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO

------------------------------
-- USP_INS_os_schedulers --
------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].USP_INS_os_schedulers') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print 'Dropping old version of dbo.USP_INS_os_schedulers'
	drop procedure [dbo].USP_INS_os_schedulers
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

print 'Creating stored procedure: dbo.USP_INS_os_schedulers'
go

-- =============================================
-- Author:		tsmmxr
-- Create date: 3/27/2006
-- Description:	Populate T38mon_os_schedulers table.
-- =============================================
CREATE PROCEDURE USP_INS_os_schedulers 
AS
BEGIN
	SET NOCOUNT ON;

	declare @run_ts		datetime; set @run_ts = getdate();
	declare @nhors2keep	int;
	declare @msg		varchar(1024);
	declare @procname	sysname; set @procname = 'USP_INS_os_schedulers';

BEGIN TRY
	set @msg = 'Running Collector ' + @procname + ', $Revision: 1.1 $. Current Database is ' + db_name()
	execute sp_T38LOGERROR 3, @procname, @msg
	INSERT INTO [T38DB001].[dbo].[T38mon_os_schedulers]
       ([run_ts]
       ,[scheduler_address]
       ,[parent_node_id]
       ,[scheduler_id]
       ,[cpu_id]
       ,[status]
       ,[is_online]
       ,[is_idle]
       ,[preemptive_switches_count]
       ,[context_switches_count]
       ,[idle_switches_count]
       ,[current_tasks_count]
       ,[runnable_tasks_count]
       ,[current_workers_count]
       ,[active_workers_count]
       ,[work_queue_count]
       ,[pending_disk_io_count]
       ,[load_factor]
       ,[yield_count]
       ,[last_timer_activity]
       ,[failed_to_create_worker]
       ,[active_worker_address]
       ,[memory_object_address]
       ,[task_memory_object_address])
	SELECT 
		@run_ts
		,[scheduler_address]
		,[parent_node_id]
		,[scheduler_id]
		,[cpu_id]
		,[status]
		,[is_online]
		,[is_idle]
		,[preemptive_switches_count]
		,[context_switches_count]
		,[idle_switches_count]
		,[current_tasks_count]
		,[runnable_tasks_count]
		,[current_workers_count]
		,[active_workers_count]
		,[work_queue_count]
		,[pending_disk_io_count]
		,[load_factor]
		,[yield_count]
		,[last_timer_activity]
		,[failed_to_create_worker]
		,[active_worker_address]
		,[memory_object_address]
		,[task_memory_object_address]
	FROM sys.dm_os_schedulers
	set @nhors2keep = NULL;
	select @nhors2keep = cast(PARAMETER_VAL as int) from T38DB001.dbo.T38CONFIGPARAMETERS 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_os_schedulers'

	if (@nhors2keep is null )
	begin
		RAISERROR ('Cannot find MAXHOURS2KEEP:T38_os_schedulers parameter in T38CONFIGPARAMETERS table.', 
	 		16, -- Severity.
	 		1 -- State.
 		);
	end
	set @msg = 'Delete data older than ' + cast(@nhors2keep as varchar(11)) + ' hours'
	execute sp_T38LOGERROR 3, @procname, @msg
	delete [dbo].[T38mon_os_schedulers] where run_ts < dateadd(hour, 0-@nhors2keep, getdate())
END TRY
BEGIN CATCH
	declare @err_no		int; set @err_no = ERROR_NUMBER();
	declare @err_ln		int; set @err_ln = ERROR_LINE();
	declare @err_state	int; set @err_state = ERROR_STATE();
	declare @err_severity int; set @err_severity = ERROR_SEVERITY();
	declare @err_msg	nvarchar(4000); set @err_msg = ERROR_MESSAGE();
	declare @err_proc	nvarchar(126); set @err_proc = ERROR_PROCEDURE();
	set @msg = 'Error ' + cast(@err_no as varchar(11)) + ' at ' + @err_proc + ':' + cast(@err_ln as varchar(11)) + ': ' + @err_msg
	RAISERROR (@msg, @err_severity, @err_state)
END CATCH;
set @msg = 'Done.' 
execute sp_T38LOGERROR 3, @procname, @msg
END
GO

/*** End script ***/
PRINT ''
go
select '
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.proc.sql  $, $Revision: 1.1 $'
go
