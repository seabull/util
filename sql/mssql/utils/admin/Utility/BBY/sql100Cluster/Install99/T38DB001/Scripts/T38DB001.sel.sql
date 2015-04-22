use T38DB001
go
-- select 'select distinct run_ts from T38DB001.dbo.' + name + ' order by run_ts desc' from sys.tables
select * from T38DB001.dbo.T38CONFIGPARAMETERS
/*
update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_VAL = 2*24 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_index_usage_stats'
update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_VAL = 2*24
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_index_operational_stats'
update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_VAL = 2*24 
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_os_wait_stats'
update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_VAL = 2*24
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_virtual_file_stats'
update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_VAL = 2*24
	where PARAMETER_NM = 'MAXHOURS2KEEP:T38_exec_query_stats'

update T38DB001.dbo.T38CONFIGPARAMETERS set PARAMETER_NM = 'MAXHOURS2KEEP:T38_virtual_file_stats'
	where PARAMETER_NM = 'xMAXHOURS2KEEP:T38_virtual_file_stats'
*/
select distinct run_ts as 'run_ts T38mon_os_wait_stats' from T38DB001.dbo.T38mon_os_wait_stats order by run_ts desc
-- select * from T38DB001.dbo.T38mon_os_wait_stats
select distinct run_ts as 'run_ts T38mon_db_index_operational_stats' from T38DB001.dbo.T38mon_db_index_operational_stats order by run_ts desc
-- select * from T38DB001.dbo.T38mon_db_index_operational_stats
select distinct run_ts as 'run_ts T38mon_index_usage_stats' from T38DB001.dbo.T38mon_index_usage_stats order by run_ts desc
-- select * from T38DB001.dbo.T38mon_index_usage_stats
select distinct run_ts as 'run_ts T38mon_exec_query_stats_by_io' from T38DB001.dbo.T38mon_exec_query_stats_by_io order by run_ts desc
-- select * from T38DB001.dbo.T38mon_exec_query_stats_by_io
select distinct run_ts as 'run_ts T38mon_exec_query_stats_by_cpu' from T38DB001.dbo.T38mon_exec_query_stats_by_cpu order by run_ts desc
-- select * from T38DB001.dbo.T38mon_exec_query_stats_by_cpu
select distinct run_ts as 'run_ts T38mon_exec_query_stats_by_duration' from T38DB001.dbo.T38mon_exec_query_stats_by_duration order by run_ts desc
-- select * from T38DB001.dbo.T38mon_exec_query_stats_by_duration
select distinct run_ts as 'run_ts T38mon_io_virtual_file_stats' from T38DB001.dbo.T38mon_io_virtual_file_stats order by run_ts desc 
-- select * from T38DB001.dbo.T38mon_io_virtual_file_stats 
--	where run_ts < dateadd(minute, 0-20, getdate()) -- dateadd(hour, 0-1, getdate())


-- exec T38DB001..USP_INS_index_usage_stats
