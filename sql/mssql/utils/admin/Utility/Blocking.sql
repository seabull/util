BEGIN TRAN

--============================================
--View Blocking in Current Database
--============================================ 
SELECT DTL.resource_type, 
   CASE  
       WHEN DTL.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN DTL.resource_type 
       WHEN DTL.resource_type = 'OBJECT' THEN OBJECT_NAME(DTL.resource_associated_entity_id) 
       WHEN DTL.resource_type IN ('KEY', 'PAGE', 'RID') THEN  
           ( 
           SELECT OBJECT_NAME([object_id]) 
           FROM sys.partitions 
           WHERE sys.partitions.hobt_id =  
           DTL.resource_associated_entity_id 
           ) 
       ELSE 'Unidentified' 
   END AS requested_object_name, DTL.request_mode, DTL.request_status,   
   DOWT.wait_duration_ms, DOWT.wait_type, DOWT.session_id AS [blocked_session_id], 
   sp_blocked.[loginame] AS [blocked_user], DEST_blocked.[text] AS [blocked_command],
   DOWT.blocking_session_id, sp_blocking.[loginame] AS [blocking_user], 
   DEST_blocking.[text] AS [blocking_command], DOWT.resource_description    
FROM sys.dm_tran_locks DTL 
   INNER JOIN sys.dm_os_waiting_tasks DOWT  
       ON DTL.lock_owner_address = DOWT.resource_address  
   INNER JOIN sys.sysprocesses sp_blocked 
       ON DOWT.[session_id] = sp_blocked.[spid]
   INNER JOIN sys.sysprocesses sp_blocking 
       ON DOWT.[blocking_session_id] = sp_blocking.[spid]
   CROSS APPLY sys.[dm_exec_sql_text](sp_blocked.[sql_handle]) AS DEST_blocked
   CROSS APPLY sys.[dm_exec_sql_text](sp_blocking.[sql_handle]) AS DEST_blocking
WHERE DTL.[resource_database_id] = DB_ID()

select *, OBJECT_NAME(s.objectid)
  from sys.sysprocesses p
left join sys.dm_exec_requests r
	on p.spid = r.session_id
CROSS APPLY sys.[dm_exec_sql_text](p.[sql_handle]) s
--cross apply sys.dm_exec_query_plan(plan_handle)
 where spid = 82 --127 --125 --103 --70

select top 10 *
  from sys.dm_exec_requests 

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

ROLLBACK