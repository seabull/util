USE T38DB001
go
alter table [dbo].[T38mon_exec_query_stats_by_io] alter column [query_plan] [nvarchar](max)
go
print 'Table T38mon_exec_query_stats_by_io has been altered.'
go
alter table [dbo].[T38mon_exec_query_stats_by_cpu] alter column [query_plan] [nvarchar](max)
go
print 'Table T38mon_exec_query_stats_by_cpu has been altered.'
go
alter table [dbo].[T38mon_exec_query_stats_by_duration] alter column [query_plan] [nvarchar](max)
go
print 'Table T38mon_exec_query_stats_by_duration has been altered.'
go