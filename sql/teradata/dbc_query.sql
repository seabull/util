-- vim:syntax=on ft=sql sw=4 ts=4 et:

--
-- dbc.tvfields 
--      CommentString
--
-- dbc.tvm
--      CommentString
--

-- Get all table and view names in meadhoc
select 
		trim(databasename) dbName
		,trim(tablename)
		,case when position('_' in tablename) > 0 
				then substring(tablename from 1 for position('_' in tablename) - 1)
				else substring(tablename from 1 for 8)
				end TblNamePrefix
		,creatorName
		,trim(firstName) || ' ' || trim(lastName) fullName
 from dbc.tables t
 left join prodbbymeadhocdb.ldap_employee l
 		on t.creatorName = l.NTLogin
  where t.databasename in( 'prodbbymeadhocdb', 'prodbbymeadhocvws', 'prodbbymeadhocwrk')
 order by databasename, tablename

select  *
  from dbc.tables2
 where tvmName = ''
   and childCount > 0

select  *
  from dbc.All_RI_Parent
 where childDB = 'PRODBBYMEADHOCWRK'
    or parentDB = 'PRODBBYMEADHOCWRK'

--        case when position('_' in tablename) > 0 
--        case when position('_' in tablename) > 0 
--        		then (case when substring( tablename from 1 for position('_' in tablename) - 1 ) not in ('v','VWS') 
--        					then substring( tablename from 1 for position('_' in tablename) - 1) 
--        					else substring( tablename from position('_' in tablename) for 
--        														position('_' in 
--        																	substring(tablename from position('_' in tablename) for char_length(tablename) ) 
--        																) - 1
--        													)
--                      end
--        			)
--        		else substring(tablename from 1 for 8)
--        		end TblNamePrefix


--
-- Find Fastload Error Tables
--
select *
  from dbc.tables
 where tableKind = 'T'
    and trim(databasename) in ('prodbbymeadhocdb','prodbbymeadhocvws','prodbbymeadhocwrk')
 --   and (trim(tableName) like  ('%_ERR1' or trim(tablename) like '%_ERR2')
    and trim(tableName) like ANY ('%Z_ERR1',  '%Z_ERR2') ESCAPE 'Z'
--    and cast(createTimestamp as date) < date - 7
order by createTimestamp Desc

select 'Drop Table ' || trim(databasename) || '.' || trim(tablename)
        || ';  '
        --|| ' -- ' || trim(creatorName) || ':' || cast(createTimestamp as char(10)) || ':' || trim(lastAlterName) || ':' || cast(lastAlterTimestamp as char(10))
  from dbc.tables
 where tableKind = 'T'
    and trim(databasename) in ('prodbbymeadhocdb','prodbbymeadhocvws','prodbbymeadhocwrk')
 --   and (trim(tableName) like  ('%_ERR1' or trim(tablename) like '%_ERR2')
    and trim(tableName) like ANY ('%Z_ERR1',  '%Z_ERR2') ESCAPE 'Z'
    and cast(createTimestamp as date) < date - 7
    and cast(lastAlterTimestamp as date) < date - 7
    and trim(lastAlterName) <> 'RASC_FORT_BCH'
    and trim(creatorName) <> 'RASC_FORT_BCH'
order by createTimestamp Desc

select 'Drop Table ' || trim(databasename) || '.' || trim(tablename)
        || ';  '
        || ' -- ' || trim(creatorName) || ':' || cast(createTimestamp as char(10)) || ':' || trim(lastAlterName) 
        || ':' || trim(coalesce(FirstName, 'Unknown')) || ' ' || trim(coalesce(LastName, 'Unknown'))
        || ':' || cast(lastAlterTimestamp as char(10))
  from dbc.tables t
  	left outer join prodbbymeadhocdb.ldap_employee
  				on trim(mailNickName) = trim(t.lastAlterName)
 where tableKind = 'T'
    and trim(databasename) in ('prodbbymeadhocdb','prodbbymeadhocvws','prodbbymeadhocwrk')
 --   and (trim(tableName) like  ('%_ERR1' or trim(tablename) like '%_ERR2')
    and trim(tableName) like ANY ('%Z_ERR1',  '%Z_ERR2') ESCAPE 'Z'
    and cast(createTimestamp as Date)  < cast(current_date - 7 as Date)
    and cast(lastAlterTimestamp as Date) < cast(current_date - 7 as Date)
    and trim(lastAlterName) <> 'RASC_FORT_BCH'
    and trim(creatorName) <> 'RASC_FORT_BCH'

-- You can use the following query to retrieve a list of tables and join indexes that have PPIs and
-- their index constraint text:
--
SELECT 
    DatabaseName
    , TableName (TITLE 'Table/Join Index Name')
    , ConstraintText
  FROM DBC.IndexConstraints
 WHERE ConstraintType = 'Q'
ORDER BY DatabaseName
        , TableName;

-- You can use the following query to retrieve a list of tables and join indexes that have SLPPIs:
--
SELECT 
        DatabaseName
        , TableName (TITLE 'Table/Join Index Name')
  FROM DBC.IndexConstraints
 WHERE ConstraintType = 'Q'
   AND ( SUBSTRING(ConstraintText FROM 1 FOR 13) < 'CHECK (/*02*/'
    OR SUBSTRING(ConstraintText FROM 1 FOR 13) > 'CHECK (/*15*/')
ORDER BY DatabaseName
        , TableName;


-- You can use a query like the following to retrieve index constraint information for each of the
-- multilevel partitioned objects:
--
SELECT 
        *
  FROM DBC.TableConstraints
 WHERE ConstraintType = 'Q'
   AND SUBSTRING(TableCheck FROM 1 FOR 13) >= 'CHECK (/*02*/'
   AND SUBSTRING(TableCheck FROM 1 FOR 13) <= 'CHECK (/*15*/';

-- You can use the following query to find the average number of rows per combined partition:
--
SELECT AVG(pc)
  FROM (
        SELECT COUNT(*) AS pc
        FROM t
        GROUP BY PARTITION
    ) AS pt;

-- Assuming the average block size is b and the row size is r, you can use the following query to
-- find the average number of data blocks per combined partition:
--
USING (b FLOAT, r FLOAT)
SELECT (:r / :b) * AVG(pc)
    FROM (
            SELECT COUNT(*) AS pc
            FROM t
            GROUP BY PARTITION
        ) AS pt;


---------------
Help view dbc.qrylog

UserID                        	?	Identifier for the user that issued the query.
UserName                      	?	Name of the user that issued the query.
DefaultDatabase               	?	Default Database used by the query.
AcctString                    	?	Unexpanded Account String under which the user issued the query.
ExpandAcctString              	?	If account expansion is invoked, account string in expanded format.
SessionID                     	?	SessionID of the query.
LogicalHostID                 	?	Logical Host ID from which query was executed.
RequestNum                    	?	Host Request number for this query within the session.
InternalRequestNum            	?	Internal Request number when StoredProcedures used within the session.
LogonDateTime                 	?	Date (YYYY-MM-DD) and Time (HH:MM:SS)that the user logged onto the DBS.
AcctStringTime                	?	Time (HH:MM:SS) if account string contains $T.
AcctStringHour                	?	Hour (HH) if account string contains $H.
AcctStringDate                	?	Date (YY/MM/DD) if account string contains $D.
AppID                         	?	The application ID under which the query is submitted.
ClientID                      	?	The client ID under which the query is submitted.
ClientAddr                    	?	The client address of the submitted query.
QueryBand                     	?	The query band under which the query is submitted.
ProfileID                     	?	The profile ID under which the user submitted the query.
StartTime                     	?	Time this query was submitted. Format YYYY-MM-DD HH:MM:SS.99
FirstStepTime                 	?	Time first step for this query was dispatched. 
LastRespTime                  	?	Time last response was sent to the host.
ElapsedTime                   	?	Difference between last response time and start time. Format HH:MM:SS.999999
NumSteps                      	?	Total number of steps for this query.
NumStepswPar                  	?	Total number of (level 1) steps with parallel steps.
MaxStepsInPar                 	?	Maximum number of (level 2) steps done in parallel for this query.
NumResultRows                 	?	The total number of rows returned to the user.
TotalIOCount                  	?	The total I/O count from all the steps.
TotalCPUTime                  	?	The total CPU time used by this query.
ErrorCode                     	?	Either the error code, or 0 if no error occurred.
ErrorText                     	?	Text of the error message or NULL if no error.
WarningOnly                   	?	T if the error was reported while running TDWM in warning mode.
AbortFlag                     	?	T if the query was aborted.
CacheFlag                     	?	Null if query was not processed from the step cache, T if executed from cache.
QueryText                     	?	Defaults to the first 200 characters of SQL. User can request another size.
StatementType                 	?	The type of statement issued by the query.  20 characters describe type.
NumOfActiveAMPs               	?	The number of AMPS that were active for this query.
HotAmp1CPU                    	?	CPU time of the highest utilized AMP for the query.
HotCPUAmpNumber               	?	Number of the AMP with highest CPU time for the query.
LowAmp1CPU                    	?	CPU time of the lowest utilized AMP for the query.
HotAmp1IO                     	?	IO Count of the highest utilized AMP for the query.
HotIOAmpNumber                	?	Number of the AMP with highest IO count for the query.
LowAmp1IO                     	?	IO Count of the lowest utilized AMP for the query.
SpoolUsage                    	?	Number of bytes used for spool in the query.
----------------------------------

SELECT UserName
	, QueryText
	, ElapsedTime
	, RANK() OVER(ORDER BY ElapsedTime DESC) AS RNK
	,STARTTIME
FROM DBC.QRYLOG
WHERE STARTTIME(DATE) >= CURRENT_DATE-1
QUALIFY RNK <= 10



select username
	,queryText
	,ElapsedTime
	,StartTime
 from dbc.qrylog
where starttime between timestamp '2008-09-29 21:29:44' and timestamp '2008-09-29 22:00:00'



--
-- Best Buy
--
REPLACE VIEW PRODETLSTAGE.VWEN_TDATA_STATS_INFO AS 
    LOCKING TABLE DBC.IndexStats FOR ACCESS
    LOCKING TABLE DBC.ColumnStats FOR ACCESS
    LOCKING TABLE DBC.MultiColumnStats FOR ACCESS
     
    SELECT DatabaseName, TableName, ColumnName,
         
       ColumnCount ,
       StatsType ,
        Collect_Date as CollectDate,
        Collect_Time as CollectTime,
        CAST(CAST((Collect_Date (FORMAT 'YYYY-MM-DD')) AS CHAR(10)) || ' ' || CAST(Collect_Time AS CHAR(11)) AS TIMESTAMP) AS CollectDateTime,
       CASE SampleSize WHEN 0 THEN 100 ELSE SampleSize END AS SampleSize,
       SampleUsed ,
       ZeroStats ,
         
       case when ZeroStats = 'N' then 
             (-1**(NumRowsw1 / 32768)) 
            * (2**((NumRowsw1/16 mod 2048) - 1023)) 
            * (1 + ((NumRowsw1 mod 16) * 2**-4) + (NumRowsw2 * 2**-20)
                 + (NumRowsw3 * 2**-36) + (NumRowsw4 * 2**-52)) 
            else 0 end AS RowCount,
         
       case when ZeroStats = 'N' then 
             (-1**(NumValuesw1 / 32768)) 
            * (2**((NumValuesw1/16 mod 2048) - 1023)) 
            * (1 + ((NumValuesw1 mod 16) * 2**-4) + (NumValuesw2 * 2**-20)
                 + (NumValuesw3 * 2**-36) + (NumValuesw4 * 2**-52)) 
            else 0 end AS DistinctColumnValues,
         
        case when ZeroStats = 'N' and NumNullsw1 > 0 THEN
             (-1**(NumNullsw1 / 32768)) 
            * (2**((NumNullsw1/16 mod 2048) - 1023)) 
            * (1 + ((NumNullsw1 mod 16) * 2**-4) + (NumNullsw2 * 2**-20)
                 + (NumNullsw3 * 2**-36) + (NumNullsw4 * 2**-52)) 
            ELSE 0 END AS CountOfNulls,
     
         
        case when ZeroStats = 'N' and AllNulls='N' then 
             (-1**(ModeFreqw1 / 32768)) 
            * (2**((ModeFreqw1/16 mod 2048) - 1023)) 
            * (1 + ((ModeFreqw1 mod 16) * 2**-4) + (ModeFreqw2 * 2**-20)
                 + (ModeFreqw3 * 2**-36) + (ModeFreqw4 * 2**-52)) 
            else 0 end as MaximumFrequency 
     
    FROM
      (
       SELECT
         DatabaseName,
         TableName,
         ColumnName,
         ColumnCount,
         Stats,
         StatsType,
         case when substr(Stats, 11, 1) = '01'xb then 'Y' else 'N' end as SampleUsed,
         case when Stats is null then null
                when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)='0000000000000000'xb then 'Y'
                else 'N' end as ZeroStats,
         case when Stats is null then null
                when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)<>'0000000000000000'xb then 'Y'
                else 'N' end as AllNulls,
     
         (
           (HASHBUCKET
             (SUBSTR(Stats, 2, 1) ||
              SUBSTR(Stats, 1, 1) (BYTE(4))
             )  - 1900
           ) * 10000
           +
           (HASHBUCKET
             ('00'xb || SUBSTR(Stats, 3, 1) (BYTE(4))
             )
           ) * 100
           +
           (HASHBUCKET
             (
              '00'xb || SUBSTR(Stats, 4, 1) (BYTE(4))
             )
           )
         ) (DATE) AS Collect_Date,
     
         (CAST(
           (HASHBUCKET
             (CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4))
             ) (FORMAT '99:')
           ) ||
           (HASHBUCKET
             (CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4))
             ) (FORMAT '99:')
           ) ||
           (HASHBUCKET
             (CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4))
             ) (FORMAT '99.')
           ) ||
           (HASHBUCKET
             (CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4))
             ) (FORMAT '99')
           ) AS TIME(2))
         ) AS Collect_Time,
     
         HASHBUCKET
          ('00'xb || SUBSTR(Stats, 12, 1) (BYTE(4))) AS SampleSize,
     
         HASHBUCKET(substr(Stats, 16+8, 1)
                 || substr(Stats, 16+7, 1) (byte(4))) as NumNullsw1,
         HASHBUCKET(substr(Stats, 16+6, 1)
                 || substr(Stats, 16+5, 1) (byte(4))) as NumNullsw2,
         HASHBUCKET(substr(Stats, 16+4, 1)
                 || substr(Stats, 16+3, 1) (byte(4))) as NumNullsw3,
         HASHBUCKET(substr(Stats, 16+2, 1)
                 || substr(Stats, 16+1, 1) (byte(4))) as NumNullsw4,
     
         HASHBUCKET(substr(Stats, 48+Offset+8, 1)
                 || substr(Stats, 48+Offset+7, 1) (byte(4))) as ModeFreqw1,
         HASHBUCKET(substr(Stats, 48+Offset+6, 1)
                 || substr(Stats, 48+Offset+5, 1) (byte(4))) as ModeFreqw2,
         HASHBUCKET(substr(Stats, 48+Offset+4, 1)
                 || substr(Stats, 48+Offset+3, 1) (byte(4))) as ModeFreqw3,
         HASHBUCKET(substr(Stats, 48+Offset+2, 1)
                 || substr(Stats, 48+Offset+1, 1) (byte(4))) as ModeFreqw4,
     
         HASHBUCKET(substr(Stats, 56+Offset+8, 1)
                 || substr(Stats, 56+Offset+7, 1) (byte(4))) as NumValuesw1,
         HASHBUCKET(substr(Stats, 56+Offset+6, 1)
                 || substr(Stats, 56+Offset+5, 1) (byte(4))) as NumValuesw2,
         HASHBUCKET(substr(Stats, 56+Offset+4, 1)
                 || substr(Stats, 56+Offset+3, 1) (byte(4))) as NumValuesw3,
         HASHBUCKET(substr(Stats, 56+Offset+2, 1)
                 || substr(Stats, 56+Offset+1, 1) (byte(4))) as NumValuesw4,
     
         HASHBUCKET(substr(Stats, 64+Offset+8, 1)
                 || substr(Stats, 64+Offset+7, 1) (byte(4))) as NumRowsw1,
         HASHBUCKET(substr(Stats, 64+Offset+6, 1)
                 || substr(Stats, 64+Offset+5, 1) (byte(4))) as NumRowsw2,
         HASHBUCKET(substr(Stats, 64+Offset+4, 1)
                 || substr(Stats, 64+Offset+3, 1) (byte(4))) as NumRowsw3,
         HASHBUCKET(substr(Stats, 64+Offset+2, 1)
                 || substr(Stats, 64+Offset+1, 1) (byte(4))) as NumRowsw4
     
       FROM
        (
         SELECT
           DatabaseName,
           TableName,
           MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' 
    END) ||
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
           MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END) AS ColumnName,
           COUNT(*) AS ColumnCount,
           'I' AS StatsType,
           
           
           MAX(CASE
                 WHEN SUBSTR(IndexStatistics, 27, 1) = '00'XB THEN 16
                 ELSE 0
               END) AS Offset,
     
           MAX(SUBSTR(IndexStatistics, 1, 128)) AS Stats
         FROM
           dbc.indexstats
         GROUP BY
           DatabaseName,
           TableName,
           StatsType,
           IndexNumber
     
         UNION ALL
     
         SELECT
           DatabaseName,
           TableName,
           MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' 
    END) ||
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
           MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END) AS ColumnName,
           COUNT(*) AS ColumnCount,
           'M' AS StatsType,
           
           
           MAX(CASE
                 WHEN SUBSTR(ColumnsStatistics, 27, 1) = '00'XB THEN 16
                 ELSE 0
               END) AS Offset,
     
           MAX(SUBSTR(ColumnsStatistics, 1, 128)) AS Stats
         FROM
           dbc.MultiColumnStats
         GROUP BY
           DatabaseName,
           TableName,
           StatsType,
           StatisticsID
     
         UNION ALL
     
         SELECT
           DatabaseName,
           TableName,
           ColumnName,
           1 AS ColumnCount,
           'C' AS StatsType,
     
           
           
           CASE
             WHEN SUBSTR(fieldStatistics, 27, 1) = '00'XB THEN 16
             ELSE 0
           END AS Offset,
     
           SUBSTR(fieldstatistics, 1, 128) AS Stats
         FROM
           dbc.columnstats
         ) dt
       WHERE Stats IS NOT NULL
      ) dt;

