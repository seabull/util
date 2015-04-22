/*-Settings--------------------------
BackColor:SkyBlue;
EnvironmentID:63356490;
EnvironmentName:Teradata Prod;
Title:dbc;
-----------------------------------*/
select dbqlsql.sqlTextInfo
  from pdcrinfo.DBQLogTbl_hst dbql
 join pdcrinfo.DBQLSqlTbl_Hst dbqlsql
 	on dbql.QueryID = dbqlsql.QueryID
	and dbql.LogDate = dbqlsql.LogDate
 where dbql.QueryID = 163654404661019872
   and dbql.LogDate = cast('2010-05-28' as date)
 

select sqlTextInfo
  from pdcrinfo.DBQLSqlTbl_Hst dbqlsql
sample 10

select sqlTextInfo
  from pdcrinfo.DBQLSqlTbl_Hst dbqlsql
 where QueryID = 163654404661019872
  
select (FirstStepTime-StartTime second(4)) (varchar(20)) Delay, sessionID, StartTime (varchar(58)), FirstStepTime (varchar(58)), FirstRespTime, dbql.StatementType, QueryText, dbql.*
  from pdcrinfo.DBQLogTbl_Hst dbql --pdcrinfo.DBQLSqlTbl_Hst
 WHERE logDate = date - 4
   --AND QueryText like '%Job=375,%'
   AND sessionID = 51086751
   --AND SessionID in (51087675,51087335,51087855, 51086751, 51087541) --51062191
   --AND dbql.StatementType IN ('Insert', 'Delete')

select (FirstStepTime-StartTime second(4)) (varchar(20)) Delay, sessionID, StartTime (varchar(58)), FirstStepTime (varchar(58)), FirstRespTime, dbql.StatementType, QueryText, dbql.*
  from pdcrinfo.DBQLogTbl_Hst dbql --pdcrinfo.DBQLSqlTbl_Hst
 WHERE logDate = date - 4
   AND SessionID in (51061985, 51062191)
   
 sample 10
 
select (FirstStepTime-StartTime second(4)) (varchar(20)) Delay, sessionID, StartTime (varchar(58)), FirstStepTime (varchar(58)), FirstRespTime, dbql.StatementType, QueryText, dbql.*
  from pdcrinfo.DBQLogTbl_Hst dbql --pdcrinfo.DBQLSqlTbl_Hst
 WHERE logDate = date - 2
   AND QueryText like '%Job=375,%'
   AND UserName = 'RASC_FORT_BCH'

 
 select sqlTextInfo --*
  from pdcrinfo.DBQLogTbl_hst dbql
 join pdcrinfo.DBQLSqlTbl_Hst dbqlsql
 	on dbql.QueryID = dbqlsql.QueryID
	and dbql.LogDate = dbqlsql.LogDate
 where  dbql.LogDate = cast('2010-06-11' as date)
 and dbql.queryid = 163274404642440238 --163264404641654005 --163274404642440238 --163274404642440220
 --and querytext like '%INSERT INTO TBEN_FI_MTRX_LO_SC_VN_SG_FD%'

show view pdcrinfo.DBQLogTbl_hst 

show table PDCRDATA.DBQLogTbl_Hst

-- queries by table name

SELECT *
  FROM pdcrinfo.DBQLObjTbl_Hst obj
  JOIN PDCRINFO.DBQLogTbl_Hst dbql
  	on obj.QueryID = dbql.QueryID
	and obj.LogDate = dbql.LogDate
 WHERE obj.logDate = date - 1 --BETWEEN date - 5 AND date - 1
   AND obj.ObjectTableName = 'FORT_DAT_FIN'
   AND obj.ObjectDatabaseName = 'PRODBBYMEADHOCDB'
   AND obj.ObjectType = 'Tab'

SELECT obj.LogDate, dbql.UserName, count(*)
  FROM pdcrinfo.DBQLObjTbl_Hst obj
  JOIN PDCRINFO.DBQLogTbl_Hst dbql
  	on obj.QueryID = dbql.QueryID
	and obj.LogDate = dbql.LogDate
 WHERE obj.logDate BETWEEN date - 7 AND date - 1
   AND obj.ObjectTableName = 'FORT_DAT_FIN'
   AND obj.ObjectDatabaseName = 'PRODBBYMEADHOCDB'
   AND obj.ObjectType = 'Tab'
 GROUP BY 1,2

