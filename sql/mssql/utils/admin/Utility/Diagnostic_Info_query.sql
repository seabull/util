-- SQL Server 2005 Diagnostic Information Queries
-- Glenn Berry 
-- April 2009
-- http://glennberrysqlperformance.spaces.live.com/
-- Twitter: GlennAlanBerry


-- SQL Version information for current instance
SELECT @@VERSION AS [SQL Version Info];

--   SQL 2005 SP2 is now an "unsupported service pack"
--   SQL 2005 SP2 Builds             SQL 2005 SP3 Builds
-- Build       Description        Build       Description
-- 3042        SP2 RTM              4035        SP3 RTM
-- 3161        SP2 CU1              4207        SP3 CU1
-- 3175        SP2 CU2              4211        SP3 CU2 
-- 3186        SP2 CU3              4220        SP3 CU3         
-- 3200        SP2 CU4              4226        SP3 CU4         
-- 3215        SP2 CU5              4230        SP3 CU5          
-- 3228        SP2 CU6              4266        SP3 CU6        
-- 3239        SP2 CU7              4273        SP3 CU7        
-- 3257        SP2 CU8              4285        SP3 CU8
-- 3282        SP2 CU9              4294        SP3 CU9
-- 3294        SP2 CU10
-- 3301        SP2 CU11
-- 3315        SP2 CU12
-- 3325        SP2 CU13
-- 3328        SP2 CU14
-- 3330        SP2 CU15
-- 3355        SP2 CU16
-- 3356        SP2 CU17
 
-- Hardware Information for SQL Server 2005
-- (Cannot distinguish between HT and multi-core)
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)]
FROM sys.dm_os_sys_info;

-- get sp_configure values for instance
EXEC sp_configure 'Show Advanced Options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure;
GO


-- Focus on
-- clr enabled (only enable if you need it)
-- lightweight pooling (should be zero)
-- max degree of parallelism
-- max server memory (MB)
-- priority boost (should be zero)


-- File Names and Paths for TempDB and all user databases in instance 
SELECT DB_NAME([database_id])AS [Database Name], [file_id], 
       name, physical_name, type_desc
FROM sys.master_files
WHERE [database_id] > 4 AND [database_id] <> 32767
OR [database_id] = 2;


-- Things to look at:
-- Are data files and log files on different drives?
-- Is everything on C: drive?
-- Is TempDB on dedicated drives?
-- Are there multiple data files?

-- Recovery model, log reuse wait description, and compatibility level for all databases on instance
SELECT [name], recovery_model_desc, log_reuse_wait_desc, [compatibility_level]
FROM sys.databases;


-- Things to look at
-- How many databases are on the instance?
-- What recovery models are they using?
-- What is the log reuse wait description?
-- What compatibility level are they on?


-- Clear Wait Stats
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'))
SELECT W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold


-- Common Significant Wait types with BOL explanations

-- *** Network Related Waits ***
-- ASYNC_NETWORK_IO        Occurs on network writes when the task is blocked behind the network

-- *** Locking Waits ***
-- LCK_M_IX                Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock
-- LCK_M_IU                Occurs when a task is waiting to acquire an Intent Update (IU) lock
-- LCK_M_S                Occurs when a task is waiting to acquire a Shared lock

-- *** I/O Related Waits ***
-- ASYNC_IO_COMPLETION  Occurs when a task is waiting for I/Os to finish
-- IO_COMPLETION        Occurs while waiting for I/O operations to complete. 
--                      This wait type generally represents non-data page I/Os. Data page I/O completion waits appear 
--                      as PAGEIOLATCH_* waits
-- PAGEIOLATCH_SH        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
-- PAGEIOLATCH_EX        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
-- WRITELOG             Occurs while waiting for a log flush to complete. 
--                      Common operations that cause log flushes are checkpoints and transaction commits.
-- PAGELATCH_EX            Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. 
--                      The latch request is in Exclusive mode.
-- BACKUPIO                Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data

-- *** CPU Related Waits ***
-- SOS_SCHEDULER_YIELD  Occurs when a task voluntarily yields the scheduler for other tasks to execute. 
--                      During this wait the task is waiting for its quantum to be renewed.

-- THREADPOOL            Occurs when a task is waiting for a worker to run on. 
--                      This can indicate that the maximum worker setting is too low, or that batch executions are taking 
--                      unusually long, thus reducing the number of workers available to satisfy other batches.
-- CX_PACKET            Occurs when trying to synchronize the query processor exchange iterator 
--                        You may consider lowering the degree of parallelism if contention on this wait type becomes a problem


-- Signal Waits for instance
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits],
       CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats;


-- Signal Waits above 10-15% is usually a sign of CPU pressure


-- Get CPU Utilization History (SQL 2005 Only)
DECLARE @ts_now bigint; 
SET @ts_now = (SELECT cpu_ticks / CONVERT(float, cpu_ticks_in_ms) FROM sys.dm_os_sys_info); 

SELECT TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
      SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
            AS [SystemIdle], 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
            'int') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE '%<SystemHealth>%') AS x 
      ) AS y 
ORDER BY record_id DESC;