select
    d.databasenamei as DatabaseName
    , t.tvmnamei as TableName
    , f.fieldname as ColumnName
    , t.CreateUID TblCreator
    , t.CreateTimeStamp TblCreateTM
    , cast(
        ( case
            when substr(fieldstatistics,1,1) = 'D8'XB then '2008-'
            when substr(fieldstatistics,1,1) = 'D7'XB then '2007-'
            when substr(fieldstatistics,1,1) = 'D6'XB then '2006-'
            when substr(fieldstatistics,1,1) = 'D5'XB then '2005-'
            when substr(fieldstatistics,1,1) = 'D4'XB then '2004-'
            when substr(fieldstatistics,1,1) = 'D3'XB then '2003-'
            when substr(fieldstatistics,1,1) = 'D2'XB then '2002-'
            when substr(fieldstatistics,1,1) = 'D1'XB then '2001-'
            when substr(fieldstatistics,1,1) = 'D0'XB then '2000-'
            when substr(fieldstatistics,1,1) = 'CF'XB then '1999-'
            when substr(fieldstatistics,1,1) = 'CE'XB then '1998-'
            else NULL
        end)||
        (case when substr(fieldstatistics,3,1) = '01'XB then '01-'
            when substr(fieldstatistics,3,1) = '02'XB then '02-'
            when substr(fieldstatistics,3,1) = '03'XB then '03-'
            when substr(fieldstatistics,3,1) = '04'XB then '04-'
            when substr(fieldstatistics,3,1) = '05'XB then '05-'
            when substr(fieldstatistics,3,1) = '06'XB then '06-'
            when substr(fieldstatistics,3,1) = '07'XB then '07-'
            when substr(fieldstatistics,3,1) = '08'XB then '08-'
            when substr(fieldstatistics,3,1) = '09'XB then '09-'
            when substr(fieldstatistics,3,1) = '0A'XB then '10-'
            when substr(fieldstatistics,3,1) = '0B'XB then '11-'
            when substr(fieldstatistics,3,1) = '0C'XB then '12-'
            else 'xx-'
            end)||
        (case when substr(fieldstatistics,4,1) = '01'XB then '01'
            when substr(fieldstatistics,4,1) = '02'XB then '02'
            when substr(fieldstatistics,4,1) = '03'XB then '03'
            when substr(fieldstatistics,4,1) = '04'XB then '04'
            when substr(fieldstatistics,4,1) = '05'XB then '05'
            when substr(fieldstatistics,4,1) = '06'XB then '06'
            when substr(fieldstatistics,4,1) = '07'XB then '07'
            when substr(fieldstatistics,4,1) = '08'XB then '08'
            when substr(fieldstatistics,4,1) = '09'XB then '09'
            when substr(fieldstatistics,4,1) = '0A'XB then '10'
            when substr(fieldstatistics,4,1) = '0B'XB then '11'
            when substr(fieldstatistics,4,1) = '0C'XB then '12'
            when substr(fieldstatistics,4,1) = '0D'XB then '13'
            when substr(fieldstatistics,4,1) = '0E'XB then '14'
            when substr(fieldstatistics,4,1) = '0F'XB then '15'
            when substr(fieldstatistics,4,1) = '10'XB then '16'
            when substr(fieldstatistics,4,1) = '11'XB then '17'
            when substr(fieldstatistics,4,1) = '12'XB then '18'
            when substr(fieldstatistics,4,1) = '13'XB then '19'
            when substr(fieldstatistics,4,1) = '14'XB then '20'
            when substr(fieldstatistics,4,1) = '15'XB then '21'
            when substr(fieldstatistics,4,1) = '16'XB then '22'
            when substr(fieldstatistics,4,1) = '17'XB then '23'
            when substr(fieldstatistics,4,1) = '18'XB then '24'
            when substr(fieldstatistics,4,1) = '19'XB then '25'
            when substr(fieldstatistics,4,1) = '1A'XB then '26'
            when substr(fieldstatistics,4,1) = '1B'XB then '27'
            when substr(fieldstatistics,4,1) = '1C'XB then '28'
            when substr(fieldstatistics,4,1) = '1D'XB then '29'
            when substr(fieldstatistics,4,1) = '1E'XB then '30'
            when substr(fieldstatistics,4,1) = '1F'XB then '31'
            else 'xx-'
            end) as char(10)
        )
  from 
         dbc.TVFields f
        ,dbc.tvm t
        ,dbc.dbase d
 where f.TableID = t.tvmID
   and d.databaseID = t.databaseID
   and d.databaseName = 'prodbbymeadhocdb'