select *
  from dbc.tables
 where tablename = 'TBENW_FI_MTRX_GRP_PROC_CTL'
 
 show table prodetlstage.TBENW_FI_MTRX_GRP_PROC_CTL 
 
 SHOW VIEW PDCRINFO.DBQLogTbl_Hst --dbc.QryLogV --DBC.QryLog 
 
 SELECT DelayTime, cast(((FirstStepTime - startTime) second(4)) as integer) --as varchar(10)) -- interval second(4)
   FROM PDCRINFO.DBQLogTbl_DBC
  WHERE DelayTime  is null
    AND logDate = date

 SELECT * --DelayTime, cast(((FirstStepTime - startTime) second(4)) as integer) --as varchar(10)) -- interval second(4)
   FROM PDCRINFO.DBQLogTbl_DBC
  WHERE sessionID = 57119227 --55307173 --55321068
--IN (55321060,55306143) --(55315992, 55316157, 55316456,55316542,55316675,55316769 ) --= 55315910 --55103102
  --= 55103958
--55103124
--55103202
 -- IN (55081957,55081954,55081957,55081964,55081962) --= 55081964
    AND logDate = date

SELECT *
  FROM PDCRINFO.DBQLogTbl_DBC dbql
  JOIN PDCRINFO.DBQLObjTbl_Dbc obj
  	on dbql.QueryID = obj.QueryID
  WHERE obj.ObjectTableName = 'FORT_PRJ_ACTION_LIST_SQL' --'BBYM_FLD_LDRSHP'
    AND obj.ObjectDatabaseName = 'PRODBBYMEADHOCDB'
	AND dbql.LogDate > date - 1

--
-- list of join indexes
--

SELECT *
  FROM DBC.tables
 WHERE requestText like '%join index%'
   AND TableKind = 'I'
   AND databasename IN ('prodbbydb', 'prodbbyrptdb', 'prodETLStage')

select *
  from dbc.databases
 where databasename = 'ProdBBYCIAdhocDB'

  
 select *
   from dbc.tables
  where databasename = 'ProdBBYCCAdhocDB'
    and tablename = 'JL_IP_ADDR'
   sample 10
   
 select *
   from dbc.Indices
  sample 10
  
--  
-- Multi column index not needed
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
      ,NumRows NumOfRows
      ,NumValues NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'C'
  AND NumValues > 0
) SINGLE,
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(120))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumRows NumOfRows
      ,NumValues NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'M'
  AND NumValues > 0
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

SELECT SINGLE.DatabaseName
      ,SINGLE.TableName
      ,SINGLE.ColumnName (CHAR(30))
      ,SINGLE.NumOfValues (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9') FirstColumnValues
      ,CASE WHEN FirstColumnValues = MultiColumnValues
            THEN 'REMOVE' ELSE 'KEEP  ' END Recomendation
      ,MULTI.NumOfValues  (FORMAT 'ZZZ,ZZZ,ZZZ,ZZ9')  MultiColumnValues
      ,MULTI.ColumnName ColumnList
	  ,t.TotalPermMB
	  ,t.CreatorName
	  ,t.SkewFactor
FROM
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(30))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumRows NumOfRows
      ,NumValues NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'C'
  AND NumValues > 0
) SINGLE,
(
SELECT DatabaseName
      ,TableName
      ,ColumnName (CHAR(120))
      ,StatsType
      ,CollectDate
      ,SampleSize
      ,NumRows NumOfRows
      ,NumValues NumOfValues
 FROM prodbbymeadhocvws.rasc_stats_details --TOOLSDB.Stats_Info
WHERE statstype = 'M'
  AND NumValues > 0
  AND COLUMNNAME <> 'PARTITION'
) MULTI
, PRODBBYMEADHOCVWS.rasc_TVMAccess_info t
WHERE SINGLE.DATABASENAME = MULTI.DATABASENAME
  AND SINGLE.TABLENAME    = MULTI.TABLENAME
  AND SINGLE.COLUMNNAME   = 
      SUBSTR(MULTI.COLUMNNAME,1,POSITION(',' IN MULTI.COLUMNNAME) - 1)
  AND RECOMENDATION = 'REMOVE'
  AND SINGLE.DATABASENAME = 'prodbbymeadhocdb'
  AND single.databasename = t.DatabaseName
  AND single.tablename = t.TableName


select
		databaseName, TableName, IndexNumber, IndexName, IndexType, UniqueFlag--, ColumnPosition, ColumnName
                 ,max((-1**(NumValuesw1 / 32768)) * (2**((NumValuesw1 / 16 mod 2048) - 1023))
                        * (1 + ((NumValuesw1 mod 16) * 2**-4)
                        + (NumValuesw2 * 2**-20)
                        + (NumValuesw3 * 2**-36)
                        + (NumValuesw4 * 2**-52))
                        ) (decimal(18,0)) AS NumValues
  from
