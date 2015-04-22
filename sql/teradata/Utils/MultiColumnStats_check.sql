--
-- from http://developer.teradata.com/database/articles/removing-multi-column-statistics-a-process-for-identification-of-redundant-statist
--
SELECT 'DROP STATISTICS ON ' || TRIM(DATABASENAME) || '.' || TRIM(TABLENAME) ||
       ' COLUMN (' || TRIM(ColumnList) || ');' REMOVE_MC_STATS
FROM
(
SELECT SINGLE.DatabaseName
      ,SINGLE.TableName
      ,SINGLE.ColumnName (CHAR(30))
      ,SINGLE.NumOfValues (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9') FirstColumnValues
      ,CASE WHEN FirstColumnValues = MultiColumnValues
            THEN 'REMOVE' ELSE 'KEEP  ' END Recomendation
      ,MULTI.NumOfValues  (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9')  MultiColumnValues
      ,MULTI.ColumnName ColumnList
FROM
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(30))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumOfRows
      ,NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'C'
  AND NumOfValues > 0
) SINGLE,
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(120))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumOfRows
      ,NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'M'
  AND NumOfValues > 0
  AND COLUMNNAME <> 'PARTITION'
) MULTI
WHERE SINGLE.DATABASENAME = MULTI.DATABASENAME
  AND SINGLE.TABLENAME    = MULTI.TABLENAME
  AND SINGLE.COLUMNNAME   = 
      SUBSTR(MULTI.COLUMNNAME,1,POSITION(',' IN MULTI.COLUMNNAME) - 1)
  AND RECOMENDATION = 'REMOVE'
  AND SINGLE.DATABASENAME = 'prodbbymeadhocdb'
-- ORDER BY 1,2,3
) DT
ORDER BY 1
;


-- the query looks for tables that have MC Statistic combinations, 
-- but do NOT have statistics on the first column of the MC Statistics. 
--
-- You may find that you can add the single column statistics on the first column, 
-- get good results and be able to remove the MC Statistics.

SELECT 'COLLECT STATISTICS ON ' || TRIM(DATABASENAME) || '.' || TRIM(TABLENAME) ||
       ' COLUMN (' || TRIM(SUBSTR(ColumnList,1,POSITION(',' IN ColumnList) - 1)) || ');' ADD_SINGLE_STATS
  FROM
(
SELECT MULTI.DatabaseName
      ,MULTI.TableName
      ,SINGLE.ColumnName (CHAR(30))
      ,CASE WHEN MULTI.NumOfRows = MULTI.NumOfValues
            THEN 'ADD SINGLE COLUMN' ELSE ' ' END Recomendation
      ,MULTI.NumOfRows
      ,MULTI.NumOfValues (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9') MultiColumnValues
      ,MULTI.ColumnName ColumnList
  FROM
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(120))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumOfRows
      ,NumOfValues
  FROM TOOLSDB.Stats_Info
 WHERE statstype = 'M'
   AND NumOfValues > 0
   AND COLUMNNAME NOT LIKE 'PARTITION%'
   AND POSITION(',' IN COLUMNNAME) > 0
) MULTI
LEFT OUTER JOIN
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(30))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumOfRows
      ,NumOfValues
  FROM TOOLSDB.Stats_Info
 WHERE statstype = 'C'
  AND NumOfValues > 0
) SINGLE
 ON SINGLE.DATABASENAME = MULTI.DATABASENAME
AND SINGLE.TABLENAME = MULTI.TABLENAME
AND SINGLE.COLUMNNAME = 
    SUBSTR(MULTI.COLUMNNAME,1,POSITION(',' IN MULTI.COLUMNNAME) - 1)
WHERE MULTI.DATABASENAME = 'prodbbymeadhocdb' 
AND SINGLE.ColumnName IS NULL
AND Recomendation > ' '
-- ORDER BY 1,2,3
) DT
GROUP BY 1
ORDER BY 1
;