--
-- ReCreate Collect Stats script
--
SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) 
        || 
                Case 
                        When    indextype = 'M' Then ' column (' 
                        Else    ' index (' 
                End     
        || indexcols || ');' 
FROM    ( 
SELECT  databasename , tablename , indexnumber , indextype, MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 1 THEN TRIM ( columnname ) 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 2 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 3 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 4 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 5 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 6 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 7 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) || MAXIMUM ( 
                CASE 
                        WHEN    columnposition = 8 THEN ',' || TRIM ( columnname ) 
                        ELSE    '' 
                END     ) AS indexcols 
FROM    ( 
SELECT  c.databasenamei AS databasename 
,       b.tvmnamei AS tablename 
,       d.indexnumber AS indexnumber 
,       d.indextype AS indextype 
,       d.fieldposition AS columnposition 
,       a.fieldname AS columnname 
FROM    dbc.tvfields a 
,       dbc.tvm b 
,       dbc.dbase c 
,       dbc.indexes d 
WHERE   a.tableid = b.tvmid 
        AND     b.databaseid = c.databaseid 
        AND     d.fieldid = a.fieldid 
        AND     d.tableid = b.tvmid 
        AND     d.databaseid = c.databaseid 
        AND     ( d.databaseid , d.tableid , d.indexnumber )  IN ( 
SELECT  databaseid , tableid , indexnumber 
FROM    dbc.indexes 
WHERE   fieldposition = 1 
        AND     indexstatistics IS NOT NULL ) 
        AND     databasename = 'MY_DBNAME' ) a 
GROUP   BY 1 , 2 , 3, 4 ) b 
UNION 
SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) || ' column (' || indexcols || ');'
FROM    ( 
        SELECT  databasename , tablename , TRIM ( columnname ) AS indexcols 
        FROM    ( 
                SELECT  c.databasenamei AS databasename , b.tvmnamei AS tablename , a.fieldname AS columnname 
                FROM    dbc.tvfields a , dbc.tvm b , dbc.dbase c 
                WHERE   a.tableid = b.tvmid 
                  AND   b.databaseid = c.databaseid 
                  AND   a.fieldstatistics IS NOT NULL 
                  AND   databasename = 'MY_DBNAME' 
                 ) a 
        GROUP   BY 1 , 2 , 3 
        ) b ; 


--**********************************************************************************

select
        c.databasenamei as DatabaseName
        , b.tvmnamei as TableName
        , a.fieldname as ColumnName
        , substr(fieldstatistics,12,8)
  from
        dbc.tvfields a,
        dbc.tvm b,
        dbc.dbase c
 where a.tableid = b.tvmid
   and b.tablekind = 'T'
   and b.databaseid = c.databaseid
   and upper(trim(c.databasenamei)) in ('prodbbymeadhocdb')
   and a.fieldstatistics is not null

/*
--**********************************************************************************
Q: Where can I find out more about what’s in the column “fieldstatistics” in dbc.tvfields? 
Specifically, if the date the stats were collected is buried in there, is the number of unique values in there as well?

We keep the detailed information that comes from collecting statistics in the column called “fieldstatistics,” which contains the following information:

• A varbyte indicates the length at the very first 2 bytes.
• The next 8 bytes represent the year, month, day, hour, minute, second and centisecond that statistics were collected, with the year allocating the first 2 bytes and everything else taking up 1 byte each.
• The next 4 bytes represent the “version” of statistics. The actual value resides in the upper 2 bytes.
• The next 8 bytes represent the number of NULLs.
• The next 2 bytes represent the number of intervals.
• The next 2 bytes represent whether the statistics are numeric. The actual value resides in the first byte.
• The rest of the field represents the interval data. Each interval occupies 40 bytes, which are divided into 5 fields of 8 bytes each.

    1. The first 40 bytes represent “interval 0,” which contains characteristics for the entire column/index:

        a. The first field represents the “min” value for the entire column/index.
        b. The second field represents the “mode” value for the entire column/index.
        c. The third field represents the “mode frequency.”
        d. The fourth field represents the “number of uniques.”
        e. The fifth field represents the “number of rows.”

    2. The rest of the intervals contain the actual “interval data”:

        a. The first field represents the “max” value for the interval.
        b. The second field represents the “mode” value for the interval.
        c. The third field represents the “mode frequency.”
        d. The fourth field represents the “non-modal” value, which is the total number of distinct non-modal values in the interval.
        e. The fifth field represents the “number of rows” for the fourth field (d).
*/

--The following query can be used to create a report that lists dbase named, column names, and the date statistics were last collected.
--You can specify the databasenames, table names, etc., if you want to limit the objects referenced.

select
        c.databasenamei as DatabaseName,
        b.tvmnamei as TableName,
        a.fieldname as ColumnName,
        cast(
                (case when substr(fieldstatistics,1,1) = 'D2'XB then '2002-'
                        when substr(fieldstatistics,1,1) = 'D1'XB then '2001-'
                        when substr(fieldstatistics,1,1) = 'D0'XB then '2000-'
                        when substr(fieldstatistics,1,1) = 'CF'XB then '1999-'
                        when substr(fieldstatistics,1,1) = 'CE'XB then '1998-'
                        else NULL
                 end)||
                (case when substr(fieldstatistics,3,1) = '01'XB then '01-'
                        when substr(fieldstatistics,3,1) = '02'XB then '02-'
                        when substr(fieldstatistics,3,1) = '03'XB then '03-'
                        when substr(fieldstatistics,3,1) = '04'XB then '04-'
                        when substr(fieldstatistics,3,1) = '05'XB then '05-'
                        when substr(fieldstatistics,3,1) = '06'XB then '06-'
                        when substr(fieldstatistics,3,1) = '07'XB then '07-'
                        when substr(fieldstatistics,3,1) = '08'XB then '08-'
                        when substr(fieldstatistics,3,1) = '09'XB then '09-'
                        when substr(fieldstatistics,3,1) = '0A'XB then '10-'
                        when substr(fieldstatistics,3,1) = '0B'XB then '11-'
                        when substr(fieldstatistics,3,1) = '0C'XB then '12-'
                        else 'xx-'
                end)||
                (case when substr(fieldstatistics,4,1) = '01'XB then '01'
                        when substr(fieldstatistics,4,1) = '02'XB then '02'
                        when substr(fieldstatistics,4,1) = '03'XB then '03'
                        when substr(fieldstatistics,4,1) = '04'XB then '04'
                        when substr(fieldstatistics,4,1) = '05'XB then '05'
                        when substr(fieldstatistics,4,1) = '06'XB then '06'
                        when substr(fieldstatistics,4,1) = '07'XB then '07'
                        when substr(fieldstatistics,4,1) = '08'XB then '08'
                        when substr(fieldstatistics,4,1) = '09'XB then '09'
                        when substr(fieldstatistics,4,1) = '0A'XB then '10'
                        when substr(fieldstatistics,4,1) = '0B'XB then '11'
                        when substr(fieldstatistics,4,1) = '0C'XB then '12'
                        when substr(fieldstatistics,4,1) = '0D'XB then '13'
                        when substr(fieldstatistics,4,1) = '0E'XB then '14'
                        when substr(fieldstatistics,4,1) = '0F'XB then '15'
                        when substr(fieldstatistics,4,1) = '10'XB then '16'
                        when substr(fieldstatistics,4,1) = '11'XB then '17'
                        when substr(fieldstatistics,4,1) = '12'XB then '18'
                        when substr(fieldstatistics,4,1) = '13'XB then '19'
                        when substr(fieldstatistics,4,1) = '14'XB then '20'
                        when substr(fieldstatistics,4,1) = '15'XB then '21'
                        when substr(fieldstatistics,4,1) = '16'XB then '22'
                        when substr(fieldstatistics,4,1) = '17'XB then '23'
                        when substr(fieldstatistics,4,1) = '18'XB then '24'
                        when substr(fieldstatistics,4,1) = '19'XB then '25'
                        when substr(fieldstatistics,4,1) = '1A'XB then '26'
                        when substr(fieldstatistics,4,1) = '1B'XB then '27'
                        when substr(fieldstatistics,4,1) = '1C'XB then '28'
                        when substr(fieldstatistics,4,1) = '1D'XB then '29'
                        when substr(fieldstatistics,4,1) = '1E'XB then '30'
                        when substr(fieldstatistics,4,1) = '1F'XB then '31'
                        else 'xx'
                end)as date
        ) as CollectionDate,
        cast(substr(cast(a.lastaltertimestamp as char(32)) ,1,10) as date) as LastAlter,
        date - collectiondate as FromCurrent,
        lastalter - collectiondate as FromAlter
  from
        dbc.tvfields a,
        dbc.tvm b,
        dbc.dbase c
 where a.tableid = b.tvmid
   and b.tablekind = 'T'
   and b.databaseid = c.databaseid
   and upper(trim(c.databasenamei)) in ('prodbbymeadhocdb')
   and a.fieldstatistics is not null
order by 1,2,3
;

/*
--****************************************
Note that the query does not return results for compound indexes, because this data is not kept in TVFIELDS. 
A parallel query that will return the dates for compound indices follows:
*/

sel unique
        c.databasenamei as DatabaseName
        , b.tvmnamei as TableName
        , d.indexname
        , cast((case when substr(IndexStatistics,1,1) = 'D2'XB then '2002-'
        when substr(IndexStatistics,1,1) = 'D1'XB then '2001-'
        when substr(IndexStatistics,1,1) = 'D0'XB then '2000-'
        when substr(IndexStatistics,1,1) = 'CF'XB then '1999-'
        when substr(IndexStatistics,1,1) = 'CE'XB then '1998-'
        else NULL end)||
        (case when substr(IndexStatistics,3,1) = '01'XB then '01-'
        when substr(IndexStatistics,3,1) = '02'XB then '02-'
        when substr(IndexStatistics,3,1) = '03'XB then '03-'
        when substr(IndexStatistics,3,1) = '04'XB then '04-'
        when substr(IndexStatistics,3,1) = '05'XB then '05-'
        when substr(IndexStatistics,3,1) = '06'XB then '06-'
        when substr(IndexStatistics,3,1) = '07'XB then '07-'
        when substr(IndexStatistics,3,1) = '08'XB then '08-'
        when substr(IndexStatistics,3,1) = '09'XB then '09-'
        when substr(IndexStatistics,3,1) = '0A'XB then '10-'
        when substr(IndexStatistics,3,1) = '0B'XB
        then '11-' when substr(IndexStatistics,3,1) = '0C'XB
        then '12-' else 'xx-'
        end)||
        (case when substr(IndexStatistics,4,1) = '01'XB then '01'
        when substr(IndexStatistics,4,1) = '02'XB then '02'
        when substr(IndexStatistics,4,1) = '03'XB then '03'
        when substr(IndexStatistics,4,1) = '04'XB then '04'
        when substr(IndexStatistics,4,1) = '05'XB then '05'
        when substr(IndexStatistics,4,1) = '06'XB then '06'
        when substr(IndexStatistics,4,1) = '07'XB then '07'
        when substr(IndexStatistics,4,1) = '08'XB then '08'
        when substr(IndexStatistics,4,1) = '09'XB then '09'
        when substr(IndexStatistics,4,1) = '0A'XB then '10'
        when substr(IndexStatistics,4,1) = '0B'XB then '11'
        when substr(IndexStatistics,4,1) = '0C'XB then '12'
        when substr(IndexStatistics,4,1) = '0D'XB then '13'
        when substr(IndexStatistics,4,1) = '0E'XB then '14'
        when substr(IndexStatistics,4,1) = '0F'XB then '15'
        when substr(IndexStatistics,4,1) = '10'XB then '16'
        when substr(IndexStatistics,4,1) = '11'XB then '17'
        when substr(IndexStatistics,4,1) = '12'XB then '18'
        when substr(IndexStatistics,4,1) = '13'XB then '19'
        when substr(IndexStatistics,4,1) = '14'XB then '20'
        when substr(IndexStatistics,4,1) = '15'XB then '21'
        when substr(IndexStatistics,4,1) = '16'XB then '22'
        when substr(IndexStatistics,4,1) = '17'XB then '23'
        when substr(IndexStatistics,4,1) = '18'XB then '24'
        when substr(IndexStatistics,4,1) = '19'XB then '25'
        when substr(IndexStatistics,4,1) = '1A'XB then '26'
        when substr(IndexStatistics,4,1) = '1B'XB then '27'
        when substr(IndexStatistics,4,1) = '1C'XB then '28'
        when substr(IndexStatistics,4,1) = '1D'XB then '29'
        when substr(IndexStatistics,4,1) = '1E'XB then '30'
        when substr(IndexStatistics,4,1) = '1F'XB then '31'
        else 'xx'
        end)as date) as CollectionDate
        , cast(substr(cast(a.lastaltertimestamp as char(32))
                ,1,10) as date) as LastAlter
        , date - collectiondate as FromCurrent
        , lastalter - collectiondate as FromAlter