(
select
		databaseName, TableName, IndexNumber, IndexName, IndexType, UniqueFlag , ColumnPosition, ColumnName
        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 8, 1) || SUBSTR(Stats, 48 + offset + 7, 1) (BYTE(4))) AS NumValuesw1
        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 6, 1) || SUBSTR(Stats, 48 + offset + 5, 1) (BYTE(4))) AS NumValuesw2
		,HASHBUCKET(SUBSTR(Stats, 48 + offset + 4, 1) || SUBSTR(Stats, 48 + offset + 3, 1) (BYTE(4))) AS NumValuesw3
		,HASHBUCKET(SUBSTR(Stats, 48 + offset + 2, 1) || SUBSTR(Stats, 48 + offset + 1, 1) (BYTE(4))) AS NumValuesw4
  from
(
select  
		databaseName, TableName, IndexNumber, IndexName, IndexType, UniqueFlag, ColumnPosition, ColumnName
		,CASE WHEN SUBSTR(indexStatistics, 23, 1) = '00'XB
                  THEN 16
                  ELSE 0
           END AS Offset
          ,case when (indexstatistics is not null) then SUBSTR(indexstatistics, 1, 80) 
                else null
           end AS Stats
--*
  from dbc.IndexStats
 where Databasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
 ) x
 ) xx
 group by 1,2,3,4,5,6--,7,8
 sample 10
 
show view prodbbymeadhocvws.rasc_table_stat_base_info
  
replace view prodbbymeadhocvws.rasc_table_stat_info
as
locking row for access
SELECT /*** 64-bit ***/
DatabaseName,
TableName,
ColumnName,
/** Number of columns within multi-column or index stats **/
ColumnCount,
/** stats collected on:
'C' --> Column
'I' --> Index
'M' --> Multiple columns (V2R5+)
'D' --> Pseudo column PARTITION (V2R6.1+)
**/
StatsType,
/** collect stats date **/
CollectDate (DATE),
/** collect stats time **/
CollectTime (TIME(2)),
CollectTimestamp (TIMESTAMP(2)),
/** V2R5: sample size used for collect stats, NULL if not sampled **/
SampleSize,
/** Version
1: pre-V2R5
2: V2R5+
3: TD12
**/
StatsVersion,
/** TD12: Number of AMPs on the system **/
NumAMPs,
/** Number of intervals **/
NumIntervals,
/** TD12: All-AMPs average of the average number of rows per NUSI value
per individual AMP, Estimated WHEN Sampled **/
AvgAmpRPV,
/** Row Count, Estimated when Sampled **/
NumRows (DECIMAL(18,0)),
/** Distinct Values, Estimated when Sampled **/
NumValues (DECIMAL(18,0)),
/** Number of partly null and all null rows,
Estimated WHEN Sampled **/
NumNulls (DECIMAL(18,0)),
/** TD12: Number of all null rows in the column or index set,
Estimated WHEN Sampled **/
NumAllNulls (DECIMAL(18,0)),
/** Maximum number of rows / value, Estimated when Sampled **/
ModeFreq (DECIMAL(18,0))
,IndexType, UniqueFlag 
from prodbbymeadhocvws.rasc_table_stat_base_info

 where databasename = 'prodbbymeadhocdb'
 
show view prodbbymeadhocvws.rasc_table_stat_base_info

replace view prodbbymeadhocvws.rasc_table_stat_base
 as
 locking row for access
 SELECT
 DatabaseName,
 TableName,
 MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition > 16 THEN ',...' ELSE '' END) AS ColumnName,
 COUNT(*) AS ColumnCount,
 'I' AS StatsType,
 MAX(SUBSTR(IndexStatistics, 1, 128)) AS STATS
 ,IndexType, UniqueFlag 
 FROM dbc.IndexStats
 GROUP BY DatabaseName, TableName, StatsType, IndexNumber,IndexType, UniqueFlag 
 HAVING STATS IS NOT NULL
 /** Remove for pre-V2R5 --> **/
 UNION ALL
 SELECT
 DatabaseName,
 TableName,
 MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END) ||
 MAX(CASE WHEN ColumnPosition > 16 THEN ',...' ELSE '' END) AS ColumnName,
 COUNT(*) AS ColumnCount,
 MAX(CASE WHEN StatisticsId = 129 AND ColumnName = 'PARTITION' THEN 'D' ELSE 'M' END) AS StatsType,
 MAX(SUBSTR(ColumnsStatistics, 1, 128)) AS STATS
 ,'M','N'
 FROM dbc.MultiColumnStats
 GROUP BY DatabaseName, TableName, StatisticsID
 HAVING STATS IS NOT NULL
 /** <-- Remove for pre-V2R5 **/
 UNION ALL
 SELECT
 DatabaseName,
 TableName,
 ColumnName,
 1 AS ColumnCount,
 'C' AS StatsType,
 SUBSTR(fieldstatistics, 1, 128) AS STATS
 ,'C','N'
 FROM dbc.ColumnStats
 WHERE STATS IS NOT NULL

