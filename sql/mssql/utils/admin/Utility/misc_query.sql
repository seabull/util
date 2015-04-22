
exec xp_fixeddrives

exec sp_helptext 'xp_fixeddrives'

exec sp_databases
exec sp_server_info
exec sp_helpdb
exec sp_helpfile
exec sp_helpfilegroup
exec sp_spaceused

SET STATISTICS TIME ON
SET STATISTICS IO ON
SET STATISTICS PROFILE ON
SET STATISTICS XML ON
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_TEXT ON
SET SHOWPLAN_XML ON

SET STATISTICS PROFILE OFF
GO

SET SHOWPLAN_ALL OFF 
GO

select *
  from sys.dm_db_missing_index_group_stats

select *
  from sys.dm_db_missing_index_groups

select *
  from sys.dm_db_missing_index_details

select *
  from sys.dm_db_missing_index_columns

--
-- Alternative to sp_spaceused
--

-- A quick way to monitor server growth is create a table
-- the above columns plus a time stamp and something like:
--
--    insert into DBGrowthTable(dbname, dbsizeMB, unallocMB, reservedMB,
--	  dataMB, unusedDB, getdate())
--        exec sp_msforeachdb 'use ?; INSERT_ENTIRE_SCRIPT_HERE'
--
-- and run it as a job once each night.

use <YOUR DATABASE HERE>
go
set nocount on

declare @dbsize bigint,
 @logsize bigint,
 @reservedpages bigint,
 @usedpages bigint,
 @pages bigint

select @dbsize = sum(convert(bigint, case when status & 64 = 0 then size else 0 end)),
 @logsize = sum(convert(bigint, case when status & 64 <> 0 then size else 0 end))
 from dbo.sysfiles

select @reservedpages = sum(a.total_pages), @usedpages = sum(a.used_pages),
 @pages = sum(
 case
 when it.internal_type IN (202, 204) then 0
 when a.type <> 1 then a.used_pages
 when p.index_id < 2 then a.data_pages
 else 0
 end
 )
 from sys.partitions p join sys.allocation_units a on p.partition_id = a.container_id
 left join sys.internal_tables it on p.object_id = it.object_id

select db_name(), 
  cast(((@dbsize + @logsize) * 8192/1048576.) as decimal(15, 2)) "DB Size(MB)",
  (case when @dbsize >= @reservedpages then cast(((@dbsize - @reservedpages) * 8192/1048567.) as decimal(15, 2)) else 0 end) "Unalloc. Space(MB)",
  cast((@reservedpages * 8192/1048576.) as decimal(15, 2)) "Reserved(MB)",
  cast((@pages * 8192/1048576.) as decimal(15, 2)) "Data Used(MB)",
  cast(((@usedpages - @pages) * 8192/1048576.) as decimal(15, 2)) "Index Used(MB)",
  cast(((@reservedpages - @usedpages) * 8192/1048576.) as decimal(15, 2)) "Unused(MB)"
go

--
-- end of Alternative to sp_spaceused
--



-- find missing indexes
select 
		DB_NAME(database_id), OBJECT_NAME(object_id), equality_columns, inequality_columns
		,included_columns,statement
		,group_handle, unique_compiles, user_seeks, user_scans, last_user_seek, last_user_scan
		,avg_total_user_cost, avg_user_impact, system_seeks,system_scans,last_system_seek, last_system_scan
		,avg_total_system_cost, avg_system_impact, index_group_handle, DDMIG.index_handle
from sys.dm_db_missing_index_group_stats as DDMIGS
inner join sys.dm_db_missing_index_groups as DDMIG
	on DDMIGS.group_handle = DDMIG.index_group_handle
inner join sys.dm_db_missing_index_details as DDMID
	on DDMIG.index_handle = DDMID.index_handle
 where DB_NAME(database_id) = 'PRFDX001'
   and OBJECT_NAME(object_id) = 'FORTvault'
order by (user_seeks * avg_total_user_cost * avg_user_impact)

-- index usage stats
select
iv.table_name,
i.name as index_name,
iv.seeks + iv.scans + iv.lookups as total_accesses,
iv.seeks,
iv.scans,
iv.lookups
from (select
			i.object_id,
			object_name(i.object_id) as table_name,
			i.index_id,
			sum(i.user_seeks) as seeks,
			sum(i.user_scans) as scans,
			sum(i.user_lookups) as lookups
		from sys.tables t
		inner join sys.dm_db_index_usage_stats i
			on t.object_id = i.object_id
		where object_name(i.object_id) = 'FORTvault'
		group by i.object_id,
			i.index_id
	) as iv