--
  from
        dbc.indexes a,
        dbc.tvm b,
        dbc.dbase c,
        dbc.indices d
--
 where a.tableid = b.tvmid
   and d.indexnumber = a.indexnumber
   and b.tablekind = 'T'
   and b.databaseid = c.databaseid
   and upper(trim(c.databasenamei)) in (' <<<>>>')
   and upper(trim(d.databasename)) = upper(trim(c.databasenamei))
   and a.IndexStatistics is not null
   and d.indexname is not null
order by 1,2,3
;

select collectDate
        ,collectTime
        ,databasename
        ,tablename
        ,columnname
        ,(-1**(NumValuesw1 / 32768)) * (2**((NumValuesw1 / 16 mod 2048) - 1023))
                        * (1 + ((NumValuesw1 mod 16) * 2**-4)
                        + (NumValuesw2 * 2**-20)
                        + (NumValuesw3 * 2**-36)
                        + (NumValuesw4 * 2**-52)) (decimal(18,0)) AS NumValues
        ,tblCreator
        ,tblCreateTm
        ,tblLastAlterID
        ,tblLastAlterTm
        ,tblLastAccessTm
        ,tblCreatorName
        ,tblOSUserName
from (select collectDate
                ,collectTime
                ,databasename
                ,tablename
                ,columnname
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 8, 1)
                        || SUBSTR(Stats, 48 + offset + 7, 1) (BYTE(4))) AS NumValuesw1
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 6, 1)
                        || SUBSTR(Stats, 48 + offset + 5, 1) (BYTE(4))) AS NumValuesw2
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 4, 1)
                        || SUBSTR(Stats, 48 + offset + 3, 1) (BYTE(4))) AS NumValuesw3
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 2, 1)
                        || SUBSTR(Stats, 48 + offset + 1, 1) (BYTE(4))) AS NumValuesw4
                ,tblCreator
                ,tblCreateTm
                ,tblLastAlterID
                ,tblLastAlterTm
                ,tblLastAccessTm
                ,tblCreatorName
                ,tblOSUserName
        from (SELECT 
                        (       (HASHBUCKET(SUBSTR(Stats, 2, 1) || SUBSTR(Stats, 1, 1) (BYTE(4)) ) - 1900 ) * 10000
                                +
                                (HASHBUCKET('00'xb || SUBSTR(Stats, 3, 1) (BYTE(4)) ) ) * 100
                                +
                                (HASHBUCKET('00'xb || SUBSTR(Stats, 4, 1) (BYTE(4)) ) )
                        ) (DATE) AS CollectDate
                        ,(CAST ( (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4)) ) (FORMAT '99:') )
                                ||
                                (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4)) ) (FORMAT '99:') )
                                ||
                                (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4)) ) (FORMAT '99.') )
                                ||
                                (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4)) ) (FORMAT '99' ) ) AS TIME(2))
                          ) AS CollectTime
                        ,databasename
                        ,t.TVMNameI as TableName
                        ,f.fieldName ColumnName
                        ,CASE WHEN SUBSTR(fieldStatistics, 23, 1) = '00'XB
                                THEN 16
                                ELSE 0
                         END AS Offset
                        ,SUBSTR(fieldstatistics, 1, 80) AS Stats
                        ,t.createUID    as tblCreator
                        ,t.createTimeStamp as tblCreateTm
                        ,t.lastAlterUID as tblLastAlterID
                        ,t.lastAlterTimestamp as tblLastAlterTm
                        ,t.lastAccessTimestamp as tblLastAccessTm
                        ,t.CreatorName as tblCreatorName
                        ,t.OSUserName as tblOSUserName
                from 
                        dbc.TVFields f
                        ,dbc.Dbase d
                        ,dbc.TVM t
                        --dbc.columnstats
               where d.databasename ='prodbbymeadhocdb'
                 --and tablename = ''
                 and t.databaseID = d.databaseID
                 and t.tvmID = f.tableID
                 and f.fieldstatistics is not null
              ) D1
) D2
;

create view prodbbymeadhocvws.rasc_tbl_stats
as 
locking row for access
select
        max(collectDate) latestCollectDt
        ,databasename
        ,tablename
         ,max((-1**(NumValuesw1 / 32768)) * (2**((NumValuesw1 / 16 mod 2048) - 1023))
                * (1 + ((NumValuesw1 mod 16) * 2**-4)
                + (NumValuesw2 * 2**-20)
                + (NumValuesw3 * 2**-36)
                + (NumValuesw4 * 2**-52))
                ) (decimal(18,0)) AS NumValues
        ,tblCreatorName
        ,tblCreatorFullName
        ,tblLastAccessTm
        ,tblLastAlterID
        ,tblLastAlterTm
  from (
        select 
 		 collectDate
                ,collectTime
                ,databasename
                ,tablename
                ,columnname
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 8, 1)
                        || SUBSTR(Stats, 48 + offset + 7, 1) (BYTE(4))) AS NumValuesw1
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 6, 1)
                        || SUBSTR(Stats, 48 + offset + 5, 1) (BYTE(4))) AS NumValuesw2
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 4, 1)
                        || SUBSTR(Stats, 48 + offset + 3, 1) (BYTE(4))) AS NumValuesw3
                ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 2, 1)
                        || SUBSTR(Stats, 48 + offset + 1, 1) (BYTE(4))) AS NumValuesw4
                ,tblCreator
                ,tblCreateTm
                ,tblLastAlterID
                ,tblLastAlterTm
                ,tblLastAccessTm
                ,tblCreatorName

show table 
;

select
  from prodbbymeadhocdb
                ,(l.Firstname || ' ' || l.lastName) as tblCreatorFullName
                ,tblOSUserName
          from prodbbymeadhocvws.rasc_tblcolumn_stats r
        left join prodbbymeadhocvws.ldap_employee l
  		on r.tblCreatorName = l.ldap_ID
        ) x
group by  2, 3, 5,6,7,8,9

order by 1

select
        max(latestCollectDt) latestCollectDt
        ,databasename
        ,tablename
        ,min(NumValues) NumValues
        ,tblCreatorName
        ,tblCreatorFullName
        ,tblLastAccessTm
        --,tblLastAlterID
        ,tblLastAlterTm
  from
(
        select
                max(collectDate) latestCollectDt
                ,databasename
                ,tablename
                 ,max((-1**(NumValuesw1 / 32768)) * (2**((NumValuesw1 / 16 mod 2048) - 1023))
                        * (1 + ((NumValuesw1 mod 16) * 2**-4)
                        + (NumValuesw2 * 2**-20)
                        + (NumValuesw3 * 2**-36)
                        + (NumValuesw4 * 2**-52))
                        ) (decimal(18,0)) AS NumValues
                ,tblCreatorName
                ,tblCreatorFullName
                ,tblLastAccessTm
                ,tblLastAlterID
                ,tblLastAlterTm
                ,'C' (char(1)) as stats_type
          from 
        (
                select 
         		 collectDate
                        ,collectTime
                        ,databasename
                        ,tablename
                        ,columnname
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 8, 1)
                                || SUBSTR(Stats, 48 + offset + 7, 1) (BYTE(4))) AS NumValuesw1
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 6, 1)
                                || SUBSTR(Stats, 48 + offset + 5, 1) (BYTE(4))) AS NumValuesw2
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 4, 1)
                                || SUBSTR(Stats, 48 + offset + 3, 1) (BYTE(4))) AS NumValuesw3
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 2, 1)
                                || SUBSTR(Stats, 48 + offset + 1, 1) (BYTE(4))) AS NumValuesw4
                        ,tblCreator
                        ,tblCreateTm
                        ,tblLastAlterID
                        ,tblLastAlterTm
                        ,tblLastAccessTm
                        ,tblCreatorName
                        ,(l.Firstname || ' ' || l.lastName) as tblCreatorFullName
                        ,tblOSUserName
                  from prodbbymeadhocvws.rasc_tblcolumn_stats r
                left join prodbbymeadhocvws.ldap_employee l
          		on r.tblCreatorName = l.ldap_ID
        ) x
        group by  2, 3, 5,6,7,8,9
        union
        select
                max(collectDate) latestCollectDt
                ,databasename
                ,tablename
                 ,max((-1**(NumValuesw1 / 32768)) * (2**((NumValuesw1 / 16 mod 2048) - 1023))
                        * (1 + ((NumValuesw1 mod 16) * 2**-4)
                        + (NumValuesw2 * 2**-20)
                        + (NumValuesw3 * 2**-36)
                        + (NumValuesw4 * 2**-52))
                        ) (decimal(18,0)) AS NumValues
                ,tblCreatorName
                ,tblCreatorFullName
                ,tblLastAccessTm
                ,tblLastAlterID
                ,tblLastAlterTm
                ,'I' (char(1)) as stats_type
          from 
        (
                select 
         		 collectDate
                        ,collectTime
                        ,databasename
                        ,tablename
                        ,columnname
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 8, 1)
                                || SUBSTR(Stats, 48 + offset + 7, 1) (BYTE(4))) AS NumValuesw1
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 6, 1)
                                || SUBSTR(Stats, 48 + offset + 5, 1) (BYTE(4))) AS NumValuesw2
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 4, 1)
                                || SUBSTR(Stats, 48 + offset + 3, 1) (BYTE(4))) AS NumValuesw3
                        ,HASHBUCKET(SUBSTR(Stats, 48 + offset + 2, 1)
                                || SUBSTR(Stats, 48 + offset + 1, 1) (BYTE(4))) AS NumValuesw4
                        ,tblCreator
                        ,tblCreateTm
                        ,tblLastAlterID
                        ,tblLastAlterTm
                        ,tblLastAccessTm
                        ,tblCreatorName
                        ,(l.Firstname || ' ' || l.lastName) as tblCreatorFullName
                        ,tblOSUserName
                  from prodbbymeadhocvws.rasc_tblindex_stats r
                left join prodbbymeadhocvws.ldap_employee l
          		on r.tblCreatorName = l.ldap_ID
        ) x
        group by  2, 3, 5,6,7,8,9
) xx
group by 2,3,5,6,7,8


