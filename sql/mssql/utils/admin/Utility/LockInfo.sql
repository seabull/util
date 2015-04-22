Create view dbo.Util_LockInfo_V
as
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
--ORDER BY L.request_session_id

Create view dbo.Util_LockInfo2_V
as
select  login_name,
        case des.transaction_isolation_level
            when 0 then 'Unspecified' when 1 then 'ReadUncomitted'
            when 2 then 'ReadCommitted' when 3 then 'Repeatable'
            when 4 then 'Serializable' when 5 then 'Snapshot'
        end as transaction_isolation_level,
        request_session_id, resource_type, resource_subtype, request_mode,
        request_type, request_status, request_owner_type,
        case when resource_type = 'object' then object_name(resource_associated_entity_id)
             when resource_type = 'database' then db_name(resource_associated_entity_id)
             when resource_type in ('key','page') then
                                 (select object_name(object_id) from sys.partitions
                                  where hobt_id = resource_associated_entity_id)
             else cast(resource_associated_entity_id as varchar(20))
        end obj_name,
        des.host_name, des.program_name, des.nt_user_name, des.status, des.lock_timeout
from sys.dm_tran_locks dtl
        left outer join sys.dm_exec_sessions des
            on dtl.request_session_id = des.session_id
where request_session_id <> @@spid

-- Table where the most latch contention occurs
select object_schema_name(ddios.object_id) + '.' + object_name(ddios.object_id) as objectName,
        indexes.name, 
		case when is_unique = 1 then 'UNIQUE ' else '' end + indexes.type_desc as index_type,
        page_latch_wait_count , page_io_latch_wait_count
from  sys.dm_db_index_operational_stats(db_id(),null,null,null) as ddios
             join sys.indexes
                        on indexes.object_id = ddios.object_id
                             and indexes.index_id = ddios.index_id
order by page_latch_wait_count + page_io_latch_wait_count desc


-- Simple query to return all records and all columns
SELECT *
FROM master.sys.dm_tran_locks;
GO

-- Focused result set
SELECT resource_type, request_session_id, resource_database_id, resource_associated_entity_id, resource_subtype, resource_description, request_status, request_owner_type, request_mode
FROM sys.dm_tran_locks;
GO

-- Number of lock records per database
SELECT COUNT(*) AS 'NumberofLockRecords', DB_NAME(resource_database_id)
FROM master.sys.dm_tran_locks
GROUP BY resource_database_id;
GO

-- Query for specific lock types
SELECT resource_type, request_session_id, resource_database_id, resource_associated_entity_id, resource_subtype, resource_description, request_status, request_owner_type, request_mode
FROM sys.dm_tran_locks
WHERE resource_type IN ('PAGE', 'KEY', 'EXTENT', 'RID');
GO

SELECT tl.request_session_id, wt.blocking_session_id, DB_NAME(tl.resource_database_id) AS DatabaseName, tl.resource_type, tl.request_mode, tl.resource_associated_entity_id
FROM sys.dm_tran_locks as tl
INNER JOIN sys.dm_os_waiting_tasks as wt
ON tl.lock_owner_address = wt.resource_address;
GO

SELECT 
        t1.resource_type,
        t1.resource_database_id,
        t1.resource_associated_entity_id,
        t1.request_mode,
        t1.request_session_id,
        t2.blocking_session_id
    FROM sys.dm_tran_locks as t1
    INNER JOIN sys.dm_os_waiting_tasks as t2
        ON t1.lock_owner_address = t2.resource_address;

