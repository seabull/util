SELECT T.[text], 
        P.[query_plan], 
        S.[program_name], 
        S.[host_name],
        S.[client_interface_name], 
        S.[login_name], 
        R.*
FROM sys.dm_exec_requests R
INNER JOIN sys.dm_exec_sessions S 
    ON S.session_id = R.session_id
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS T
CROSS APPLY sys.dm_exec_query_plan(plan_handle) As P
GO


--Return Query Text Along With sp_who2 Using DMV 
SELECT  D.text SQLStatement, 
        A.Session_ID SPID, 
        ISNULL(B.status,A.status) Status,
        A.login_name Login,
        A.host_name HostName,
        C.BlkBy, 
        DB_NAME(B.Database_ID) DBName,
        B.command,
        ISNULL(B.cpu_time, A.cpu_time) CPUTime,
        ISNULL((B.reads + B.writes),(A.reads + A.writes)) DiskIO, 
        A.last_request_start_time LastBatch,
        A.program_name
  FROM    sys.dm_exec_sessions A    
LEFT JOIN    sys.dm_exec_requests B
    ON A.session_id = B.session_id   
LEFT JOIN       (
            SELECT                 
                A.request_session_id SPID,
                B.blocking_session_id BlkBy           
              FROM sys.dm_tran_locks as A             
            INNER JOIN sys.dm_os_waiting_tasks as B            
                ON A.lock_owner_address = B.resource_address        
            ) C    
    ON A.Session_ID = C.SPID   
OUTER APPLY sys.dm_exec_sql_text(sql_handle) D

-- use the following query to list all the schedulers 
-- and look at the number of runnable tasks
select  
    scheduler_id, 
    current_tasks_count, 
    runnable_tasks_count 
from  
    sys.dm_os_schedulers 
where  
    scheduler_id < 255

-- a high-level view of which currently cached batches or 
-- procedures are using the most CPU
select top 50  
    sum(qs.total_worker_time) as total_cpu_time,  
    sum(qs.execution_count) as total_execution_count, 
    count(*) as  number_of_statements,  
    qs.plan_handle  
from  
    sys.dm_exec_query_stats qs 
group by qs.plan_handle 
order by sum(qs.total_worker_time) desc

-- determine which query is using the most cumulative CPU
select  
    highest_cpu_queries.plan_handle,  
    highest_cpu_queries.total_worker_time, 
    q.dbid, 
    q.objectid, 
    q.number, 
    q.encrypted, 
    q.[text] 
from  
    (select top 50  
        qs.plan_handle,  
        qs.total_worker_time 
    from  
        sys.dm_exec_query_stats qs 
    order by qs.total_worker_time desc) as highest_cpu_queries 
    cross apply sys.dm_exec_sql_text(plan_handle) as q 
order by highest_cpu_queries.total_worker_time desc

--determine whether any active requests are running in parallel for a given session by using the following query.
select  
    r.session_id, 
    r.request_id, 
    max(isnull(exec_context_id, 0)) as number_of_workers, 
    r.sql_handle, 
    r.statement_start_offset, 
    r.statement_end_offset, 
    r.plan_handle 
from  
    sys.dm_exec_requests r 
    join sys.dm_os_tasks t on r.session_id = t.session_id 
    join sys.dm_exec_sessions s on r.session_id = s.session_id 
where  
    s.is_user_process = 0x1 
group by  
    r.session_id, r.request_id,  
    r.sql_handle, r.plan_handle,  
    r.statement_start_offset, r.statement_end_offset 
having max(isnull(exec_context_id, 0)) > 0

-- to determine the connections with API cursors (as opposed to TSQL cursors) 
-- that are using a fetch buffer size of one row. 
-- It is much more efficient to use a larger fetch buffer, such as 100 rows.
select  
    cur.*  
from  
    sys.dm_exec_connections con 
    cross apply sys.dm_exec_cursors(con.session_id) as cur 
where 
    cur.fetch_buffer_size = 1  
    and cur.properties LIKE 'API%'    -- API  
--cursor (TSQL cursors always have fetch buffer of 1)