-- obsolete
--create view prodbbymeadhocvws.rasc_tblcolumn_stats
replace view prodbbymeadhocvws.rasc_tblcolumn_stats
as 
locking row for access
SELECT 
          (     (HASHBUCKET(SUBSTR(Stats, 2, 1) || SUBSTR(Stats, 1, 1) (BYTE(4)) ) - 1900 ) * 10000
                 +
                 (HASHBUCKET('00'xb || SUBSTR(Stats, 3, 1) (BYTE(4)) ) ) * 100
                 +
                 (HASHBUCKET('00'xb || SUBSTR(Stats, 4, 1) (BYTE(4)) ) )
          ) (DATE) as CollectDate
          ,(
                 CAST ( (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4)) ) (FORMAT '99:') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4)) ) (FORMAT '99:') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4)) ) (FORMAT '99.') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4)) ) (FORMAT '99' ) ) 
                  AS TIME(2))
          ) AS CollectTime
          ,databasename
          ,t.TVMNameI as TableName
          ,f.fieldName ColumnName
          ,CASE WHEN SUBSTR(fieldStatistics, 23, 1) = '00'XB
                  THEN 16
                  ELSE 0
           END AS Offset
          ,case when (fieldstatistics is not null) then SUBSTR(fieldstatistics, 1, 80) 
                else null
           end AS Stats
          ,t.createUID    as tblCreator
          ,t.createTimeStamp as tblCreateTm
          ,t.lastAlterUID as tblLastAlterID
          ,t.lastAlterTimestamp as tblLastAlterTm
          ,t.lastAccessTimestamp as tblLastAccessTm
          ,t.CreatorName as tblCreatorName
          ,t.OSUserName as tblOSUserName
  from 
          dbc.TVFields f
          ,dbc.Dbase d
          ,dbc.TVM t
          --dbc.columnstats
 where d.databasename ='prodbbymeadhocdb'
   --and tablename = ''
   and t.databaseID = d.databaseID
   and t.tvmID = f.tableID
   and t.tablekind = 'T'
   --and f.fieldstatistics is not null

-- obsolete
create view prodbbymeadhocvws.rasc_tblindex_stats
as 
locking row for access
SELECT 
          (     (HASHBUCKET(SUBSTR(Stats, 2, 1) || SUBSTR(Stats, 1, 1) (BYTE(4)) ) - 1900 ) * 10000
                 +
                 (HASHBUCKET('00'xb || SUBSTR(Stats, 3, 1) (BYTE(4)) ) ) * 100
                 +
                 (HASHBUCKET('00'xb || SUBSTR(Stats, 4, 1) (BYTE(4)) ) )
          ) (DATE) as CollectDate
          ,(
                 CAST ( (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4)) ) (FORMAT '99:') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4)) ) (FORMAT '99:') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4)) ) (FORMAT '99.') )
                  ||
                  (HASHBUCKET (CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4)) ) (FORMAT '99' ) ) 
                  AS TIME(2))
          ) AS CollectTime
          ,databasename
          ,t.TVMNameI as TableName
          ,f.fieldName ColumnName
          ,CASE WHEN SUBSTR(indexStatistics, 23, 1) = '00'XB
                  THEN 16
                  ELSE 0
           END AS Offset
          ,case when (indexstatistics is not null) then SUBSTR(indexstatistics, 1, 80) 
                else null
           end AS Stats
          ,t.createUID    as tblCreator
          ,t.createTimeStamp as tblCreateTm
          ,t.lastAlterUID as tblLastAlterID
          ,t.lastAlterTimestamp as tblLastAlterTm
          ,t.lastAccessTimestamp as tblLastAccessTm
          ,t.CreatorName as tblCreatorName
          ,t.OSUserName as tblOSUserName
  from 
        dbc.indexes i
        , dbc.tvm t
        , dbc.dbase d
        , dbc.tvfields f
--        , dbc.indices i2
--
 where 
       t.tvmid = i.tableid
   and t.tvmid = f.tableid
   and f.fieldid = i.fieldid
--   and i2.indexnumber = i.indexnumber
   and t.tablekind = 'T'
   and t.databaseid = d.databaseid
   and upper(trim(d.databasenamei)) in ('PRODBBYMEADHOCDB')
   --and upper(trim(i2.databasename)) = upper(trim(d.databasenamei))
--   and i.IndexStatistics is not null
--   and i2.indexname is not null

select
        trim(l.FirstName) || ' ' || l.LastName as tblCreatorFullName
        ,trim(s.DatabaseName) || '.' || s.TableName as TableName
        ,max(s.CollectDate) as LastCollectDateOnTbl
        ,sum(s.RowCount)  as tblTotalCollectedRows
        ,s.tblLastAccessTm
  from Prodbbymeadhocvws.Rasc_Tbl_STATS_INFO s
--left join prodbbymeadhocvws.ldap_employee l
--        on upper(trim(s.tblCreatorName)) = l.ldap_ID
left join prodbbymeadhocdb.ldap_employee l
        on upper(trim(s.tblCreatorName)) = l.mailNickName
group by tblCreatorFullName
        ,DatabaseName
        ,TableName
        ,tblLastAccessTm
order by TableName

select
        ownerID
  from prodbbymeadhocdb.fort_job
 where ownerID

--
-- New Tables without stats
--
SELECT 
        trim(T.DATABASENAME)  DatabaseName
        , T.TABLENAME as TableName
        , CASE WHEN S.DATABASENAME IS NULL THEN 'NO STATS' ELSE '' END AS HAS_STATS
        , S.COUNT_ZERO_STATS
        , trim(l.FirstName) || ' ' || l.LastName as creatorFullName
        , t.creatorName
        -- last access timestamp is no longer collected
        --, t.lastAccessTimeStamp
        , t.createTimestamp
        --,t.accessCount
  FROM DBC.TABLES T
LEFT OUTER JOIN (       SELECT DATABASENAME, TABLENAME
				, SUM(CASE WHEN ZEROSTATS='Y'  THEN 1 ELSE 0 END) AS COUNT_ZERO_STATS
			FROM  PRODBBYMEADHOCVWS.rasc_tbl_stats_info
			WHERE DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
			GROUP BY 1,2) S
                ON T.DATABASENAME = S.DATABASENAME
                AND T.TABLENAME = S.TABLENAME
left outer join prodbbymeadhocdb.ldap_employee l
                on T.creatorName = trim(l.mailNickName)
WHERE  T.DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
  AND T.TABLEKIND ='T'
  and t.createTimeStamp > cast (date - 7 as Timestamp)
  --and t.createTimeStamp > Timestamp '2008-10-01 12:00:00'
  and t.tableName not like 'bu0%'
  AND COALESCE(S.COUNT_ZERO_STATS, 999) > 0
  and t.tablename not like 'bu0%'
ORDER BY 5,1,2

select
        t.databasename, t.tablename
        , s.collectDate
        , S.rowCount
        , s.DistinctColumnValues
        , S.countOfNulls
        , trim(l.FirstName) || ' ' || trim(l.LastName) as creatorFullName
        , t.creatorName as creatorID
        , t.lastAccessTimeStamp
        , t.createTimestamp
  from dbc.tables t
join prodbbymeadhocvws.rasc_tbl_stats_info s
    on s.databasename = t.databasename
    and s.tablename = t.tablename
left outer join prodbbymeadhocdb.ldap_employee l
                on lower(T.creatorName) = lower(trim(l.mailNickName))
 WHERE  t.DATABASENAME = 'prodbbymeadhocdb' -- in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
  and s.collectDate < date - 7
  and t.TABLEKIND ='T'
--
-- The query to pull no-stats or zero-stats tables in prodbbymeadhoc*
-- This query is based on Jen Erickson's SQL and modified to
-- use prodbbymeadhocvws views instead of dbc views and prodetlstage views
--
SELECT 
        T.DATABASENAME, T.TABLENAME
        , CASE WHEN S.DATABASENAME IS NULL THEN 'NO STATS' ELSE '' END AS HAS_STATS
        , S.COUNT_ZERO_STATS
        , trim(l.FirstName) || ' ' || trim(l.LastName) as creatorFullName
        , t.creatorName as creatorID
        , t.lastAccessTimeStamp
        , t.createTimestamp
  FROM DBC.TABLES T
LEFT OUTER JOIN (       SELECT DATABASENAME, TABLENAME
				, SUM(CASE WHEN ZEROSTATS='Y'  THEN 1 ELSE 0 END) AS COUNT_ZERO_STATS
			FROM  PRODBBYMEADHOCVWS.rasc_tbl_stats_info
			WHERE DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
			GROUP BY 1,2) S
                ON T.DATABASENAME = S.DATABASENAME
                AND T.TABLENAME = S.TABLENAME
left outer join prodbbymeadhocdb.ldap_employee l
                on T.creatorName = trim(l.mailNickName)
WHERE  T.DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
  AND T.TABLEKIND ='T'
  AND COALESCE(S.COUNT_ZERO_STATS, 999) > 0
ORDER BY 1,2

--**********************************************************************************
-- a version Use DBC views
Replace VIEW Prodbbymeadhocvws.rasc_tbl_stats_info AS 
    --LOCKING TABLE Prodbbymeadhocvws.IndexStatsWithCreator FOR ACCESS
    --LOCKING TABLE Prodbbymeadhocvws.ColumnStatsWithCreator FOR ACCESS
    --LOCKING TABLE Prodbbymeadhocvws.MultiColumnStatsWithCreator FOR ACCESS
    LOCKING TABLE dbc.IndexStats FOR ACCESS
    LOCKING TABLE dbc.ColumnStats FOR ACCESS
    LOCKING TABLE dbc.MultiColumnStats FOR ACCESS