inner join sys.indexes i
	on iv.object_id = i.object_id
	and iv.index_id = i.index_id
order by total_accesses desc



select *
  from sys.dm_db_file_space_usage
  from sys.destination_data_spaces
  from sys.filegroups

select *
  from sys.databases
  from sys.data_spaces
  from sys.master_files
select size/128 as sizeMB
		,*
  from sys.database_files

exec sp_helptext 'sp_spaceused'

-- Permission: View Server State
DBCC SQLPERF(LOGSPACE)

SELECT name AS 'File Name' 
	, physical_name AS 'Physical Name'
	, size/128 AS 'Total Size in MB'
	, size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS 'Available Space In MB'
	, *
FROM sys.database_files;

select *
  from sys.databases

--locks held by transactions
SELECT  L.request_session_id AS SPID, 
        DB_NAME(L.resource_database_id) AS DatabaseName,
        O.Name AS LockedObjectName, 
        P.object_id AS LockedObjectId, 
        L.resource_type AS LockedResource, 
        L.request_mode AS LockType,
        ST.text AS SqlStatementText,        
        ES.login_name AS LoginName,
        ES.host_name AS HostName,
        TST.is_user_transaction as IsUserTransaction,
        AT.name as TransactionName,
        CN.auth_scheme as AuthenticationMethod
FROM    sys.dm_tran_locks L
        JOIN sys.partitions P ON P.hobt_id = L.resource_associated_entity_id
        JOIN sys.objects O ON O.object_id = P.object_id
        JOIN sys.dm_exec_sessions ES ON ES.session_id = L.request_session_id
        JOIN sys.dm_tran_session_transactions TST ON ES.session_id = TST.session_id
        JOIN sys.dm_tran_active_transactions AT ON TST.transaction_id = AT.transaction_id
        JOIN sys.dm_exec_connections CN ON CN.session_id = ES.session_id
        CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
WHERE   resource_database_id = db_id()
ORDER BY L.request_session_id

SELECT OSTasks.session_ID, OSThreads.os_thread_id
  FROM sys.dm_os_tasks AS OSTasks
INNER JOIN sys.dm_os_threads AS OSThreads
    ON OSTasks.worker_address = OSThreads.worker_address
WHERE OSTasks.session_ID IS NOT NULL
ORDER BY OSTasks.session_ID;

-- some info about locks
SELECT DISTINCT
SP.SPID,
SP.HOSTPROCESS,
SP.LOGIN_TIME,
SP.LAST_BATCH,
SP.OPEN_TRAN,
SP.STATUS,
SP.HOSTNAME,
SP.PROGRAM_NAME,
SP.CMD,
SP.LOGINAME,
SP.CPU,
SP.MEMUSAGE,
A.RESOURCE_TYPE, A.RESOURCE_SUBTYPE,
A.RESOURCE_ASSOCIATED_ENTITY_ID,
(CASE A.REQUEST_MODE
WHEN 'SCH-S' THEN 'SCHEMA STABILITY'
WHEN 'SCH-M' THEN 'SCHEMA MODIFICATION'
WHEN 'S' THEN 'SHARED'
WHEN 'U' THEN 'UPDATE'
WHEN 'X' THEN 'EXCLUSIVE'
WHEN 'IS' THEN 'Intent Shared'
WHEN 'IU' THEN 'Intent Update'
WHEN 'IX' THEN 'Intent Exclusive'
WHEN 'SIU' THEN 'Shared Intent Update'
WHEN 'SIX' THEN 'Shared Intent Exclusive'
WHEN 'UIX' THEN 'Update Intent Exclusive'
WHEN 'BU' THEN 'Bulk Update'
WHEN 'RangeS_S' THEN 'Shared Key-Range and Shared Resourcelock'
WHEN 'RangeS_U' THEN 'Shared Key-Range and Update Resource lock'
WHEN 'RangeI_N' THEN 'Insert Key-Range and Null Resourcelock'
WHEN 'RangeI_S' THEN 'Key-Range Conversion lock, created by an overlap of RangeI_N and S locks'
WHEN 'RangeI_U' THEN 'Key-Range Conversion lock, created byan overlap of RangeI_N and U locks'
WHEN 'RangeI_X' THEN 'Key-Range Conversion lock, created byan overlap of RangeI_N and X locks'
WHEN 'RangeX_S' THEN 'Key-Range Conversion lock, created byan overlap of RangeI_N and RangeS_S locks'
WHEN 'RangeX_U' THEN 'Key-Range Conversion lock, created byan overlap of RangeI_N and RangeS_U locks'
WHEN 'RangeX_X' THEN 'Exclusive Key-Range and ExclusiveResource lock'
ELSE NULL
END) AS REQUEST_LOCK_MODE,
A.REQUEST_TYPE,
A.REQUEST_STATUS,
A.REQUEST_OWNER_TYPE,
C.NAME,
C.TRANSACTION_BEGIN_TIME,
C.TRANSACTION_TYPE,
C.TRANSACTION_STATE,
C.TRANSACTION_STATUS,
C.TRANSACTION_STATUS2,
C.DTC_STATE,
C.DTC_ISOLATION_LEVEL,
DB_NAME(SP.DBID) DATABASE_NAME
FROM
SYS.DM_TRAN_LOCKS A
INNER JOIN SYS.SYSPROCESSES SP
ON A.REQUEST_SESSION_ID = SP.SPID
LEFT OUTER JOIN SYS.DM_EXEC_REQUESTS B
ON A.REQUEST_REQUEST_ID = B.REQUEST_ID
LEFT OUTER JOIN SYS.DM_TRAN_ACTIVE_TRANSACTIONS C
ON A.REQUEST_OWNER_ID = C.TRANSACTION_ID
WHERE SP.SPID > 50 /*REMOVING THE SYSTEM SPIDS*/
AND SP.PROGRAM_NAME NOT LIKE 'SQLAGENT%'
ORDER BY SPID