replace view prodbbymeadhocvws.rasc_table_stat_base2
 as
 locking row for access
 SELECT
 DatabaseName,
 TableName,
 ColumnName,
 ColumnCount,
 StatsType,
 /** TD12 changed the HASHBUCKET function (16 bit vs. 20 bit),
 on TD12 (using 20 bits for HashBuckets) the result must be divided by 16 **/
 ((HASHBUCKET()+1)/65536) AS TD12,
 SUBSTR(STATS, 1, 4) AS CollectDate_,
 SUBSTR(STATS, 5, 4) AS CollectTime_,
 POSITION(SUBSTR(STATS, 9, 1) IN '010203'xb) AS StatsVersion,
 CASE WHEN HASHBUCKET ('00'xb || SUBSTR(STATS, 11, 1) (BYTE(4))) / TD12 = 1
 THEN HASHBUCKET ('00'xb || SUBSTR(STATS, 12, 1) (BYTE(4))) / TD12
 END AS SampleSize,
 SUBSTR(STATS, 13 + 4, 8) AS NumNulls_,
 SUBSTR(STATS, 21 + 4, 2) AS NumIntervals_,
 CASE
 WHEN StatsVersion = 3 THEN SUBSTR(STATS, 25 + 8, 8)
 END AS NumAllNulls_,
 CASE WHEN StatsVersion = 3 THEN SUBSTR(STATS, 33 + 8 , 8)
 END AS AvgAmpRPV_,
 CASE WHEN StatsVersion = 3 THEN SUBSTR(STATS, 57 + 8, 2)
 END AS NumAMPs_,
 CASE WHEN SUBSTR(STATS, 23 + 4, 1) = '01'xb THEN 16
 ELSE 32
 END AS Offset,
 CASE WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset, 8)
 WHEN StatsVersion = 3 THEN SUBSTR(STATS, 73 + Offset, 8)
 END AS ModeFreq_,
 CASE WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset + 8, 8)
 WHEN StatsVersion = 3 THEN SUBSTR(STATS, 73 + Offset + 8, 8)
 END AS NumValues_,
 CASE WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset + 16, 8)
 WHEN StatsVersion = 3 THEN SUBSTR(STATS, 73 + Offset + 16, 8)
 END AS NumRows_
 ,IndexType, UniqueFlag 
 from prodbbymeadhocvws.rasc_table_stat_base