SELECT 
        DatabaseName, TableName, ColumnName
        , ColumnCount , StatsType 
        , Collect_Date as CollectDate
        , Collect_Time as CollectTime
        , CAST( CAST( (Collect_Date (FORMAT 'YYYY-MM-DD') ) AS CHAR(10) ) 
                || ' ' 
                || CAST(Collect_Time AS CHAR(11)) AS TIMESTAMP
              ) AS CollectDateTime
        ,CASE SampleSize WHEN 0 THEN 100 ELSE SampleSize END AS SampleSize
        ,SampleUsed 
        ,ZeroStats 
        ,case when ZeroStats = 'N' then 
                        (-1**(NumRowsw1 / 32768)) 
                        * (2**((NumRowsw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumRowsw1 mod 16) * 2**-4) + (NumRowsw2 * 2**-20)
                                + (NumRowsw3 * 2**-36) + (NumRowsw4 * 2**-52)
                           ) 
                else 0 
        end AS RowCount
        ,case when ZeroStats = 'N' then 
                        (-1**(NumValuesw1 / 32768)) 
                        * (2**((NumValuesw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumValuesw1 mod 16) * 2**-4) + (NumValuesw2 * 2**-20)
                                + (NumValuesw3 * 2**-36) + (NumValuesw4 * 2**-52)
                          ) 
                else 0 
        end AS DistinctColumnValues
        ,case when ZeroStats = 'N' and NumNullsw1 > 0 THEN
                        (-1**(NumNullsw1 / 32768)) 
                        * (2**((NumNullsw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumNullsw1 mod 16) * 2**-4) + (NumNullsw2 * 2**-20)
                                + (NumNullsw3 * 2**-36) + (NumNullsw4 * 2**-52)
                          ) 
                ELSE 0 
         END AS CountOfNulls
        ,case when ZeroStats = 'N' and AllNulls='N' then 
                         (-1**(ModeFreqw1 / 32768)) 
                        * (2**((ModeFreqw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((ModeFreqw1 mod 16) * 2**-4) + (ModeFreqw2 * 2**-20)
                                + (ModeFreqw3 * 2**-36) + (ModeFreqw4 * 2**-52)
                           )
                else 0 
        end as MaximumFrequency 
        --, tblCreatorName
        --, tblCreateTm
        --, tblLastAccessTm
  FROM
(
        SELECT
                DatabaseName
                ,TableName
                ,ColumnName
                ,ColumnCount
                ,Stats
                ,StatsType
                ,case when substr(Stats, 11, 1) = '01'xb then 'Y' else 'N' end as SampleUsed
                ,case when Stats is null then null 
                        when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)='0000000000000000'xb then 'Y'
                        else 'N' 
                end as ZeroStats
                ,case when Stats is null then null
                       when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)<>'0000000000000000'xb then 'Y'
                       else 'N' 
                end as AllNulls
                ,(
                        (HASHBUCKET ( SUBSTR(Stats, 2, 1) 
                                        || SUBSTR(Stats, 1, 1) (BYTE(4))
                                    )  - 1900
                        ) * 10000
                        +
                        (HASHBUCKET ( '00'xb || SUBSTR(Stats, 3, 1) (BYTE(4)) )
                        ) * 100
                        +
                        (HASHBUCKET ( '00'xb || SUBSTR(Stats, 4, 1) (BYTE(4)) )
                        )
                ) (DATE) AS Collect_Date
                ,( CAST(
                        (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4))
                                    ) (FORMAT '99:')
                        ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4))
                                       ) (FORMAT '99:')
                           ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4))
                                       ) (FORMAT '99.')
                           ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4))
                                       ) (FORMAT '99')
                           ) 
                     AS TIME(2) )
                ) AS Collect_Time
                , HASHBUCKET ('00'xb || SUBSTR(Stats, 12, 1) (BYTE(4))) AS SampleSize
                , HASHBUCKET( substr(Stats, 16+8, 1) || substr(Stats, 16+7, 1) (byte(4)) ) as NumNullsw1
                , HASHBUCKET( substr(Stats, 16+6, 1) || substr(Stats, 16+5, 1) (byte(4)) ) as NumNullsw2
                , HASHBUCKET( substr(Stats, 16+4, 1) || substr(Stats, 16+3, 1) (byte(4)) ) as NumNullsw3
                , HASHBUCKET( substr(Stats, 16+2, 1) || substr(Stats, 16+1, 1) (byte(4)) ) as NumNullsw4
                , HASHBUCKET( substr(Stats, 48+Offset+8, 1) || substr(Stats, 48+Offset+7, 1) (byte(4)) ) as ModeFreqw1
                , HASHBUCKET( substr(Stats, 48+Offset+6, 1) || substr(Stats, 48+Offset+5, 1) (byte(4)) ) as ModeFreqw2
                , HASHBUCKET( substr(Stats, 48+Offset+4, 1) || substr(Stats, 48+Offset+3, 1) (byte(4)) ) as ModeFreqw3
                , HASHBUCKET( substr(Stats, 48+Offset+2, 1) || substr(Stats, 48+Offset+1, 1) (byte(4)) ) as ModeFreqw4
                , HASHBUCKET( substr(Stats, 56+Offset+8, 1) || substr(Stats, 56+Offset+7, 1) (byte(4)) ) as NumValuesw1
                , HASHBUCKET( substr(Stats, 56+Offset+6, 1) || substr(Stats, 56+Offset+5, 1) (byte(4)) ) as NumValuesw2
                , HASHBUCKET( substr(Stats, 56+Offset+4, 1) || substr(Stats, 56+Offset+3, 1) (byte(4)) ) as NumValuesw3
                , HASHBUCKET( substr(Stats, 56+Offset+2, 1) || substr(Stats, 56+Offset+1, 1) (byte(4)) ) as NumValuesw4
                , HASHBUCKET( substr(Stats, 64+Offset+8, 1) || substr(Stats, 64+Offset+7, 1) (byte(4)) ) as NumRowsw1
                , HASHBUCKET( substr(Stats, 64+Offset+6, 1) || substr(Stats, 64+Offset+5, 1) (byte(4)) ) as NumRowsw2
                , HASHBUCKET( substr(Stats, 64+Offset+4, 1) || substr(Stats, 64+Offset+3, 1) (byte(4)) ) as NumRowsw3
                , HASHBUCKET( substr(Stats, 64+Offset+2, 1) || substr(Stats, 64+Offset+1, 1) (byte(4)) ) as NumRowsw4
                --, tblCreatorName
                --, tblCreateTm
                --, tblLastAccessTm
       FROM
        (
                SELECT
                        DatabaseName
                        , TableName
                        , MAX( CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END ) 
                                || MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END)
                        AS ColumnName
                        , COUNT(*) AS ColumnCount
                        , 'I' AS StatsType
                        , MAX(CASE WHEN SUBSTR(IndexStatistics, 27, 1) = '00'XB
                                   THEN 16
                                   ELSE 0
                                END) AS Offset
                        , MAX( SUBSTR(IndexStatistics, 1, 128) ) AS Stats
                        --, tblCreatorName
                        --, tblCreateTm
                        --, tblLastAccessTm
                FROM dbc.indexstats     -- STATS VIEWS
                GROUP BY DatabaseName, TableName, StatsType, IndexNumber
                        --, tblCreatorName
                        --, tblCreateTm
                        --, tblLastAccessTm

                UNION ALL
                SELECT
                        DatabaseName
                        , TableName
                        , MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END)
                        AS ColumnName
                        , COUNT(*) AS ColumnCount
                        , 'M' AS StatsType
                        , MAX(CASE WHEN SUBSTR(ColumnsStatistics, 27, 1) = '00'XB 
                                THEN 16
                                ELSE 0
                            END) AS Offset
                        , MAX(SUBSTR(ColumnsStatistics, 1, 128)) AS Stats
                        --, tblCreatorName
                        --, tblCreateTm
                        --, tblLastAccessTm
                FROM dbc.MultiColumnStats -- STATS VIEWS
                GROUP BY DatabaseName, TableName, StatsType, StatisticsID
                        --, tblCreatorName
                        --, tblCreateTm
                        --, tblLastAccessTm

                UNION ALL
     
                SELECT
                        DatabaseName
                        , TableName
                        , ColumnName
                        , 1 AS ColumnCount
                        , 'C' AS StatsType
                        , CASE WHEN SUBSTR(fieldStatistics, 27, 1) = '00'XB 
                                THEN 16
                                ELSE 0
                          END AS Offset
                        , SUBSTR(fieldstatistics, 1, 128) AS Stats
                        --, tblCreatorName
                        --, tblCreateTm
                        --, tblLastAccessTm
                FROM dbc.columnstats      -- STATS VIEWS
        ) dt
        WHERE Stats IS NOT NULL
) dt;

--Create VIEW Prodbbymeadhocvws.Rasc_Tbl_STATS_INFO AS 
Replace VIEW Prodbbymeadhocvws.rasc_tbl_stats_info AS 
    LOCKING TABLE Prodbbymeadhocvws.IndexStatsWithCreator FOR ACCESS
    LOCKING TABLE Prodbbymeadhocvws.ColumnStatsWithCreator FOR ACCESS
    LOCKING TABLE Prodbbymeadhocvws.MultiColumnStatsWithCreator FOR ACCESS