-- check snapshot isolation flag
select sys.databases.snapshot_isolation_state
 ,sys.databases.snapshot_isolation_state_desc
 from sys.databases
 where (sys.databases.[name] = '<MyDatabase>')

-- How to check whether read committed transactions use snapshots:
select sys.databases.is_read_committed_snapshot_on
 from sys.databases
 where (sys.databases.[name] = '<MyDatabase>')

SELECT a.[name] as 'Table',
  b.[name] as 'Column',
  c.[name] as 'Datatype',
  b.[length] as 'Length',
  CASE
   WHEN b.[cdefault] > 0 THEN d.[text]
   ELSE NULL
  END as 'Default',
  CASE
   WHEN b.[isnullable] = 0 THEN 'No'
   ELSE 'Yes'
  END as 'Nullable'
FROM  sysobjects a
INNER JOIN syscolumns b
ON  a.[id] = b.[id]
INNER JOIN systypes c
ON  b.[xtype] = c.[xtype]
LEFT JOIN syscomments d
ON  b.[cdefault] = d.[id]
WHERE a.[xtype] = 'u'
-- 'u' for user tables, 'v' for views.
and a.[name]='FORTVault'
AND  a.[name] <> 'dtproperties'
ORDER BY a.[name],b.[colorder]


sp_sdidebug      xp_availablemedia    xp_cmdshell
xp_deletemail    xp_dirtree           xp_dropwebtask
xp_dsninfo       xp_enumdsn           xp_enumerrorlogs
xp_enumgroups    xp_enumqueuedtasks   xp_eventlog
xp_findnextmsg   xp_fixeddrives       xp_getfiledetails
xp_getnetname    xp_grantlogin        xp_logevent
xp_loginconfig   xp_logininfo         xp_makewebtask
xp_msver         xp_perfend           xp_perfmonitor
xp_perfsample    xp_perfstart         xp_readerrorlog
xp_readmail      xp_regread           xp_revokelogin
xp_runweb  

sp_OACreate        sp_OADestroy       sp_OAGetErrorInfo   sp_OAGetProperty
sp_OAMethod        sp_OASetProperty   sp_OAStop           sp_sdidebug
xp_availablemedia  xp_cmdshell        xp_deletemail       xp_dirtree
xp_dropwebtask     xp_dsninfo         xp_enumdsn          xp_enumerrorlogs
xp_enumgroups      xp_enumqueuedtasks xp_eventlog         xp_findnextmsg
xp_fixeddrives     xp_getfiledetails  xp_getnetname       xp_grantlogin
xp_logevent        xp_loginconfig     xp_logininfo        xp_regread
xp_perfend         xp_perfmonitor     xp_perfsample       xp_perfstart
xp_readerrorlog    xp_readmail        xp_revokelogin      xp_runwebtask
xp_schedulersignal xp_sendmail        xp_servicecontrol   xp_snmp_getstate
xp_snmp_raisetrap  xp_sprintf         xp_sqlinventory     xp_sqlregister
xp_sqltrace        xp_sscanf          xp_startmail        xp_stopmail
xp_subdirs         xp_unc_to_drive    xp_dirtree 
 