replace view prodbbymeadhocvws.rasc_table_stat_base_info
 as
 locking row for access
 SELECT
 DatabaseName,
 TableName,
 ColumnName,
 ColumnCount,
 StatsType,
 SampleSize,
 StatsVersion,
 ( (HASHBUCKET(SUBSTR(CollectDate_, 2, 1) || SUBSTR(CollectDate_, 1, 1) (BYTE(4)) ) / TD12 - 1900) * 10000
 +
 (HASHBUCKET ('00'xb || SUBSTR(CollectDate_, 3, 1) (BYTE(4))) / TD12) * 100
 +
 (HASHBUCKET ( '00'xb || SUBSTR(CollectDate_, 4, 1) (BYTE(4))) / TD12) (DATE, FORMAT 'yyyy-mm-ddB')
 ) AS CollectDate,
 (
 (HASHBUCKET (CAST('00'xb || SUBSTR(CollectTime_, 1, 1) AS BYTE(4))) / TD12 (FORMAT '99:')) ||
 (HASHBUCKET (CAST('00'xb || SUBSTR(CollectTime_, 2, 1) AS BYTE(4))) / TD12 (FORMAT '99:')) ||
 (HASHBUCKET (CAST('00'xb || SUBSTR(CollectTime_, 3, 1) AS BYTE(4))) / TD12 (FORMAT '99.')) ||
 (HASHBUCKET (CAST('00'xb || SUBSTR(CollectTime_, 4, 1) AS BYTE(4))) / TD12 (FORMAT '99')) (TIME(2), FORMAT 'hh:mi:ss.s(2)')
 ) AS CollectTime,
 (CollectDate || (CollectTime (CHAR(11))))
 (TIMESTAMP(2), FORMAT 'yyyy-mm-ddBhh:mi:ss.s(2)') AS CollectTimestamp,
 HASHBUCKET(SUBSTR(NumNulls_, 8, 1) || SUBSTR(NumNulls_, 7, 1) (BYTE(4))) / TD12 AS NumNullsw1,
 HASHBUCKET(SUBSTR(NumNulls_, 6, 1) || SUBSTR(NumNulls_, 5, 1) (BYTE(4))) / TD12 AS NumNullsw2,
 HASHBUCKET(SUBSTR(NumNulls_, 4, 1) || SUBSTR(NumNulls_, 3, 1) (BYTE(4))) / TD12 AS NumNullsw3,
 HASHBUCKET(SUBSTR(NumNulls_, 2, 1) || SUBSTR(NumNulls_, 1, 1) (BYTE(4))) / TD12 AS NumNullsw4,
 CASE WHEN NumNulls_ = '00'xb THEN 0
 ELSE (-1**(NumNullsw1 / 32768)) * (2**((NumNullsw1/16 MOD 2048) - 1023))
 * (1 + ((NumNullsw1 MOD 16) * 2**-4) + (NumNullsw2 * 2**-20)
 + (NumNullsw3 * 2**-36) + (NumNullsw4 * 2**-52)
 )
 END AS NumNulls,
 HASHBUCKET(SUBSTR(NumIntervals_, 2, 1) || SUBSTR(NumIntervals_, 1, 1) (BYTE(4))) / TD12 AS NumIntervals,
 HASHBUCKET(SUBSTR(NumAllNulls_, 8, 1) || SUBSTR(NumAllNulls_, 7, 1) (BYTE(4))) / TD12 AS NumAllNullsw1,
 HASHBUCKET(SUBSTR(NumAllNulls_, 6, 1) || SUBSTR(NumAllNulls_, 5, 1) (BYTE(4))) / TD12 AS NumAllNullsw2,
 HASHBUCKET(SUBSTR(NumAllNulls_, 4, 1) || SUBSTR(NumAllNulls_, 3, 1) (BYTE(4))) / TD12 AS NumAllNullsw3,
 HASHBUCKET(SUBSTR(NumAllNulls_, 2, 1) || SUBSTR(NumAllNulls_, 1, 1) (BYTE(4))) / TD12 AS NumAllNullsw4,
 CASE WHEN NumAllNulls_ = '00'xb THEN 0
 ELSE
 (-1**(NumAllNullsw1 / 32768))
 * (2**((NumAllNullsw1/16 MOD 2048) - 1023))
 * (1 + ((NumAllNullsw1 MOD 16) * 2**-4) + (NumAllNullsw2 * 2**-20)
 + (NumAllNullsw3 * 2**-36) + (NumAllNullsw4 * 2**-52))
 END AS NumAllNulls,
 HASHBUCKET(SUBSTR(AvgAmpRPV_, 8, 1) || SUBSTR(AvgAmpRPV_, 7, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw1,
 HASHBUCKET(SUBSTR(AvgAmpRPV_, 6, 1) || SUBSTR(AvgAmpRPV_, 5, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw2,
 HASHBUCKET(SUBSTR(AvgAmpRPV_, 4, 1) || SUBSTR(AvgAmpRPV_, 3, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw3,
 HASHBUCKET(SUBSTR(AvgAmpRPV_, 2, 1) || SUBSTR(AvgAmpRPV_, 1, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw4,
 CASE WHEN AvgAmpRPV_ = '00'xb THEN 0
 ELSE
 (-1**(AvgAmpRPVw1 / 32768))
 * (2**((AvgAmpRPVw1/16 MOD 2048) - 1023))
 * (1 + ((AvgAmpRPVw1 MOD 16) * 2**-4) + (AvgAmpRPVw2 * 2**-20)
 + (AvgAmpRPVw3 * 2**-36) + (AvgAmpRPVw4 * 2**-52))
 END AS AvgAmpRPV,
 HASHBUCKET(SUBSTR(NumAMPs_, 2, 1) || SUBSTR(NumAMPs_, 1, 1) (BYTE(4))) / TD12 AS NumAMPs,
 HASHBUCKET(SUBSTR(ModeFreq_, 8, 1) || SUBSTR(ModeFreq_, 7, 1) (BYTE(4))) / TD12 AS ModeFreqw1,
 HASHBUCKET(SUBSTR(ModeFreq_, 6, 1) || SUBSTR(ModeFreq_, 5, 1) (BYTE(4))) / TD12 AS ModeFreqw2,
 HASHBUCKET(SUBSTR(ModeFreq_, 4, 1) || SUBSTR(ModeFreq_, 3, 1) (BYTE(4))) / TD12 AS ModeFreqw3,
 HASHBUCKET(SUBSTR(ModeFreq_, 2, 1) || SUBSTR(ModeFreq_, 1, 1) (BYTE(4))) / TD12 AS ModeFreqw4,
 CASE WHEN ModeFreq_ = '00'xb THEN 0
 ELSE
 (-1**(ModeFreqw1 / 32768))
 * (2**((ModeFreqw1/16 MOD 2048) - 1023))
 * (1 + ((ModeFreqw1 MOD 16) * 2**-4) + (ModeFreqw2 * 2**-20)
 + (ModeFreqw3 * 2**-36) + (ModeFreqw4 * 2**-52)
 )
 END AS ModeFreq,
 HASHBUCKET(SUBSTR(NumValues_, 8, 1) || SUBSTR(NumValues_, 7, 1) (BYTE(4))) / TD12 AS NumValuesw1,
 HASHBUCKET(SUBSTR(NumValues_, 6, 1) || SUBSTR(NumValues_, 5, 1) (BYTE(4))) / TD12 AS NumValuesw2,
 HASHBUCKET(SUBSTR(NumValues_, 4, 1) || SUBSTR(NumValues_, 3, 1) (BYTE(4))) / TD12 AS NumValuesw3,
 HASHBUCKET(SUBSTR(NumValues_, 2, 1) || SUBSTR(NumValues_, 1, 1) (BYTE(4))) / TD12 AS NumValuesw4,
 CASE WHEN NumValues_ = '00'xb THEN 0
 ELSE
 (-1**(NumValuesw1 / 32768))
 * (2**((NumValuesw1/16 MOD 2048) - 1023))
 * (1 + ((NumValuesw1 MOD 16) * 2**-4) + (NumValuesw2 * 2**-20)
 + (NumValuesw3 * 2**-36) + (NumValuesw4 * 2**-52))
 END AS NumValues,
 HASHBUCKET(SUBSTR(NumRows_, 8, 1) || SUBSTR(NumRows_, 7, 1) (BYTE(4))) / TD12 AS NumRowsw1,
 HASHBUCKET(SUBSTR(NumRows_, 6, 1) || SUBSTR(NumRows_, 5, 1) (BYTE(4))) / TD12 AS NumRowsw2,
 HASHBUCKET(SUBSTR(NumRows_, 4, 1) || SUBSTR(NumRows_, 3, 1) (BYTE(4))) / TD12 AS NumRowsw3,
 HASHBUCKET(SUBSTR(NumRows_, 2, 1) || SUBSTR(NumRows_, 1, 1) (BYTE(4))) / TD12 AS NumRowsw4,
 CASE WHEN NumRows_ = '00'xb THEN 0
 ELSE
 (-1**(NumRowsw1 / 32768))
 * (2**((NumRowsw1/16 MOD 2048) - 1023))
 * (1 + ((NumRowsw1 MOD 16) * 2**-4) + (NumRowsw2 * 2**-20)
 + (NumRowsw3 * 2**-36) + (NumRowsw4 * 2**-52)
 )
 END AS NumRows
 ,IndexType, UniqueFlag 
 from prodbbymeadhocvws.rasc_table_stat_base2

select NumRows/(NumValues + 1), i.*
  from prodbbymeadhocvws.rasc_table_stat_info i
 where databasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
   and indexType = 'P'
   and UniqueFlag = 'N'
   and NumRows/(NumValues + 1) > 1
   
select NumRows/(NumValues + 1), i.*
  from prodbbymeadhocvws.rasc_table_stat_info i
 where databasename = 'prodbbymeadhocwrk'
   and indexType = 'P'
   and UniqueFlag = 'N'
   and tablename = 'Vert000144_Cntrl_Erode_Old'
   
 select *
   from prodbbymeadhocvws.rasc_table_storage
  where tablename like 'BBYM_MTRX_MUR_TAB_ISSUE%'
  
  
-- tables with obsolete stats

 select (cast(s.LastAccessed as date) - i.CollectDate),
 		i.databasename, i.TableName, i.StatsType, i.CollectDate, s.LastAccessed,
 		i.NumRows, i.NumValues, i.ModeFreq, i.IndexType, 
 		s.CreatorName, s.TotalPermMB, s.SkewFactor,  s.TotalAccess
  from prodbbymeadhocvws.rasc_table_stat_info i
  	join prodbbymeadhocvws.rasc_table_storage s
	on i.databasename = s.databaseName
	and i.TableName = s.TableName
 where i.databasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
   and i.CollectDate < cast(s.LastAccessed as date) - 1
   and cast(s.LastAccessed as date) > date - 26
   and s.TotalAccess > 0
   
help stat PRODBBYMEADHOCWRK.QLIK_CLAIMS_LEGACY


SELECT *
  FROM PDCRINFO.DBQLObjTbl_Dbc a
 WHERE a.ObjectDatabaseName = 'prodbbymeadhocdb'
   AND objectTableName = 'haiku'

SELECT H.Haiku, H.HaikuID
  FROM PRODBBYMEADHOCDB.haiku H
 WHERE cast(H.RecModTS as date) > date - 400

SELECT min(logDate)
  FROM PDCRINFO.DBQLObjTblSum_Hst

--
-- columns not accessed in last 60 days
--

drop TABLE PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp

CREATE SET TABLE PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp
as
(
SELECT 'prodbbymeadhocdb' DatabaseName, c.TableName, c.ColumnName, obj.ObjectTableName, sum(obj.Object_Cnt) AccessCount, max(obj.LogDate) LastAccessed
  FROM (SELECT databaseName, TableName, ColumnName FROM DBC.Columns
  		WHERE databaseName = 'prodbbymeadhocdb') as c
LEFT OUTER JOIN PDCRINFO.DBQLObjTblSum_Hst obj --PDCRINFO.DBQLObjTbl_Hst obj
  	on c.DatabaseName = obj.ObjectDatabaseName
	AND c.TableName = obj.ObjectTableName
	AND c.ColumnName = obj.ObjectColumnName
	--AND c.DatabaseName = 'prodbbymeadhocdb'
    AND obj.LogDate > date - 91
 WHERE c.DatabaseName = 'prodbbymeadhocdb'
GROUP BY 1,2,3,4
--HAVING obj.ObjectTableName is null
--ORDER BY 3, 1,2
) with data primary index (databaseName, TableName)
  
help STATISTICS PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp

COLLECT STATISTICS index (DatabaseName, TableName) on PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp
;collect STATISTICS column (ObjectTableName) on PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp

SELECT *
  FROM DBC.Columns c
 WHERE c.DatabaseName = 'prodbbymeadhocdb'
   

SELECT count(*)
  from PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp
  
--
-- Tables that have columns never accessed and columns accessed
--

SELECT x.DatabaseName, x.TableName
		,max(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MaxAccessCount
		,min(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MinAccessCount
		,sum(CASE WHEN x.AccessCount is null then 1 else 0 end) ColNotAccessed
		,sum(CASE WHEN x.AccessCount is not null AND x.AccessCount > 0 then 1 else 0 end) ColAccessed
  FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp  x
GROUP BY 1,2
HAVING MinAccessCount <= 0 AND MaxAccessCount > 0

--
-- Table columns not accessed in last 90 days
--

SELECT xx.DatabaseName, xx.TableName, xx.ColumnName, 
		CASE c.ColumnType WHEN 'I' then 'Integer'
			WHEN 'D' then 'Decimal'
			WHEN 'DA' then 'Date'
			WHEN 'CV' then 'VARCHAR'
			WHEN 'TS' then 'Timestamp'
			else c.ColumnType
			end ColumnType, 
		c.ColumnLength
  FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp xx
  JOIN
(
	SELECT x.DatabaseName, x.TableName
			,max(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MaxAccessCount
			,min(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MinAccessCount
			,sum(CASE WHEN x.AccessCount is null then 1 else 0 end) ColNotAccessed
			,sum(CASE WHEN x.AccessCount is not null AND x.AccessCount > 0 then 1 else 0 end) ColAccessed
	FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp  x
	GROUP BY 1,2
	HAVING MinAccessCount <= 0 AND MaxAccessCount > 0
) xxx
	on xx.DatabaseName = xxx.DatabaseName
	AND xx.TableName = xxx.TableName
JOIN (SELECT * FROM DBC.Columns WHERE databasename = 'prodbbymeadhocdb') c
	on xx.DatabaseName = c.DatabaseName
	AND xx.TableName = c.TableName
	AND xx.ColumnName = c.columnName
 WHERE xx.AccessCount is null


--
-- Tables with columns not accessed, excluding tables never accessed
--

SELECT t.DatabaseName, t.TableName, t.CreatorName, t.CreateTimeStamp, t.TotalPermMB, t.lastAccessed, xx.LastAccessedCol, xx.ColNotAccessed, xx.ColAccessed, xx.TotalColumns 
  FROM (
SELECT x.DatabaseName, x.TableName
		,max(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MaxAccessCount
		,min(CASE WHEN x.AccessCount is null then 0 else x.AccessCount end) MinAccessCount
		,sum(CASE WHEN x.AccessCount is null then 1 else 0 end) ColNotAccessed
		,sum(CASE WHEN x.AccessCount is not null AND x.AccessCount > 0 then 1 else 0 end) ColAccessed
		,sum(CASE WHEN x.ColumnName is null then 0 else 1 end) TotalColumns
		,max(x.LastAccessed) LastAccessedCol
  FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp  x
GROUP BY 1,2
HAVING MinAccessCount <= 0 AND MaxAccessCount > 0
) xx
JOIN PRODBBYMEADHOCVWS.rasc_tvmaccess_info t
	on xx.DatabaseName = t.DatabaseName
	AND xx.TableName = t.TableName
	AND t.TableKind = 'T'

	SELECT *
	  FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp  x
	 WHERE x.DatabaseName = 'prodbbymeadhocdb'
	   AND x.TableName = 'AJU_REPORTING'

SELECT c.DatabaseName, c.TableName, c.ColumnName, col.ColumnType, col.ColumnLength, c.LastAccessed, c.AccessCount, I.CreatorName, I.CREATETIMESTAMP, I.lastAccessed, I.SkewFactor, I.TotalPermMB
  FROM (SELECT * FROM DBC.Columns WHERE databasename = 'prodbbymeadhocdb') col
  JOIN PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp c
  	on c.DatabaseName = col.DatabaseName
	AND c.TableName = col.TableName
	AND c.ColumnName = col.ColumnName
  JOIN PRODBBYMEADHOCVWS.rasc_tvmaccess_info I
  	on c.DatabaseName = I.DatabaseName
   AND c.TableName = I.TableName
   AND I.TableKind = 'T'
 --WHERE c.ObjectTableName is null
 ORDER BY C.DatabaseName, c.TableName, col.ColumnID
 


SELECT *
  FROM PRODBBYMEADHOCWRK.Columns_NotAccessed_Temp x
 WHERE x.TableName like 'ESC_%'
 ORDER BY TableName, ColumnName

SELECT *
  FROM PDCRINFO.DBQLObjTbl_Hst x
 WHERE logdate = date - 1
   AND x.ObjectDatabaseName = 'prodbbymeadhocdb'
   AND x.ObjectTableName = 'haiku'

SELECT *
  FROM PDCRINFO.DBQLObjTbl_Dbc x
 WHERE x.ObjectDatabaseName = 'prodbbymeadhocdb'
   AND x.ObjectTableName = 'haiku'

SELECT x.Haiku, x.RecModTS
  FROM PRODBBYMEADHOCDB.haiku x
 WHERE x.HaikuID < 100

SELECT *
  FROM DBC.Columns x
 WHERE x.DatabaseName = 'prodbbymeadhocdb'
   AND x.TableName = 'ESC_CUSTCST'

SELECT LogDate, UserName, ObjectDatabaseName, ObjectTableName--, objectType
  FROM PDCRINFO.DBQLObjTblSum_Hst x
 WHERE x.ObjectTableName IN ( 'tbend_lo_transfer', 'tbend_lo_transfer_line')
   AND x.UserName not IN ('RASC_FORT_BCH', 'ter_ucc_bch' ,'ter_umm_bch', 'bby_tva_user', 'BBYColStatsUser', 'DBAdmin')
  GROUP by 1,2,3,4 --,5
  --logdate > date - 90
  -- AND x.ObjectDatabaseName = 'prodbbymeadhocdb'
  -- AND x.ObjectTableName = 'tbend_lo_transfer'
 
 SELECT *
   FROM PDCRINFO.DBQLogTbl_Hst x
  WHERE x.QueryID = 163344815611721526 --163784815611962351
    AND x.LogDate = date -
	
replace view prodbbymeadhocvws.Rasc_CPUSum_Pct_90
 as
 locking row for access
SELECT 
		sum(CASE WHEN Username IN ('RASC_FORT_BCH') then AMPCPUTime
			else 0 end) RASC_CPU
		,sum(AMPCPUTime) Total_CPU
		,cast(100*RASC_CPU/Total_CPU as decimal(6,3)) pct
  from PDCRINFO.DBQLogTbl_Hst
 WHERE logDate > date - 92
 
SELECT *
  FROM prodbbymeadhocvws.Rasc_CPUSum_Pct --_90
  
SELECT 
		cast(100*sum(CASE WHEN Username IN ('RASC_FORT_BCH') then AMPCPUTime
			else 0 end)/sum(AMPCPUTime) as decimal(6,3)) pct
  from PDCRINFO.DBQLogTbl_Hst --PDCRINFO.DBQLSummaryTbl --DBQLSummaryTbl_Hst
 WHERE logDate > date - 92
 --WHERE UserName = 'RASC_FORT_BCH'
 --GROUP BY 1,2
 --sample 100
 
drop STATISTICS on PRODBBYMEADHOCWRK.GMR_STG2 column partition
;drop STATISTICS on PRODBBYMEADHOCWRK.GMR_STG2 column (partition, sls_key)

ALTER TABLE PRODBBYMEADHOCWRK.GMR_STG2 modify primary index
add range BETWEEN '2011-01-01' AND '2012-12-31' each interval '1' DAY

help STATISTICS PRODBBYMEADHOCWRK.GMR_STG2 


	
SELECT cast(421468225.45898283/2976925128.3898253 as decimal(6,3))

SELECT logDate, sum(AMPCPUTime)
  from PDCRINFO.DBQLogTbl_Hst --PDCRINFO.DBQLSummaryTbl --DBQLSummaryTbl_Hst
GROUP BY 1