SELECT 
        DatabaseName, TableName, ColumnName
        , ColumnCount , StatsType 
        , Collect_Date as CollectDate
        , Collect_Time as CollectTime
        , CAST( CAST( (Collect_Date (FORMAT 'YYYY-MM-DD') ) AS CHAR(10) ) 
                || ' ' 
                || CAST(Collect_Time AS CHAR(11)) AS TIMESTAMP
              ) AS CollectDateTime
        ,CASE SampleSize WHEN 0 THEN 100 ELSE SampleSize END AS SampleSize
        ,SampleUsed 
        ,ZeroStats 
        ,case when ZeroStats = 'N' then 
                        (-1**(NumRowsw1 / 32768)) 
                        * (2**((NumRowsw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumRowsw1 mod 16) * 2**-4) + (NumRowsw2 * 2**-20)
                                + (NumRowsw3 * 2**-36) + (NumRowsw4 * 2**-52)
                           ) 
                else 0 
        end AS RowCount
        ,case when ZeroStats = 'N' then 
                        (-1**(NumValuesw1 / 32768)) 
                        * (2**((NumValuesw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumValuesw1 mod 16) * 2**-4) + (NumValuesw2 * 2**-20)
                                + (NumValuesw3 * 2**-36) + (NumValuesw4 * 2**-52)
                          ) 
                else 0 
        end AS DistinctColumnValues
        ,case when ZeroStats = 'N' and NumNullsw1 > 0 THEN
                        (-1**(NumNullsw1 / 32768)) 
                        * (2**((NumNullsw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((NumNullsw1 mod 16) * 2**-4) + (NumNullsw2 * 2**-20)
                                + (NumNullsw3 * 2**-36) + (NumNullsw4 * 2**-52)
                          ) 
                ELSE 0 
         END AS CountOfNulls
        ,case when ZeroStats = 'N' and AllNulls='N' then 
                         (-1**(ModeFreqw1 / 32768)) 
                        * (2**((ModeFreqw1/16 mod 2048) - 1023)) 
                        * ( 1 + ((ModeFreqw1 mod 16) * 2**-4) + (ModeFreqw2 * 2**-20)
                                + (ModeFreqw3 * 2**-36) + (ModeFreqw4 * 2**-52)
                           )
                else 0 
        end as MaximumFrequency 
        , tblCreatorName
        , tblCreateTm
        , tblLastAccessTm
  FROM
(
        SELECT
                DatabaseName
                ,TableName
                ,ColumnName
                ,ColumnCount
                ,Stats
                ,StatsType
                ,case when substr(Stats, 11, 1) = '01'xb then 'Y' else 'N' end as SampleUsed
                ,case when Stats is null then null 
                        when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)='0000000000000000'xb then 'Y'
                        else 'N' 
                end as ZeroStats
                ,case when Stats is null then null
                       when substr(Stats, 25,2)='0000'xb and substr(Stats, 17,8)<>'0000000000000000'xb then 'Y'
                       else 'N' 
                end as AllNulls
                ,(
                        (HASHBUCKET ( SUBSTR(Stats, 2, 1) 
                                        || SUBSTR(Stats, 1, 1) (BYTE(4))
                                    )  - 1900
                        ) * 10000
                        +
                        (HASHBUCKET ( '00'xb || SUBSTR(Stats, 3, 1) (BYTE(4)) )
                        ) * 100
                        +
                        (HASHBUCKET ( '00'xb || SUBSTR(Stats, 4, 1) (BYTE(4)) )
                        )
                ) (DATE) AS Collect_Date
                ,( CAST(
                        (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 5, 1) AS BYTE(4))
                                    ) (FORMAT '99:')
                        ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 6, 1) AS BYTE(4))
                                       ) (FORMAT '99:')
                           ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 7, 1) AS BYTE(4))
                                       ) (FORMAT '99.')
                           ) 
                        || (HASHBUCKET ( CAST('00'xb || SUBSTR(Stats, 8, 1) AS BYTE(4))
                                       ) (FORMAT '99')
                           ) 
                     AS TIME(2) )
                ) AS Collect_Time
                , HASHBUCKET ('00'xb || SUBSTR(Stats, 12, 1) (BYTE(4))) AS SampleSize
                , HASHBUCKET( substr(Stats, 16+8, 1) || substr(Stats, 16+7, 1) (byte(4)) ) as NumNullsw1
                , HASHBUCKET( substr(Stats, 16+6, 1) || substr(Stats, 16+5, 1) (byte(4)) ) as NumNullsw2
                , HASHBUCKET( substr(Stats, 16+4, 1) || substr(Stats, 16+3, 1) (byte(4)) ) as NumNullsw3
                , HASHBUCKET( substr(Stats, 16+2, 1) || substr(Stats, 16+1, 1) (byte(4)) ) as NumNullsw4
                , HASHBUCKET( substr(Stats, 48+Offset+8, 1) || substr(Stats, 48+Offset+7, 1) (byte(4)) ) as ModeFreqw1
                , HASHBUCKET( substr(Stats, 48+Offset+6, 1) || substr(Stats, 48+Offset+5, 1) (byte(4)) ) as ModeFreqw2
                , HASHBUCKET( substr(Stats, 48+Offset+4, 1) || substr(Stats, 48+Offset+3, 1) (byte(4)) ) as ModeFreqw3
                , HASHBUCKET( substr(Stats, 48+Offset+2, 1) || substr(Stats, 48+Offset+1, 1) (byte(4)) ) as ModeFreqw4
                , HASHBUCKET( substr(Stats, 56+Offset+8, 1) || substr(Stats, 56+Offset+7, 1) (byte(4)) ) as NumValuesw1
                , HASHBUCKET( substr(Stats, 56+Offset+6, 1) || substr(Stats, 56+Offset+5, 1) (byte(4)) ) as NumValuesw2
                , HASHBUCKET( substr(Stats, 56+Offset+4, 1) || substr(Stats, 56+Offset+3, 1) (byte(4)) ) as NumValuesw3
                , HASHBUCKET( substr(Stats, 56+Offset+2, 1) || substr(Stats, 56+Offset+1, 1) (byte(4)) ) as NumValuesw4
                , HASHBUCKET( substr(Stats, 64+Offset+8, 1) || substr(Stats, 64+Offset+7, 1) (byte(4)) ) as NumRowsw1
                , HASHBUCKET( substr(Stats, 64+Offset+6, 1) || substr(Stats, 64+Offset+5, 1) (byte(4)) ) as NumRowsw2
                , HASHBUCKET( substr(Stats, 64+Offset+4, 1) || substr(Stats, 64+Offset+3, 1) (byte(4)) ) as NumRowsw3
                , HASHBUCKET( substr(Stats, 64+Offset+2, 1) || substr(Stats, 64+Offset+1, 1) (byte(4)) ) as NumRowsw4
                , tblCreatorName
                , tblCreateTm
                , tblLastAccessTm
       FROM
        (
                SELECT
                        DatabaseName
                        , TableName
                        , MAX( CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END ) 
                                || MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END)
                        AS ColumnName
                        , COUNT(*) AS ColumnCount
                        , 'I' AS StatsType
                        , MAX(CASE WHEN SUBSTR(IndexStatistics, 27, 1) = '00'XB
                                   THEN 16
                                   ELSE 0
                                END) AS Offset
                        , MAX( SUBSTR(IndexStatistics, 1, 128) ) AS Stats
                        , tblCreatorName
                        , tblCreateTm
                        , tblLastAccessTm
                FROM prodbbymeadhocvws.indexstatsWithCreator     -- STATS VIEWS
                GROUP BY DatabaseName, TableName, StatsType, IndexNumber
                        , tblCreatorName
                        , tblCreateTm
                        , tblLastAccessTm

                UNION ALL
                SELECT
                        DatabaseName
                        , TableName
                        , MAX(CASE WHEN ColumnPosition = 1 THEN TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 2 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 3 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 4 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 5 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 6 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 7 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 8 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 9 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 10 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 11 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 12 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 13 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 14 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 15 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition = 16 THEN ',' || TRIM(ColumnName) ELSE '' END)
                                || MAX(CASE WHEN ColumnPosition > 16  THEN ',...' ELSE '' END)
                        AS ColumnName
                        , COUNT(*) AS ColumnCount
                        , 'M' AS StatsType
                        , MAX(CASE WHEN SUBSTR(ColumnsStatistics, 27, 1) = '00'XB 
                                THEN 16
                                ELSE 0
                            END) AS Offset
                        , MAX(SUBSTR(ColumnsStatistics, 1, 128)) AS Stats
                        , tblCreatorName
                        , tblCreateTm
                        , tblLastAccessTm
                FROM prodbbymeadhocvws.MultiColumnStatsWithCreator -- STATS VIEWS
                GROUP BY DatabaseName, TableName, StatsType, StatisticsID
                        , tblCreatorName
                        , tblCreateTm
                        , tblLastAccessTm

                UNION ALL
     
                SELECT
                        DatabaseName
                        , TableName
                        , ColumnName
                        , 1 AS ColumnCount
                        , 'C' AS StatsType
                        , CASE WHEN SUBSTR(fieldStatistics, 27, 1) = '00'XB 
                                THEN 16
                                ELSE 0
                          END AS Offset
                        , SUBSTR(fieldstatistics, 1, 128) AS Stats
                        , tblCreatorName
                        , tblCreateTm
                        , tblLastAccessTm
                FROM prodbbymeadhocvws.columnstatsWithCreator      -- STATS VIEWS
        ) dt
        WHERE Stats IS NOT NULL
) dt;

--Create View prodbbymeadhocvws.multiColumnStatsWithCreator
Replace View prodbbymeadhocvws.multiColumnStatsWithCreator
as
SELECT 
        DBC.DBase.DatabaseNameI(NAMED DatabaseName)
        , DBC.TVM.TVMNameI(NAMED TableName)
        , DBC.Indexes.IndexNumber(NAMED StatisticsId)
        , DBC.Indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9')
        , (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldName else Cast('PARTITION' as char(9)) end)(NAMED ColumnName)
        , (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldType else Cast('I' as char(1)) end)(NAMED ColumnType)
        , (case when DBC.indexes.fieldid > 0 then DBC.TVFields.MaxLength else 2 end) (NAMED ColumnLength , FORMAT 'Z,ZZZ,ZZZ,ZZ9')
        , (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldFormat else cast('ZZZZ9' as char(5)) end) (NAMED ColumnFormat)
        , DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9')
        , DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 'Z9')
        , DBC.Indexes.IndexStatistics(NAMED ColumnsStatistics)
        , dbc.Indexes.CreateTimeStamp idxCreateTm
        , dbc.Indexes.LastAccessTimeStamp idxLastAccessTm
        , dbc.TVM.CreatorName tblCreatorName
        , dbc.TVM.CreateTimeStamp tblCreateTm
        , dbc.TVM.LastAccessTimeStamp tblLastAccessTm
  FROM DBC.Indexes
INNER JOIN DBC.TVM
     ON (DBC.TVM.TVMid = DBC.indexes.tableid)
INNER JOIN DBC.dbase
     ON (DBC.TVM.DatabaseId = DBC.dbase.DatabaseId
         and upper(trim(dbc.dbase.databaseNameI)) in ( 'PRODBBYMEADHOCDB', 'PRODBBYMEADHOCWRK', 'PRODBBYMEADHOCVWS')
        )
LEFT OUTER JOIN DBC.TVFields
     ON (DBC.indexes.fieldid = DBC.TVFields.fieldid
         AND DBC.TVM.TVMid = DBC.TVFields.tableid)
 WHERE (DBC.indexes.indextype = 'M'
   OR DBC.indexes.indextype = 'D') /*Derived column PARTITION stats*/
  and upper(trim(dbc.dbase.databaseNameI)) in ( 'PRODBBYMEADHOCDB', 'PRODBBYMEADHOCWRK', 'PRODBBYMEADHOCVWS')
    with check option;

--Create View prodbbymeadhocvws.IndexStatsWithCreator
Replace View prodbbymeadhocvws.indexstatswithcreator
as
SELECT DBC.DBase.DatabaseNameI(NAMED DatabaseName),
          DBC.TVM.TVMNameI(NAMED TableName),
          DBC.Indexes.IndexNumber,
          DBC.Indexes.Name(NAMED IndexName),
          DBC.Indexes.IndexType,
          DBC.Indexes.UniqueFlag,
          DBC.Indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9'),
          DBC.TVFields.FieldName(NAMED ColumnName),
          DBC.TVFields.FieldType(NAMED ColumnType),
          DBC.TVFields.MaxLength(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9'),
          DBC.TVFields.FieldFormat(NAMED ColumnFormat),
          DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),
          DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 'Z9'),
          DBC.Indexes.IndexStatistics
        , DBC.Indexes.IndexStatistics(NAMED ColumnsStatistics)
        , dbc.Indexes.CreateTimeStamp idxCreateTm
        , dbc.Indexes.LastAccessTimeStamp idxLastAccessTm
        , dbc.TVM.CreatorName tblCreatorName
        , dbc.TVM.CreateTimeStamp tblCreateTm
        , dbc.TVM.LastAccessTimeStamp tblLastAccessTm

FROM    DBC.Indexes,
        DBC.Dbase,
        DBC.TVM,
        DBC.TVFields

WHERE   DBC.TVM.DatabaseId = DBC.dbase.DatabaseId
AND     DBC.TVM.TVMid = DBC.indexes.tableid
AND     DBC.TVM.TVMid = DBC.TVFields.tableid
AND     DBC.indexes.indextype <> 'M'
AND     DBC.TVFields.fieldid = DBC.indexes.fieldid 
and     upper(trim(dbc.dbase.databaseNameI)) in  ( 'PRODBBYMEADHOCDB', 'PRODBBYMEADHOCWRK', 'PRODBBYMEADHOCVWS')
with check option;

--Create View prodbbymeadhocvws.ColumnStatsWithCreator
Replace View prodbbymeadhocvws.ColumnStatsWithCreator
AS  
SELECT  DBC.DBASE.DatabaseNameI (NAMED DatabaseName),
          DBC.TVM.TVMNameI(NAMED TableName),
          DBC.TVFields.FieldName(NAMED ColumnName),
          DBC.TVFields.FieldType(NAMED ColumnType),
          DBC.TVFields.MaxLength(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9'),
          DBC.TVFields.FieldFormat(NAMED ColumnFormat),
          DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),

          DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 
'Z9'),
          DBC.TVFields.FieldStatistics,
          DBC.TVFields.FieldID(NAMED SeqNumber)
        , dbc.TVFields.CreateTimeStamp colCreateTm
        , dbc.TVFields.LastAccessTimeStamp colLastAccessTm
        , dbc.TVM.CreatorName tblCreatorName
        , dbc.TVM.CreateTimeStamp tblCreateTm
        , dbc.TVM.LastAccessTimeStamp tblLastAccessTm

FROM     DBC.TVFields,
         DBC.Dbase,
         DBC.TVM

