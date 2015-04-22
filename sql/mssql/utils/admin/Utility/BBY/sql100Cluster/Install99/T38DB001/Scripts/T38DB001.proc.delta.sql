/******************************************************************************/
/* Server SQL DBA System Support Database                                     */
/* SQL Server 'T38DB001' DATABASE                                             */
/*----------------------------------------------------------------------------*/
/* Created July 22, 2008 by Michael Royzman                                   */
/******************************************************************************/ 

/* $Author: A645276 $
** $Archive:   //uxpvcs2/pvcs/projects/Database/archives/DatabaseSolutions/MSSQL/EnvironmentMonitoring/T38DB001/Scripts/T38DB001.proc.delta.svl  $
** $Date: 2011/02/08 17:09:56 $
** $Revision: 1.1 $
**/

PRINT ''
go
select '
Start of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.proc.delta.sql  $, $Revision: 1.1 $'
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

------------------------------
-- USP_INS_os_waiting_tasks --
------------------------------

ALTER PROCEDURE [dbo].[USP_INS_exec_query_stats]
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
			[query_plan])
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
			qp.query_plan 
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
			[query_plan])
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
			  qp.query_plan 
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
			[query_plan])
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
			  qp.query_plan
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
End of script' = convert(varchar(8), getdate(), 1) + ' ' + convert(varchar(8), getdate(), 8) + ': $Workfile:   T38DB001.proc.delta.sql  $, $Revision: 1.1 $'
go