-- 
-- Find query plans that may run in parallel 
-- 
select  
    p.*,  
    q.*, 
    cp.plan_handle 
from  
    sys.dm_exec_cached_plans cp 
    cross apply sys.dm_exec_query_plan(cp.plan_handle) p 
    cross apply sys.dm_exec_sql_text(cp.plan_handle) as q 
where  
    cp.cacheobjtype = 'Compiled Plan' and 
    p.query_plan.value('declare namespace  
p="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; 
        max(//p:RelOp/@Parallel)', 'float') > 0


-- amount of memory consumed by components outside the Buffer pool  
-- note that we exclude single_pages_kb as they come from BPool 
-- BPool is accounted for by the next query 
select 
    sum(multi_pages_kb  
        + virtual_memory_committed_kb 
        + shared_memory_committed_kb) as 
[Overall used w/o BPool, Kb] 
from  
    sys.dm_os_memory_clerks  
where  
    type <> 'MEMORYCLERK_SQLBUFFERPOOL' 

-----------------------------------------------
-- Memory Related
-----------------------------------------------
 
-- amount of memory consumed by BPool 
-- note that currenlty only BPool uses AWE 
select 
    sum(multi_pages_kb  
        + virtual_memory_committed_kb 
        + shared_memory_committed_kb 
        + awe_allocated_kb) as [Used by BPool with AWE, Kb] 
from  
    sys.dm_os_memory_clerks  
where  
    type = 'MEMORYCLERK_SQLBUFFERPOOL'

-- Detailed information per component can be obtained as follows. (This includes memory allocated from buffer pool as well as outside the buffer pool.)
declare @total_alloc bigint  
declare @tab table ( 
    type nvarchar(128) collate database_default  
    ,allocated bigint 
    ,virtual_res bigint 
    ,virtual_com bigint 
    ,awe bigint 
    ,shared_res bigint 
    ,shared_com bigint 
    ,topFive nvarchar(128) 
    ,grand_total bigint 
); 
-- note that this total excludes buffer pool  
committed memory as it represents the largest 
consumer which is normal 
select 
    @total_alloc =  
        sum(single_pages_kb  
            + multi_pages_kb  
            + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL'  
                THEN virtual_memory_committed_kb  
                ELSE 0 END)  
            + shared_memory_committed_kb) 
from  
    sys.dm_os_memory_clerks  
print  
    'Total allocated (including from Buffer Pool): '  
    + CAST(@total_alloc as varchar(10)) + ' Kb' 
insert into @tab 
select 
    type 
    ,sum(single_pages_kb + multi_pages_kb) as allocated 
    ,sum(virtual_memory_reserved_kb) as vertual_res 
    ,sum(virtual_memory_committed_kb) as virtual_com 
    ,sum(awe_allocated_kb) as awe 
    ,sum(shared_memory_reserved_kb) as shared_res  
    ,sum(shared_memory_committed_kb) as shared_com 
    ,case  when  ( 
        (sum(single_pages_kb  
            + multi_pages_kb  
            + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL'  
                THEN virtual_memory_committed_kb  
                ELSE 0 END)  
            + shared_memory_committed_kb))/ 
            (@total_alloc + 0.0)) >= 0.05  
          then type  
          else 'Other'  
    end as topFive 
    ,(sum(single_pages_kb  
        + multi_pages_kb  
        + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL'  
            THEN virtual_memory_committed_kb  
            ELSE 0 END)  
        + shared_memory_committed_kb)) as grand_total  
from  
    sys.dm_os_memory_clerks  
group by type 
order by (sum(single_pages_kb + multi_pages_kb 
+ (CASE WHEN type <>  
'MEMORYCLERK_SQLBUFFERPOOL' THEN  
virtual_memory_committed_kb ELSE 0 END) +  
shared_memory_committed_kb)) desc 
select  * from @tab

-- To determine the top ten consumers of the buffer pool pages (via a single-page allocator) 
-- use the following query.

-- top 10 consumers of memory from BPool 
select  
    top 10 type,  
    sum(single_pages_kb) as [SPA Mem, Kb] 
from  
    sys.dm_os_memory_clerks 
group by type  
order by sum(single_pages_kb) desc
