USE T38DB001
go

alter table [dbo].[T38mon_exec_query_stats_by_io] add [plan_generation_num] [bigint] NULL,
execution_count [bigint] NULL, 
last_execution_time [datetime] NULL,
creation_time [datetime] NULL
go
print 'Table T38mon_exec_query_stats_by_io has been altered.'
go


alter table [dbo].[T38mon_exec_query_stats_by_cpu] add [plan_generation_num] [int] NULL,
execution_count [int] NULL, 
last_execution_time [datetime] NULL,
creation_time [datetime] NULL
go
print 'Table T38mon_exec_query_stats_by_cpu has been altered.'
go


alter table [dbo].[T38mon_exec_query_stats_by_duration] add [plan_generation_num] [bigint] NULL,
execution_count [bigint] NULL, 
last_execution_time [datetime] NULL,
creation_time [datetime] NULL
go
print 'Table T38mon_exec_query_stats_by_duration has been altered.'
go