WHERE    DBC.TVM.DatabaseId = DBC.DBASE.DatabaseId
AND      DBC.TVM.TVMid = DBC.TVFields.TableId 
and      upper(trim(dbc.dbase.databaseNameI)) in ( 'PRODBBYMEADHOCDB', 'PRODBBYMEADHOCWRK', 'PRODBBYMEADHOCVWS')
with check option;

--**********************************************************************************
show view dbc.multicolumnstats;

REPLACE VIEW DBC.MultiColumnStats AS
SELECT DBC.DBase.DatabaseNameI(NAMED DatabaseName),
       DBC.TVM.TVMNameI(NAMED TableName),
       DBC.Indexes.IndexNumber(NAMED StatisticsId),
       DBC.Indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9'),
       (case when DBC.indexes.fieldid > 0
             then DBC.TVFields.FieldName else Cast('PARTITION' as char(9)) end)(NAMED ColumnName),
       (case when DBC.indexes.fieldid > 0
             then DBC.TVFields.FieldType else Cast('I' as char(1)) end)(NAMED ColumnType),
       (case when DBC.indexes.fieldid > 0
             then DBC.TVFields.MaxLength else 2 end)(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9 '),
       (case when DBC.indexes.fieldid > 0
             then DBC.TVFields.FieldFormat else cast('ZZZZ9' as char(5)) end) (NAMED ColumnFormat),
       DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),
       DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 'Z9'),
       DBC.Indexes.IndexStatistics(NAMED ColumnsStatistics)
FROM DBC.Indexes
     INNER JOIN DBC.TVM
     ON (DBC.TVM.TVMid = DBC.indexes.tableid)
     INNER JOIN DBC.dbase
     ON (DBC.TVM.DatabaseId = DBC.dbase.DatabaseId)
     LEFT OUTER JOIN DBC.TVFields
     ON (DBC.indexes.fieldid = DBC.TVFields.fieldid
         AND DBC.TVM.TVMid = DBC.TVFields.tableid)

     WHERE (DBC.indexes.indextype = 'M'
            OR DBC.indexes.indextype = 'D') /*Derived column PARTITION stats*/
    with check option;

--**********************************************************************************
show view dbc.indexStats;


REPLACE VIEW DBC.IndexStats AS
SELECT DBC.DBase.DatabaseNameI(NAMED DatabaseName),
          DBC.TVM.TVMNameI(NAMED TableName),
          DBC.Indexes.IndexNumber,
          DBC.Indexes.Name(NAMED IndexName),
          DBC.Indexes.IndexType,
          DBC.Indexes.UniqueFlag,
          DBC.Indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9'),
          DBC.TVFields.FieldName(NAMED ColumnName),
          DBC.TVFields.FieldType(NAMED ColumnType),
          DBC.TVFields.MaxLength(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9'),
          DBC.TVFields.FieldFormat(NAMED ColumnFormat),
          DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),
          DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 'Z9'),
          DBC.Indexes.IndexStatistics

FROM    DBC.Indexes,
        DBC.Dbase,
        DBC.TVM,
        DBC.TVFields

WHERE   DBC.TVM.DatabaseId = DBC.dbase.DatabaseId
AND     DBC.TVM.TVMid = DBC.indexes.tableid
AND     DBC.TVM.TVMid = DBC.TVFields.tableid
AND     DBC.indexes.indextype <> 'M'
AND     DBC.TVFields.fieldid = DBC.indexes.fieldid with check option;

--**********************************************************************************

show view dbc.columnStats;

REPLACE VIEW DBC.ColumnStats
AS  SELECT  DBC.DBASE.DatabaseNameI (NAMED DatabaseName),
          DBC.TVM.TVMNameI(NAMED TableName),
          DBC.TVFields.FieldName(NAMED ColumnName),
          DBC.TVFields.FieldType(NAMED ColumnType),
          DBC.TVFields.MaxLength(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9
'),
          DBC.TVFields.FieldFormat(NAMED ColumnFormat),
          DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),

          DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 
'Z9'),
          DBC.TVFields.FieldStatistics,
          DBC.TVFields.FieldID(NAMED SeqNumber)

FROM     DBC.TVFields,
         DBC.Dbase,
         DBC.TVM

WHERE    DBC.TVM.DatabaseId = DBC.DBASE.DatabaseId
AND      DBC.TVM.TVMid = DBC.TVFields.TableId with check option;


-- TD12 Upgrade post-upgrade stats collect
select Databasename, Tablename, max(CollectDate)
  from prodbbymeadhocvws.rasc_tbl_stats_info 
 where CollectDate < date -2
   and databasename = 'prodbbymeadhocdb'
   and TableName not like 'X_%'
   and CollectDate > date - 365 * 4
 group by 1,2


---------------------------------------------
-- standard query from Teradata forum
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
,IndexType, UniqueFlag      -- added by LJ
FROM
(
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
        ,IndexType, UniqueFlag      -- added by LJ
    FROM
    (
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
            ,IndexType, UniqueFlag      -- added by LJ
        FROM
        (
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
                ,IndexType, UniqueFlag      -- added by LJ
            FROM dbc.IndexStats
            GROUP BY DatabaseName, TableName, StatsType, IndexNumber
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
                ,null, null      -- added by LJ
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
                ,null, null      -- added by LJ
            FROM dbc.ColumnStats
            WHERE STATS IS NOT NULL
        ) dt
    ) dt
) dt
;
---------------------

--**********************************************************************************
help table dbc.indexes;
 
Column Name                    Type Comment
------------------------------ ---- -----------------------------------------------------------------------------------
TableId                        BF   ?
IndexType                      CF   Indexes.IndexType is P (NPPI), Q (PPI), S (SI), U (unique), K (primary key), J (join index), 
                                        N (hash index), V (value-ordered SI without ALL), H (hash-ordered SI wi
IndexNumber                    I2   Indexes.IndexNumber is the internal number assigned to the index. A primary index has an index number of 1. 
                                        A secondary index has an index number that is a multiple
UniqueFlag                     CF   ?
FieldId                        I2   ?
FieldPosition                  I2   ?
IndexMode                      CF   Indexes.IndexMode is H (secondary index rows are hash distributed to the AMPs), 
                                        L (secondary index rows are on the same AMP as the referenced data row), or NULL (pr
DatabaseId                     BF   ?
IndexStatistics                BV   ?
Name                           CF   ?
CreateUID                      BF   ?
CreateTimeStamp                TS   ?
LastAlterUID                   BF   ?
LastAlterTimeStamp             TS   ?
LastAccessTimeStamp            TS   ?
AccessCount                    I    ?

--**********************************************************************************

help table dbc.tvfields;

Column Name                    Type Comment
------------------------------ ---- ---------------------------------------
TableId                        BF   ?
FieldName                      CF   ?
FieldId                        I2   ?
Nullable                       CF   ?
FieldType                      CF   ?
MaxLength                      I    ?
DefaultValue                   CV   ?
DefaultValueI                  BV   ?
TotalDigits                    I2   ?
ImpliedPoint                   I2   ?
FieldFormat                    CF   ?
FieldTitle                     CV   ?
CommentString                  CV   ?
CollationFlag                  CF   ?
UpperCaseFlag                  CF   ?
DatabaseId                     BF   ?
Compressible                   CF   ?
CompressValue                  CV   ?
CompressValueList              CV   ?
FieldStatistics                BV   ?
ColumnCheck                    CV   ?
CheckCount                     I2   ?
CreateUID                      BF   ?
CreateTimeStamp                TS   ?
LastAlterUID                   BF   ?
LastAlterTimeStamp             TS   ?
LastAccessTimeStamp            TS   ?
AccessCount                    I    ?
SPParameterType                CF   ?
CharType                       I2   ?
LobSequenceNo                  I2   ?
IdColType                      CF   ?
UDTypeId                       BF   ?
UDTName                        CF   ?

--**********************************************************************************
help table dbc.dbase;

Column Name                    Type Comment
------------------------------ ---- ---------------------------------------
DatabaseNameI                  CF   ?
DatabaseId                     BF   ?
OwnerId                        BF   ?
PasswordString                 CF   ?
ProtectionType                 CF   ?
JournalFlag                    CF   ?
PermSpace                      F    ?
SpoolSpace                     F    ?
StartupString                  CV   ?
CommentString                  CV   ?
AccountName                    CF   ?
CreatorName                    CF   ?
DatabaseName                   CF   ?
JournalId                      BF   ?
Version                        I2   ?
OwnerName                      CF   ?
NumFallBackTables              I2   ?
NumLogProtTables               I2   ?
DefaultDataBase                CF   ?
LogonRules                     I2   ?
AccLogRules                    I2   ?
AccLogUsrRules                 I2   ?
DefaultCollation               CF   ?
RowType                        CF   ?
PasswordChgDate                I    ?
LockedDate                     I    ?
LockedTime                     I2   ?
LockedCount                    I1   ?
UnResolvedRICount              I2   ?
TimeZoneHour                   I1   ?
TimeZoneMinute                 I1   ?
DefaultDateForm                CF   ?
CreateUID                      BF   ?
CreateTimeStamp                TS   ?
LastAlterUID                   BF   ?
LastAlterTimeStamp             TS   ?
TempSpace                      F    ?
LastAccessTimeStamp            TS   ?
AccessCount                    I    ?
DefaultCharType                I2   ?
RoleName                       CF   ?
ProfileName                    CF   ?
UDFLibRevision                 I    ?

--**********************************************************************************

-- Table View Macro? TVM
help table dbc.tvm;

Column Name                    Type Comment
------------------------------ ---- ---------------------------------------
DatabaseId                     BF   ?
TVMNameI                       CF   ?
LogicalHostId                  I2   ?
SessionNo                      I    ?
TVMId                          BF   ?
TableKind                      CF   ?
ProtectionType                 CF   ?
TempFlag                       CF   ?
HashFlag                       CF   ?
NextIndexId                    I2   ?
NextFieldId                    I2   ?
Version                        I2   ?
RequestText                    CV   ?
CreateText                     CV   ?
CommentString                  CV   ?
CreatorName                    CF   ?
TVMName                        CF   ?
JournalFlag                    CF   ?
JournalId                      BF   ?
UtilVersion                    I2   Returns the utility version count. This
AccLogRules                    CF   ?
ColumnAccRules                 I2   ?
CheckOpt                       CF   ?
ParentCount                    I2   ?
ChildCount                     I2   ?
NamedTblCheckCount             I2   ?
UnnamedTblCheckExist           CF   ?
PrimaryKeyIndexId              I2   ?
CreateUID                      BF   ?
CreateTimeStamp                TS   ?
LastAlterUID                   BF   ?
LastAlterTimeStamp             TS   ?
TriggerCount                   I2   ?
CommitOpt                      CF   ?
TransLog                       CF   ?
LastAccessTimeStamp            TS   ?
AccessCount                    I    ?
SPObjectCodeRows               I    ?
RSGroupID                      I    ?
TblRole                        CF   ?
TblStatus                      CF   ?
RequestTxtOverflow             CF   ?
CreateTxtOverflow              CF   ?
QueueFlag                      CF   ?
XSPExternalName                CF   ?
XSPOptions                     CF   ?
XSPExtFileReference            CV   ?
ExecProtectionMode             CF   ?
CharacterType                  I2   ?
Platform                       CF   ?
AuthIdUsed                     BF   ?
AuthorizationType              CF   ?
AuthorizationSubType           CF   ?
OSDomainName                   CF   ?
OSUserName                     CF   ?


--**********************************************************************************
