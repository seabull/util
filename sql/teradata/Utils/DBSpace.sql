select databasename
		,max(PermSpaceGB) StorageCapacityGB
		,max(CurrentPermGB) StorageUsedGB
        ,case when max(PermSpaceGB) > 0 then cast( max(currentPermGB)/max(PermSpaceGB)*100 as decimal(20,0) ) else 0 end as UsagePercent
  from (
        select databasename
            ,cast(sum(currentPerm)/(1024*1024*1024) as decimal(20,6)) as currentPermGB
            ,cast(sum(PeakPerm)/(1024*1024*1024) as decimal(20, 6)) as PeakPermGB
            ,cast(0 as decimal(20, 6)) as PermSpaceGB
            ,cast(0 as decimal(20, 6)) as TempSpaceGB
            ,cast(0 as decimal(20, 6)) as SpoolSpaceGB
          from dbc.tablesize ts
          where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk')
          group by DatabaseName
        union
          select databasename
                ,0 as currentPermGB
                ,0 as PeakPermGB
                ,cast(sum(PermSpace)/(1024*1024*1024) as decimal(20, 6))  as PermSpaceGB
                ,cast(sum(TempSpace)/(1024*1024*1024) as decimal(20, 6))  as TempSpaceGB
                ,cast(sum(spoolSpace)/(1024*1024*1024) as decimal(20, 6)) as SpoolSpaceGB
            from dbc.databases
           where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk')
            group by databaseName
    ) x
group by 1