- Page Life Expectancy (PLE) value for default instance
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = 'SQLServer:Buffer Manager' -- Modify this if you have named instances
AND counter_name = 'Page life expectancy';


-- PLE is a good measurement of memory pressure
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value


-- Buffer Pool Usage for instance
SELECT TOP(20) [type], SUM(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks 
GROUP BY [type]  
ORDER BY SUM(single_pages_kb) DESC;


-- CACHESTORE_SQLCP  SQL Plans         - These are cached SQL statements or batches that aren't in 
--                                     stored procedures, functions and triggers
-- CACHESTORE_OBJCP  Object Plans      - These are compiled plans for stored procedures, 
--                                     functions and triggers
-- CACHESTORE_PHDR   Algebrizer Trees  - An algebrizer tree is the parsed SQL text that 
--                                     resolves the table and column names



-- Switch to user database *******************
--USE YourDatabaseName;
--GO

-- Individual File Sizes and space available for current database
SELECT name AS [File Name] , physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB]
FROM sys.database_files;


-- Look at how large and how full the files are and where they are located
-- Make sure the transaction log is not full!!


-- Cached SP's By Execution Count (SQL 2005)
SELECT TOP(25) qt.[text] AS [SP Name], qs.execution_count AS [Execution Count],  
qs.execution_count/DATEDIFF(Second, qs.creation_time, GETDATE()) AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
qs.max_logical_reads, qs.max_logical_writes, qs.total_physical_reads, 
DATEDIFF(Minute, qs.creation_time, GetDate()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE qt.[dbid] = DB_ID() -- Filter by current database
ORDER BY qs.execution_count DESC;



-- Cached SP's By Worker Time (SQL 2005) Worker time relates to CPU cost
SELECT TOP(25) qt.[text] AS [SP Name], qs.total_worker_time AS [TotalWorkerTime], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.execution_count AS [Execution Count], 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.creation_time, GETDATE()), 0) AS [Calls/Second],
ISNULL(qs.total_elapsed_time/qs.execution_count, 0) AS [AvgElapsedTime], 
qs.max_logical_reads, qs.max_logical_writes, 
DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE qt.[dbid] = DB_ID() -- Filter by current database
ORDER BY qs.total_worker_time DESC;



-- Cached SP's By Logical Reads (SQL 2005) Logical reads relate to memory pressure
SELECT TOP(25) qt.[text] AS [SP Name], total_logical_reads, qs.max_logical_reads,
total_logical_reads/qs.execution_count AS [AvgLogicalReads], qs.execution_count AS [Execution Count], 
qs.execution_count/DATEDIFF(Second, qs.creation_time, GETDATE()) AS [Calls/Second], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
qs.total_logical_writes,
 qs.max_logical_writes, qs.total_physical_reads, 
DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE qt.[dbid] = DB_ID() -- Filter by current database
ORDER BY total_logical_reads DESC;



-- Possible Bad Indexes (writes > reads)
SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
        user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
        user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC;



-- Missing Indexes for entire instance by Index Advantage
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], migs.last_user_seek, 
mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
ORDER BY index_advantage DESC;


-- Look at last user seek time, number of user seeks to help determine source and importance
-- SQL Server is overly eager to add included columns, so beware


-- Breaks down buffers used by current database by object (table, index) in the buffer cache
SELECT OBJECT_NAME(p.[object_id]) AS [ObjectName], 
p.index_id, COUNT(*)/128 AS [buffer size(MB)],  COUNT(*) AS [buffer_count] 
FROM sys.allocation_units AS a
INNER JOIN sys.dm_os_buffer_descriptors AS b
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p
ON a.container_id = p.hobt_id
WHERE b.database_id = DB_ID()
AND p.[object_id] > 100
GROUP BY p.[object_id], p.index_id
ORDER BY buffer_count DESC;


-- Tells you what tables and indexes are using the most memory in the buffer cache


-- Detect blocking (run multiple times)
SELECT t1.resource_type AS [lock type],DB_NAME(resource_database_id) AS [database],
t1.resource_associated_entity_id AS [blk object],t1.request_mode AS [lock req],                                                                          --- lock requested
t1.request_session_id AS [waiter sid], t2.wait_duration_ms AS [wait time], -- spid of waiter  
(SELECT [text] FROM sys.dm_exec_requests AS r                              -- get sql for waiter
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) 
WHERE r.session_id = t1.request_session_id) AS [waiter_batch],
(SELECT SUBSTRING(qt.[text],r.statement_start_offset/2, 
    (CASE WHEN r.statement_end_offset = -1 
    THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
    ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS qt
WHERE r.session_id = t1.request_session_id) AS [waiter_stmt],    -- statement blocked
t2.blocking_session_id AS [blocker sid],                         -- spid of blocker
(SELECT [text] FROM sys.sysprocesses AS p                        -- get sql for blocker
CROSS APPLY sys.dm_exec_sql_text(p.[sql_handle]) 
WHERE p.spid = t2.blocking_session_id) AS [blocker_stmt]
FROM sys.dm_tran_locks AS t1 
INNER JOIN sys.dm_os_waiting_tasks AS t2
ON t1.lock_owner_address = t2.resource_address;


