-- vim: sw=4 ts=4 et ft=sql: 

--
-- This query get info about index stats only.
-- It doesn't pull multi-Column stats (indexType = 'M')
-- It does pull single column index stats from dbc.tvfields
--
select databaseName
		,TableName
		,columnName
		,columnCount
		,indexType
		,tblCreatorName
		,tblCreateTm
		,SampleUsed
		,zeroStats
		,Collect_Date
		,Collect_Time
  from prodbbymeadhocvws.indexStatsWithColumnsDetail
 where collect_Date < date -5
 	or collect_date is null
order by collect_Date Desc, databasename, tablename 


select 'Collect Statistics ' 
        || case when indexType = 'M' then ' Column('
                                    else ' Index('
            end
        || columnName || ')'
        || ' on ' || trim(databasename) || '.' || trim(tablename)
        || ';'
        || ' -- ' || trim(tblCreatorName)  || ':' || indexType || ':' || columnCount || ':' || coalesce(Collect_Date, date - 1000) || ':' || SampleUsed

  from prodbbymeadhocvws.indexStatsWithColumnsDetail
 where collect_Date < date - 7
 	or collect_date is null
order by databasename, tablename
