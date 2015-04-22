-- $Id: SqlServerInternals.sql,v 1.1 2010/10/22 16:30:47 A645276 Exp $
-- $Author: A645276 $
-- $Date: 2010/10/22 16:30:47 $
--
-- managing memory in other caches

select * --removed_last_round_count
  from sys.dm_os_memory_cache_clock_hands
order by removed_last_round_count DESC

-- Memory Broker 

select *
  from sys.dm_os_ring_buffers
 where ring_buffer_type = 'RING_BUFFER_MEMORY_BROKER'

-- sizing Memory

-- how much space used by a component outside of buffer pool
select type, sum(multi_pages_kb) --*
  from sys.dm_os_memory_clerks
 where multi_pages_kb != 0
group by type

select *
  from sys.dm_os_sys_info

-- NUMA and schedulers

-- resource monitor

select session_id,
		convert(varchar(10), t1.status) as status,
		convert(varchar(20), t1.command) as command,
		convert(varchar(15), t2.state) as worker_state
  from sys.dm_exec_requests t1
join sys.dm_os_workers t2
	on t2.task_address = t1.task_address
 where command = 'RESOURCE MONITOR'

-- scheduler internals

select *
  from sys.dm_os_schedulers

select *
  from sys.dm_os_workers

select *
  from sys.dm_os_threads

select *
  from sys.dm_os_tasks

select * -- session_id, exec_context_id, wait_duration_ms, wait_type, resource_address
			-- blocking_task_address, blocking_session_id, blocking_exec_context_id, resource_description
  from sys.dm_os_waiting_tasks

-- DAC

select s.session_id
  from sys.tcp_endpoints t
join sys.dm_exec_sessions s
	on t.endpoint_id = s.endpoint_id
 where t.name = 'Dedicated Admin Connection'

-- observing memory internals

select * -- physical_memory_in_bytes, virtual_memory_in_bytes, bpool_*
  from sys.dm_os_sys_info

select suser_sname(), suser_name()

-- Resource Governor

select *
  from sys.resource_governor_configuration

select *
  from sys.resource_governor_resource_pools

select *
  from sys.resource_governor_workload_groups
