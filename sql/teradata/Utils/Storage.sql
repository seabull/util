/*-Settings--------------------------
BackColor:SkyBlue;
EnvironmentID:63356490;
EnvironmentName:Teradata Prod;
Highlights:<?xml version="1.0"?><Highlights><Color ARGB="Syntax error"><Span start="6054" end="6078" /><Span start="6819" end="6825" /><Span start="15253" end="15270" /><Span start="15840" end="15857" /><Span start="16202" end="16219" /><Span start="20996" end="20997" /><Span start="21035" end="21036" /><Span start="22296" end="22301" /><Span start="22390" end="22393" /><Span start="22407" end="22412" /><Span start="22514" end="22527" /><Span start="22562" end="22575" /><Span start="22608" end="22621" /><Span start="33137" end="33142" /><Span start="33231" end="33234" /><Span start="33248" end="33253" /><Span start="33355" end="33368" /><Span start="33403" end="33416" /><Span start="33449" end="33462" /><Span start="43410" end="43434" /><Span start="50849" end="50861" /><Span start="50891" end="50916" /><Span start="50946" end="50971" /><Span start="51001" end="51008" /><Span start="51038" end="51059" /><Span start="51091" end="51116" /><Span start="51137" end="51164" /><Span start="51194" end="51221" /><Span start="52838" end="52849" /><Span start="52946" end="52960" /><Span start="52981" end="52997" /><Span start="53027" end="53043" /><Span start="53117" end="53134" /><Span start="53164" end="53187" /><Span start="53217" end="53244" /><Span start="53274" end="53304" /><Span start="53334" end="53358" /><Span start="53390" end="53416" /><Span start="53437" end="53465" /><Span start="53495" end="53523" /><Span start="53549" end="53577" /><Span start="53675" end="53699" /><Span start="57765" end="57792" /><Span start="71865" end="71895" /><Span start="71925" end="71953" /><Span start="76212" end="76235" /><Span start="78983" end="78995" /><Span start="79365" end="79391" /><Span start="79425" end="79451" /><Span start="79681" end="79682" /><Span start="79742" end="79743" /><Span start="79863" end="79864" /><Span start="79919" end="79920" /><Span start="79981" end="79982" /><Span start="80041" end="80042" /><Span start="80108" end="80109" /><Span start="80220" end="80221" /><Span start="80277" end="80278" /><Span start="80339" end="80340" /><Span start="80372" end="80373" /><Span start="82491" end="82492" /><Span start="82509" end="82510" /><Span start="82528" end="82529" /><Span start="82548" end="82549" /><Span start="82568" end="82569" /><Span start="82624" end="82636" /><Span start="82652" end="82653" /><Span start="82848" end="82874" /><Span start="82898" end="82924" /><Span start="88085" end="88105" /></Color></Highlights>;
Title:Storage;
-----------------------------------*/
DIAGNOSTIC VERBOSEEXPLAIN ON FOR SESSION;
DIAGNOSTIC HELPSTATS ON FOR SESSION;
DIAGNOSTIC STATHASHPART ON FOR SESSION;

SELECT add_months(current_date - extract(day FROM current_date) + 1, -1), 
	current_date - extract(day FROM current_date)

-- compression analysis

SELECT dbt.DATABASENAME,
       dbt.TABLENAME,
       MAX(CASE WHEN (compressvaluelist IS NOT NULL) 
                THEN (CASE WHEN INDEX(compressvaluelist,',') > 0
                           THEN '3. MVC '
                           ELSE '2. SVC '
                           END)
                ELSE '1. NONE'
                END) COMPRESS_TYPE,
       MIN(pds.Current_Perm)/(1024*1024) CURRENT_PERM_In_MB
  FROM dbc.columns dbt,
      (SELECT t.DATABASENAME,
              t.TABLENAME,
              SUM(ts.CurrentPerm) CURRENT_PERM 
         FROM DBC.Tables t,
              DBC.TableSize ts
        WHERE t.DATABASENAME = ts.DATABASENAME
          AND t.TABLENAME = ts.TABLENAME
          AND ts.TABLENAME <> 'ALL'
          and t.DATABASENAME IN ('prodbbymeadhocdb','prodbbymeadhocwrk')
       HAVING CURRENT_PERM > 1000000000 --10000000000
        GROUP BY 1,2
    ) pds
WHERE dbt.DATABASENAME IN ('prodbbymeadhocdb','prodbbymeadhocwrk')
  AND dbt.DATABASENAME = pds.DATABASENAME
  AND dbt.TABLENAME = pds.TABLENAME
-- HAVING COMPRESS_TYPE = '1. NONE'
GROUP BY 1,2
ORDER BY 1,3, 4 DESC,2

-- Stats Analysis

SELECT S.DATABASENAME,
       S.TABLENAME,
       S.COLLECTDATE (FORMAT 'YYYY-MM-DD'),
       CASE WHEN D.VALUES_SUM = 0
            THEN 'ZERO OR NO STATS'
            ELSE 'DIFF COLL DATES '
            END CHECK_STATS
  FROM prodbbymeadhocvws.rasc_stats_details S, --Stats_Info_64bit S,
( 
SELECT DATABASENAME,
       TABLENAME,
       COUNT(DISTINCT COLLECTDATE) NUM_DATES,
       SUM(COALESCE(NumValues,0)) VALUES_SUM
  FROM prodbbymeadhocvws.rasc_stats_details --Stats_Info_64bit 
WHERE DATABASENAME IN ('prodbbymeadhocdb','prodbbymeadhocwrk')
GROUP BY 1,2
HAVING NUM_DATES > 1
    OR VALUES_SUM = 0
) D
WHERE S.DATABASENAME = D.DATABASENAME
  AND S.TABLENAME    = D.TABLENAME
GROUP BY 1,2,3,4
ORDER BY 1,2,3
;

SELECT *
  FROM PRODBBYMEADHOCVWS.rasc_stats_check
 WHERE CHECK_STATS = 'ZERO OR NO STATS'
   AND TotalPermMB > 1

 -- string manipulation search

SELECT ACCOUNT_STRING,
       QUALIFIED_QUERIES (FORMAT 'ZZZ,ZZZ,ZZ9'),
       (USE_SUBSTR / (QUALIFIED_QUERIES (FLOAT))) * 100 (FORMAT 'ZZ9.99') PER_SUBSTR,
       (USE_POS / (QUALIFIED_QUERIES (FLOAT))) * 100 (FORMAT 'ZZ9.99') PER_POSITION,
       (USE_LIKE / (QUALIFIED_QUERIES (FLOAT))) * 100 (FORMAT 'ZZ9.99') PER_LIKE,
       (USE_TRIM / (QUALIFIED_QUERIES (FLOAT))) * 100 (FORMAT 'ZZ9.99') PER_TRIM,
       (USE_CONCAT / (QUALIFIED_QUERIES (FLOAT))) * 100 (FORMAT 'ZZ9.99') PER_CONCAT
FROM
(
SELECT ACCOUNT_STRING,
       COUNT(*) QUALIFIED_QUERIES,
       SUM(CASE WHEN WHERE_CLAUSE LIKE '%SUBSTR%' THEN 1 ELSE 0 END) USE_SUBSTR,
       SUM(CASE WHEN WHERE_CLAUSE LIKE '%POSITION%' THEN 1 ELSE 0 END) USE_POS,
       SUM(CASE WHEN WHERE_CLAUSE LIKE '%TRIM%' THEN 1 ELSE 0 END) USE_TRIM,
       SUM(CASE WHEN WHERE_CLAUSE LIKE '%LIKE%' THEN 1 ELSE 0 END) USE_LIKE,
       SUM(CASE WHEN WHERE_CLAUSE LIKE '%||%' THEN 1 ELSE 0 END) USE_CONCAT
FROM
(
SELECT l.LOGDATE,
       -- USING TERADATA PERFORMANCE COE RECOMMENDED ACCOUNT STRING FORMAT
       SUBSTR(AcctString,5,4) ACCOUNT_STRING,
       POSITION('WHERE' IN s.sqltextinfo) WHERE_POS,
       SUBSTR(s.sqltextinfo, WHERE_POS, 32000 - WHERE_POS) WHERE_CLAUSE
FROM PDCRINFO.DBQLogTbl l,
     PDCRINFO.DBQLSqlTbl s
WHERE l.ProcID = s.ProcID
  AND l.QueryID = s.QueryID
  AND s.SqlRowNo = 1 
  AND l.LOGDATE BETWEEN CURRENT_DATE - 14  AND date - 1 --30
  and s.LogDate BETWEEN CURRENT_DATE - 14  AND date - 1 --30
  AND WHERE_POS > 0
  AND ACCOUNT_STRING = '$M1$&D&H&SMEADHOC' --NOT IN ('XXXX','YYYY')
) QQ
HAVING QUALIFIED_QUERIES > 100
   AND ( USE_SUBSTR > 0 OR
         USE_POS > 0 OR
         USE_TRIM > 0 OR
         USE_LIKE > 0 OR
         USE_CONCAT > 0
       )
GROUP BY 1
) FF
ORDER BY 2 DESC,1

SELECT *
  FROM PDCRINFO.DBQLSqlTbl
  sample 10
 
CREATE VIEW PRODBBYMEADHOCVWS.rasc_stats_check
as
SELECT S.DATABASENAME,
       S.TABLENAME,
       S.COLLECTDATE (FORMAT 'YYYY-MM-DD'),
       CASE WHEN D.VALUES_SUM = 0
            THEN 'ZERO OR NO STATS'
            ELSE 'DIFF COLL DATES '
            END CHECK_STATS
		,tvm.creatorName, tvm.CreateTimeStamp, tvm.TotalPermMB, tvm.SkewFactor, tvm.lastAccessed
  FROM prodbbymeadhocvws.rasc_stats_details S, --Stats_Info_64bit S,
( 
SELECT DATABASENAME,
       TABLENAME,
       COUNT(DISTINCT COLLECTDATE) NUM_DATES,
       SUM(COALESCE(NumValues,0)) VALUES_SUM
  FROM prodbbymeadhocvws.rasc_stats_details --Stats_Info_64bit 
WHERE DATABASENAME IN ('prodbbymeadhocdb','prodbbymeadhocwrk')
GROUP BY 1,2
HAVING NUM_DATES > 1
    OR VALUES_SUM = 0
) D
LEFT JOIN PRODBBYMEADHOCVWS.rasc_TVMAccess_info tvm
	on D.databasename = tvm.databaseName
	AND D.tablename = tvm.tablename
WHERE S.DATABASENAME = D.DATABASENAME
  AND S.TABLENAME    = D.TABLENAME
GROUP BY 1,2,3,4,5,6,7,8,9
--HAVING CHECK_STATS = 'ZERO OR NO STATS'
--ORDER BY 1,2,3


SELECT *
  FROM PRODBBYMEADHOCVWS.rasc_stats_details
  sample 10

select UserName, LogonDateTime, AcctStringDate, LogonSource, AppID, ClientID, ClientAddr, QueryText
  from pdcrinfo.dbqlogtbl_hst
 where AppID in ('QVB', 'QV')
   and ClientAddr in ('168.94.11.86','168.94.11.74')
   --and LogonDateTime > date - 2
   and LogDate between date - 2 and date
   and UserName <> 'RASC_FORT_BCH'

select * --UserName, LogonDateTime, AcctStringDate, LogonSource, AppID, ClientID, ClientAddr, QueryText
  from pdcrinfo.dbqlogtbl_hst
 where UserName <> ClientID
   and LogDate between date - 12 and date
   and UserName in ('A833360', 'A198308')
   and ClientID in ('A833360', 'A198308')
--   and 
--   		ClientID = 'A833360' --'A198308'
  
 where AppID in ('QVB', 'QV')
   and ClientAddr in ('168.94.11.86','168.94.11.74')
   --and LogonDateTime > date - 2
   and LogDate between date - 2 and date
   and UserName <> 'RASC_FORT_BCH'


Create Macro prodbbymeadhocdb.RASC_DBPerf_Detail_purge
 --(fromDt(Date,Format 'yyyy-mm-dd')
 --,toDt(Date, Format 'yyyy-mm-dd')) 
 As (
Delete From PRODBBYMEADHOCDB.RASC_DBPerf_Detail
  Where Calndr_Dt < date - 731;
  --Where Calndr_Dt Between :fromDt And :toDt 
)

create view prodbbymeadhocvws.rasc_dbperf_detail_export
as
select Calndr_dt, Calndr_tm, 
		Fisc_Day_Of_Wk_Nbr, Fisc_Wk_id, Fisc_Wk_Yr_ID, Fisc_Wk_Nm, Fisc_Mth_ID,
		Fisc_Mth_Nm, Fisc_Yr_ID, 
		SQLType, SQLIdText, ActionID, AlertID, JobID, WaveID, SQLId, 
		UserName, UserType, Total_CPU, Total_IO
  from prodbbymeadhocvws.rasc_dbperf_detail_v
 where calndr_dt between date - 1 and date

--Skew
SELECT
HASHAMP(HASHBUCKET(HASHROW(col whose amp distribution that needs to be checked; eg: PI)))
,CAST(COUNT(*) AS DECIMAL(18,0))
FROM
DBNAME.TBLNAME
GROUP BY 1
ORDER BY 1 

select CollectTimeStamp, UserName, LogonDateTime, AppID,
	StartTime, TotalIOCount, TOtalCPUTime, ErrorCode
	, ErrorText, AbortFlag, QueryText, StatementType
	,SpoolUsage
  from dbc.QryLog --Summary --DBQLogSummary
 where CollectTimeStamp > cast(date - 1 as timestamp(2))
   and UserName = 'A323289'

DBQL(HotAmp)

drop table prodbbymeadhocwrk.rasc_qv_logon_hst

create table prodbbymeadhocwrk.rasc_qv_logon_hst
,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
(
      LogDate DATE FORMAT 'yyyy/mm/dd' NOT NULL,
      UserName VARCHAR(128) CHARACTER SET UNICODE NOT CASESPECIFIC,
      LogonDateTime TIMESTAMP(2),
      AcctStringDate DATE FORMAT 'yyyy-mm-dd',
      LogonSource CHAR(128) CHARACTER SET LATIN NOT CASESPECIFIC,
      AppID CHAR(30) CHARACTER SET UNICODE NOT CASESPECIFIC,
      ClientID CHAR(30) CHARACTER SET UNICODE NOT CASESPECIFIC,
      ClientAddr CHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC
)
PRIMARY INDEX NUPI_rasc_qv_logon_hst ( LogDate ,UserName )
--PARTITION BY RANGE_N(LogDate  BETWEEN DATE '2009-10-12' AND DATE '2012-12-31' EACH INTERVAL '1' DAY );

insert explain with stats into prodbbymeadhocqcd as "test1" 
select userid , count(*)
  from dbc.qrylog
  group by 1

select RptDate
		,ETL_Period
		,sum(cnt)
		,sum(Total_TPH_Saving)
  from (
select cast(eventts as date) RptDate
		, FORT_RPTID
		, case when extract(hour from eventts) < 10 then 'P2'
				when extract(hour from eventts) between 10 and 17 then 'P3'
				else 'P6'
				end ETL_Period
		, case when Fort_RptID = 80010 then 0.5
				when Fort_RptID = 80020 then 0.49
				when Fort_RptID = 80030 then 0.35
				when Fort_RptID = 80040 then 0.16
				end OldTPH
		, case when Fort_RptID = 80010 then 0.14
				when Fort_RptID = 80020 then 0.13
				when Fort_RptID = 80030 then 0.16
				when Fort_RptID = 80040 then 0.11
				end NewTPH				
		, count(*) cnt
		, OldTPH - NewTPH TPHSaving
		, TPHSaving * cnt Total_TPH_Saving
  from prodbbymeadhocdb.web_utilization
 where FORT_RPTID in (80010, 80020, 80030, 80040) 
 group by 1,2,3
 ) x
 where RptDate > '2009-06-07'
 group by 1,2
 order by 1,2--,3

WITH RECURSIVE rpt (ProjectID, ReportID, jobId, txt, lvl) AS
(
select projectID
		, ReportID
		, case when position(',' in JobID) > 0 
				then Substring(JobID From 0 for position(',' in JobID))
				else JobID
			end jobID
		, case when position(',' in JobID) > 0 
				then Substring(JobID From position(',' in JobID) + 1)
				else null
			end txt
		, 1 lvl
  from prodbbymeadhocdb.fort_prj_report
union all
select projectID
		, ReportID
		, case when position(',' in txt) > 0 
				then Substring(txt From 0 for position(',' in txt))
				else txt
			end 
		, case when position(',' in txt) > 0 
				then Substring(txt From position(',' in txt) + 1)
				else null
			end 
		,lvl + 1
  from rpt
 where txt is not null
  )
 select ProjectID, ReportID, jobID
   from rpt
--  where ProjectID = 143
order by ProjectID, ReportID

select
		x.RptDate
		,Fort_RptID
		,sum(AccessCount) over (partition by Fort_RptID order by RptDate rows between 1 preceding and 1 preceding) AccessCountDay_1
		,AccessCount
		,AccessCount - AccessCountDay_1 AccessIncrease
		,r.ReportName
  from (
	select cast(eventts as date) RptDate
			,Fort_RptID
			--,case when extract(hour from eventts) < 10 then 'P2'
			--		when extract(hour from eventts) between 10 and 17 then 'P3'
			--		else 'P6'
			--		end ETL_Period
			,count(*) AccessCount
	from prodbbymeadhocdb.web_utilization
	group by 1,2--,3
) x
left join prodbbymeadhocdb.fort_prj_report r
	on x.Fort_RptID = r.ReportID
 where RptDate > '2009-05-28'
order by 1,5 Desc, 4

select cast(eventts as date) RptDate
		,Fort_RptID
		--,case when extract(hour from eventts) < 10 then 'P2'
		--		when extract(hour from eventts) between 10 and 17 then 'P3'
		--		else 'P6'
		--		end ETL_Period
		,count(*) AccessCount
  from prodbbymeadhocdb.web_utilization
 where RptDate > '2009-05-27'
   and Fort_RptID = 155001 --3800 --2080010
group by 1,2--,3
order by 1,2

select --case when RptDate < '2009-05-31' then 'Pre-May-31' 
		--	else 'Post-May-31'
		--	end Rpt
		--,
		Fort_RptID
		,sum(case when RptDate < '2009-05-31' then AccessCount else 0 end) TotalPreMay31Access
		,sum(case when RptDate >= '2009-05-31' then AccessCount else 0 end) TotalPostMay31Access
		,sum(case when RptDate < '2009-05-31' then 1 else 0 end)  PreMay31Days
		,sum(case when RptDate >= '2009-05-31' then 1 else 0 end)  PostMay31Days
		,cast(case when PreMay31Days = 0 then 0 else TotalPreMay31Access/PreMay31Days end as integer) AvgPreMay31
		,cast(case when PostMay31Days = 0 then 0 else TotalPostMay31Access/PostMay31Days end as integer) AvgPostMay31
		,AvgPostMay31 - AvgPreMay31 AccessIncrease
		,r.ReportName
		--,count(*) TotalDays
		--,TotalAccess/TotalDays AvgByDay
		--,cast(avg(AccessCount) as integer) avgAccess
  from
(
select
		cast(eventts as date) RptDate
		,Fort_RptID
		--,case when extract(hour from eventts) < 10 then 'P2'
		--		when extract(hour from eventts) between 10 and 17 then 'P3'
		--		else 'P6'
		--		end ETL_Period
		,count(*) AccessCount
  from prodbbymeadhocdb.web_utilization
 where RptDate > '2009-05-01'
   --and Fort_RptID = 155001 --3800 --2080010
group by 1,2--,3
) x
left join prodbbymeadhocdb.fort_prj_report r
	on x.Fort_RptID = r.ReportID
group by 1, 9--,2
order by 8 DESC,1


  
show table prodbbymeadhocdb.fort_prj_report 

select top 10 *
  from prodbbymeadhocdb.rasc_lu_ldap_emp --dbc.tables
  
select --top 10 
		r.tableName
		,t.TableKind
		,t.AccessCount
		,t.CreateTimeStamp
		,t.LastAccessTimeStamp
		,t.creatorName
		,trim(e.FirstName) ||' ' || trim(e.LastName) CreatorFullName
		--,t.LastAlterName
		,r.ReportName
		--,substring(TableName from 1 for index(trim(TableName), '.') - 1)
		--,substring(TableName from index(trim(TableName), '.') + 1)
  from prodbbymeadhocdb.fort_prj_report r
  join dbc.tables t
		on t.databasename = substring(r.TableName from 1 for index(trim(r.TableName), '.') - 1)
   and t.tableName = substring(r.TableName from index(trim(r.TableName), '.') + 1)
  left join prodbbymeadhocdb.rasc_lu_ldap_emp e
  		on t.creatorName = e.ldap_id
 where t.databasename = substring(r.TableName from 1 for index(trim(r.TableName), '.') - 1)
   and t.tableName = substring(r.TableName from index(trim(r.TableName), '.') + 1)
 group by 1,2,3,4,5,6,7,8
  order by t.AccessCount DESC
  
select cast(eventts as date) RptDate
		,Fort_RptID
		,count(*)
  from prodbbymeadhocdb.web_utilization
 where Fort_RptID in (402001, 402555)
group by 1,2
order by 1 DESC

select 
		databasename
		,cast(sum(currentPerm)/(1024*1024*1024) as decimal(20,6)) as currentPermGB
  from dbc.tablesize
 where databaseName in ('prodbbymeadhocdb', 'prodbbymeadhocwrk')
group by 1

replace view prodbbymeadhocvws.rasc_nonFortBch_Access_30D
as
	locking row for access
select t.databasename, t.tablename, x.ObjectTableName, max(x.logDate) lastAccessDate
  from dbc.tables t
  left join 
  (select obj.Objectdatabasename, obj.Objecttablename, obj.LogDate
     from pdcrinfo.DBQLObjTbl_Hst obj
   join pdcrinfo.DBQLogTbl_Hst dbql
  	on dbql.procID = obj.ProcID
	and dbql.QueryID = obj.QueryID
	and dbql.UserName <> 'RASC_FORT_BCH'
    and dbql.LogDate > date - 31
	where
	 obj.Objectdatabasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
	and obj.ObjectType = 'Tab'
	and obj.LogDate > date - 31
	) x
	  	on t.tablename = x.ObjectTableName
	and t.databasename = x.ObjectDatabaseName
 where t.databasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
   and t.tablename not like 'bu0a%'
   and t.tablename not like 'bu1a%'
   and t.tablename not like 'bu2a%'
   and t.tablename not like 'bu3a%'
   and t.tablename not like 'bu4a%'
   --and t.tablename = 'haiku'
 group by 1,2,3
 having lastAccessDate is null

CREATE SET TABLE prodbbymeadhocwrk.TableSizeHist ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      databaseName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      tableName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      creatorName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      TotalPermMB DECIMAL(16,2),
      skewFactor DECIMAL(5,2),
      RecModTS TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP(0))
PRIMARY INDEX ( databaseName ,tableName ,RecModTS )
INDEX ( databaseName ,tableName );

help STATISTICS PRODBBYMEADHOCWRK.tableSizeHist

CREATE SET TABLE PRODBBYMEADHOCWRK.tableSizeHist_New ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      databaseName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      tableName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      creatorName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      TotalPermMB DECIMAL(16,2),
      TotalPeakMB DECIMAL(16,2),
      skewFactor DECIMAL(5,2),
      RecModTS TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP(0))
PRIMARY INDEX ( databaseName ,tableName ,RecModTS )
INDEX ( databaseName ,tableName );

insert into PRODBBYMEADHOCWRK.tableSizeHist_New 
(databasename,tablename	,creatorName,TotalPermMB,TotalPeakMB,skewFactor	,RecModTS)
SELECT databasename
		,tablename
		,creatorName
		,TotalPermMB
		,TotalPermMB
		,skewFactor
		,RecModTS
  FROM PRODBBYMEADHOCWRK.tableSizeHist

rename TABLE PRODBBYMEADHOCWRK.tableSizeHist to PRODBBYMEADHOCWRK.tableSizeHist_Old
;rename TABLE PRODBBYMEADHOCWRK.tableSizeHist_New to PRODBBYMEADHOCWRK.tableSizeHist

COLLECT STATISTICS on PRODBBYMEADHOCWRK.tableSizeHist index (databaseName ,tableName ,RecModTS )
;COLLECT STATISTICS on PRODBBYMEADHOCWRK.tableSizeHist index (databaseName ,tableName )
;COLLECT STATISTICS on PRODBBYMEADHOCWRK.tableSizeHist column (databaseName )
;COLLECT STATISTICS on PRODBBYMEADHOCWRK.tableSizeHist column (tableName)
;COLLECT STATISTICS on PRODBBYMEADHOCWRK.tableSizeHist column (RecModTS)

select *
  from prodbbymeadhocwrk.TableSizeHist 
 where tableName like '%FMS%'
   and databasename = 'prodbbymeadhocwrk'
 order by RecModTS, tablename

CREATE SET TABLE prodbbymeadhocwrk.TVMAccessExclusionList ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      databaseName 	VARCHAR(30) NOT NULL,
      tableName 	VARCHAR(30) NOT NULL,
	  tableKind		char(1),
	  reasonToKeep	VARCHAR(100),
	  requestedBy	VARCHAR(30),
	  keepUntil	    date,
	  RecModTS		TIMESTAMP(0) Default Current_timestamp(0)
	  )
primary Index (databasename, tablename)

alter table prodbbymeadhocwrk.TVMAccessExclusionList 
	add keepUntil	    date;

show table prodbbymeadhocwrk.TVMAccessExclusionList

collect stats prodbbymeadhocwrk.TVMAccessExclusionList index (databaseName, tableName)
;collect stats prodbbymeadhocwrk.TVMAccessExclusionList column (tableKind)
;collect stats prodbbymeadhocwrk.TVMAccessExclusionList column (requestedBy)
;collect stats prodbbymeadhocwrk.TVMAccessExclusionList column (RecModTS)
;collect stats prodbbymeadhocwrk.TVMAccessExclusionList column (reasonToKeep) 

insert into prodbbymeadhocwrk.TVMAccessExclusionList (databasename, tableName, tableKind, reasonToKeep, requestedBy)
	Values
	('prodbbymeadhocdb','','T','','')

--drop table prodbbymeadhocwrk.TVMAccessHist 

CREATE SET TABLE prodbbymeadhocwrk.TVMAccessHist ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      databaseName VARCHAR(30),
      tableName VARCHAR(30),
      creatorName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      TotalPermMB DECIMAL(16,2),
      skewFactor DECIMAL(5,2),
	  lastAccessTimestamp timestamp,
	  totalAccessCount bigint,
	  createTimestamp timestamp,
	  tableKind	char(1),
      RecModTS TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP(0)
)
PRIMARY INDEX ( databaseName ,tableName ,RecModTS )
INDEX ( databaseName ,tableName )
INDEX ( totalAccessCount)

collect stats prodbbymeadhocwrk.TVMAccessHist index ( databaseName ,tableName ,RecModTS )
;collect stats prodbbymeadhocwrk.TVMAccessHist index ( databaseName ,tableName )
;collect stats prodbbymeadhocwrk.TVMAccessHist index ( totalAccessCount )


alter table prodbbymeadhocwrk.TVMAccessHist
	add tableKind	char(1)

insert into prodbbymeadhocwrk.TVMAccessHist
(databaseName, tableName, creatorName, TotalPermMB, skewFactor, lastAccessTimestamp, totalAccessCount, createTimestamp, tableKind)

--drop view prodbbymeadhocvws.rasc_TVMAccess_info

SHOW VIEW rasc_TVMAccess_info

replace view prodbbymeadhocvws.rasc_TVMAccess_info
as
	locking row for access
SELECT  
		t.databasename
		, t.tablename
		, t.creatorName
		, t.createTimestamp
		, t.tableKind
        , cast(cast(sum(currentperm) as decimal(24,4))/(1024*1024) as decimal(16,2)) as TotalPermMB
		--, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(cast(AVG(CurrentPerm) as decimal(18,4))/cast(MAX(CurrentPerm) as decimal(18,4))*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(cast(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end as bigint)) TotalAccess
  FROM dbc.tables t 
  left outer join dbc.TableSize ts
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where t.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk', 'prodbbymeadhocvws', 'prodbbymeadhocrptdb')
   and t.tablename not like 'bu%'
 group by 1,2,3,4,5
-- having TotalAccess = 0
--having SkewFactor > 10 and TotalPermMB > 50
--order by 1,4,6,2
--order by 8,1,4 DESC,3,2

help column dbc.tables.*

delete from prodbbymeadhocwrk.TVMAccessHist
 where RecModTS < cast(date - 365 as timestamp)

collect stats prodbbymeadhocwrk.TVMAccessHist index (databaseName, tableName)
;collect stats prodbbymeadhocwrk.TVMAccessHist index (totalAccessCount)
;collect stats prodbbymeadhocwrk.TVMAccessHist column (lastAccessTimestamp)
;collect stats prodbbymeadhocwrk.TVMAccessHist column (creatorName)
;collect stats prodbbymeadhocwrk.TVMAccessHist column (RecModTS)
--collect stats prodbbymeadhocwrk.TVMAccessHist column (TotalPermMB

collect stats prodbbymeadhocwrk.TVMAccessHist column (tableKind)

help column dbc.tables.*

update a 
  from prodbbymeadhocwrk.TVMAccessHist as a
  			, dbc.tables as t
   set tableKind = t.tableKind
 where a.databasename = t.databasename
   and a.tablename = t.tablename
   
   
select *
  from prodbbymeadhocwrk.TVMAccessHist
 where cast(RecModTS as date) > date - 2

		--,tablename
		--,cast(sum(currentPerm)/(1024*1024) as decimal(20,6)) as currentPermMB
		--,cast(currentPermGB/290 as decimal(16,4)) as usage

select *
  from prodbbymeadhocvws.rasc_db_space 

replace view prodbbymeadhocvws.rasc_db_space_by_amp
as
locking row for access
select vproc, cast(sum(currentperm)/(1024*1024) as decimal(16,4)) UsedPermMB
	, cast(sum(maxPerm)/(1024*1024) as decimal(16,4)) MaxPermMB
	, cast(sum(PeakPerm)/(1024*1024) as decimal(16,4)) PeakPermMB
	, cast(UsedPermMB/MaxPermMB as decimal(10,4))*100 UsagePct
  from dbc.diskspace
 where databasename in ('prodbbymeadhocdb', 'prodbbymeahocwrk', 'prodbbymeadhocrptdb')
 group by vproc

 order by 2 desc

--replace view prodbbymeadhocvws.rasc_db_space as locking row for access

SELECT current_timestamp(0) currentTime,
		d.DatabaseName,
		SUM ( CURRENTPERMspace ) / 1024 / 1024 AS USED_MB ,
		d.PERMSPACE / 1024 / 1024 AS MAX_MB ,
		CAST( USED_MB AS DEC ( 18 , 6 ) ) / CAST( MAX_MB AS DEC ( 18 ,6 ) ) AS USE_PCT
FROM (select dbase.databasenamei,
			dbase.databaseid,
			dbase.permspace,
			tvm.tvmid,
			tvm.tvmnamei
		from DBC.Dbase dbase,
			DBC.TVM tvm
		where Dbase.databasenamei iN ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd')
		  and TVM.DatabaseId = Dbase.DatabaseId
		) d ( databasename, databaseid, permspace, tvmid, tablename),
		DBC.DataBaseSpace
WHERE DataBaseSpace.TableID <> '000000000000'XB
  AND DataBaseSpace.DatabaseId = d.DatabaseId
  AND DataBaseSpace.TableID = d.tvmid
group by 1,2,4

replace view prodbbymeadhocvws.rasc_db_space as locking row for access
 select
 current_timestamp(0) currentTime
 ,databasename
 ,case when max(PermSpaceGB) > 0 then cast( max(currentPermGB)/max(PermSpaceGB)*100 as decimal(20,4) ) else 0 end as PermUsagePct
 ,max(currentPermGB) currentPermGB
 ,max(PermSpaceGB) permSpaceGB
 ,case when max(PermSpaceGB) > 0 then cast( max(peakPermGB)/max(PermSpaceGB)*100 as decimal(20,4) ) else 0 end as PeakUsagePct
 ,max(peakPermGB) peakSpaceGB
 from (
 select databasename
 ,cast(sum(currentPerm)/(1024*1024*1024) as decimal(20,6)) as currentPermGB
 ,cast(sum(PeakPerm)/(1024*1024*1024) as decimal(20, 6)) as PeakPermGB
 ,cast(0 as decimal(20, 6)) as PermSpaceGB
 ,cast(0 as decimal(20, 6)) as TempSpaceGB
 ,cast(0 as decimal(20, 6)) as SpoolSpaceGB
 from dbc.tablesize ts
 where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd', 'prodbbymeadhocrptdb', 'prodbbymeadhocArc')
 group by DatabaseName
 union all
 select databasename
 ,0 as currentPermGB
 ,0 as PeakPermGB
 ,cast(sum(PermSpace)/(1024*1024*1024) as decimal(20, 6))  as PermSpaceGB
 ,cast(sum(TempSpace)/(1024*1024*1024) as decimal(20, 6))  as TempSpaceGB
 ,cast(sum(spoolSpace)/(1024*1024*1024) as decimal(20, 6)) as SpoolSpaceGB
 from dbc.databases
 where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd', 'prodbbymeadhocrptdb', 'prodbbymeadhocArc')
 group by databaseName
 ) x
 group by 1,2

replace view prodbbymeadhocvws.rasc_table_storage as 
	locking row for access
SELECT  
		ts.databasename
		, ts.tablename
		, t.creatorName
        , cast(sum(currentperm)/(1024*1024) as decimal(20,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, cast(sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then cast(AccessCount as bigint) else 0 end) as bigint) TotalAccess
  FROM dbc.TableSize ts 
  left outer join dbc.tables t
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk', 'prodbbymeadhocrptdb')
 group by 1,2,3

create view prodbbymeadhocvws.rasc_storage_by_owner as 
	locking row for access
SELECT  
		--ts.databasename
		--, ts.tablename
		t.creatorName
		, e.FirstName || ' ' || e.LastName ownerName
		, t.tablename
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		--, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		--, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		--, max(lastAccessTimeStamp) lastAccessed
		--, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
  FROM dbc.TableSize ts 
  left outer join dbc.tables t
  		on ts.databasename = t.databasename
		and ts.tablename = t.tablename
  left outer join prodbbymeadhocvws.rasc_lu_ldap_employee e
  		on t.creatorName = e.LDAP_ID
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2,3

-- skew information for a table

select  hashamp(hashbucket(hashrow(REPORT_ID ,TIMELVL ,TIMEID )))  AMP# 
		, count(*)   "Nbr of Rows on the AMP"
 from PRODBBYMEADHOCWRK.PNL_MODEL_VERT
group by 1 order by 1 ;

select
		t.creatorName
		, e.FirstName || ' ' || e.LastName ownerName
		, t.tablename
        , cast(sum(TotalPermMB)/1024 as decimal(16,2)) as TotalPermGB
  from prodbbymeadhocvws.rasc_table_storage t
left outer join prodbbymeadhocvws.rasc_lu_ldap_employee e
  on lower(t.creatorName) = lower(e.Ldap_ID)
 where t.databasename in ('prodbbymeadhocwrk') --( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2,3

select
         current_timestamp(0) currentTime
        ,databasename                                                                                                               
        ,case when max(PermSpaceGB) > 0 then cast( max(currentPermGB)/max(PermSpaceGB)*100 as decimal(20,4) ) else 0 end as PermUsagePct 
       ,max(currentPermGB) currentPermGB
       ,max(PermSpaceGB) permSpaceGB
  from (                                                                                                                          
        select databasename                                                                                                       
            ,cast(sum(currentPerm)/(1024*1024*1024) as decimal(20,6)) as currentPermGB                                            
            ,cast(sum(PeakPerm)/(1024*1024*1024) as decimal(20, 6)) as PeakPermGB                                                 
            ,cast(0 as decimal(20, 6)) as PermSpaceGB                                                                             
            ,cast(0 as decimal(20, 6)) as TempSpaceGB                                                                             
            ,cast(0 as decimal(20, 6)) as SpoolSpaceGB                                                                            
          from dbc.tablesize ts                                                                                                   
          where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd')                                                         
          group by DatabaseName                                                                                                   
        union all                                                                                                                    
          select databasename                                                                                                     
                ,0 as currentPermGB                                                                                               
                ,0 as PeakPermGB                                                                                                  
                ,cast(sum(PermSpace)/(1024*1024*1024) as decimal(20, 6))  as PermSpaceGB                                          
                ,cast(sum(TempSpace)/(1024*1024*1024) as decimal(20, 6))  as TempSpaceGB                                          
                ,cast(sum(spoolSpace)/(1024*1024*1024) as decimal(20, 6)) as SpoolSpaceGB                                         
            from dbc.databases                                                                                                    
           where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd')                                                        
            group by databaseName                                                                                                 
    ) x                                                                                                                           
group by 1,2

Insert into prodbbymeadhocwrk.tableSizeHist
(databasename, tablename, creatorName, TotalPermMB, skewFactor)
select
        databasename
		,'All_Tables'
		,null
        ,max(currentPermMB)
        ,case when max(PermSpaceMB) > 0 then cast( max(currentPermMB)/max(PermSpaceMB)*100 as decimal(20,4) ) else 0 end as PermUsage 
  from (                                                                                                                          
        select databasename                                                                                                       
            ,cast(sum(currentPerm)/(1024*1024) as decimal(20,6)) as currentPermMB                                            
            ,cast(sum(PeakPerm)/(1024*1024) as decimal(20, 6)) as PeakPermMB                                                 
            ,cast(0 as decimal(20, 6)) as PermSpaceMB                                                                             
            ,cast(0 as decimal(20, 6)) as TempSpaceMB                                                                             
            ,cast(0 as decimal(20, 6)) as SpoolSpaceMB                                                                            
          from dbc.tablesize ts                                                                                                   
          where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk')                                                         
          group by DatabaseName                                                                                                   
        union all                                                                                                                    
          select databasename                                                                                                     
                ,0 as currentPermMB                                                                                               
                ,0 as PeakPermMB                                                                                                  
                ,cast(sum(PermSpace)/(1024*1024) as decimal(20, 6))  as PermSpaceMB                                          
                ,cast(sum(TempSpace)/(1024*1024) as decimal(20, 6))  as TempSpaceMB                                          
                ,cast(sum(spoolSpace)/(1024*1024) as decimal(20, 6)) as SpoolSpaceMB                                         
            from dbc.databases                                                                                                    
           where databaseName in ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk')                                                        
            group by databaseName                                                                                                 
    ) x                                                                                                                           
group by 1,2,3

SELECT 
		d.DatabaseName,
		'All_Tables',
		null,
		SUM ( CURRENTPERMspace ) / 1024 / 1024 AS USED_MB ,
		--d.PERMSPACE / 1024 / 1024 AS MAX_MB ,
		CAST( SUM ( CURRENTPERMspace ) / 1024 / 1024 AS DEC ( 18 , 6 ) ) / CAST( d.PERMSPACE / 1024 / 1024 AS DEC ( 18 ,6 ) ) * 100 AS USE_PCT
FROM (select dbase.databasenamei,
			dbase.databaseid,
			dbase.permspace,
			tvm.tvmid,
			tvm.tvmnamei
		from DBC.Dbase dbase,
			DBC.TVM tvm
		where Dbase.databasenamei iN ('Prodbbymeadhocdb', 'Prodbbymeadhocwrk', 'prodbbymeadhocqcd')
		  and TVM.DatabaseId = Dbase.DatabaseId
		) d ( databasename, databaseid, permspace, tvmid, tablename),
		DBC.DataBaseSpace
WHERE DataBaseSpace.TableID <> '000000000000'XB
  AND DataBaseSpace.DatabaseId = d.DatabaseId
  AND DataBaseSpace.TableID = d.tvmid
group by d.DatabaseName, d.PERMSPACE



select databasename
		,tablename
		,TotalPermMB
		,skewFactor
		,RecModTS
  from prodbbymeadhocwrk.tableSizeHist x
 where tablename = 'All_Tables'
order by databasename, RecModTS

show table prodbbymeadhocwrk.tableSizeHist

select databasename
		,tablename
		,creatorName
		--,RecModTS
		--,cast(RecModTS as date)
		,max(case when cast(RecModTS as date) <= date '2011-04-20' then TotalPermMB else 0 end) TotalPermMB_20 
		,max(case when cast(RecModTS as date) >= date '2011-04-21' then TotalPermMB else 0 end) TotalPermMB_21 
		,TotalPermMB_21 - TotalPermMB_20 delta
  from prodbbymeadhocwrk.tableSizeHist
 where cast(RecModTS as date) > date '2011-04-01'
   and cast(RecModTS as date) < date '2011-04-29'
   and tablename <> 'All_Tables'
   AND databasename = 'PRODBBYMEADHOCWRK'
group by 1,2,3
having delta > 10

SELECT databasename, sum(x.TotalPermMB) TotalUsageMB
		,sum(CASE WHEN TableName  like 'BBYM%' then x.TotalPermMB else 0 end) BBYMUsage
		, cast(BBYMUsage*100/TotalUsageMB as decimal(5,2)) BBYMPct
  FROM PRODBBYMEADHOCVWS.rasc_tvmaccess_info x
-- WHERE x.TableName like 'BBYM%'
 GROUP by 1
 
   select databasename
		,tablename
		,creatorName
		--,RecModTS
		--,cast(RecModTS as date)
		,max(case when cast(RecModTS as date) <= date '2009-04-23' then TotalPermMB else 0 end) TotalPermMB_04 
		,max(case when cast(RecModTS as date) >= date '2009-08-24' then TotalPermMB else 0 end) TotalPermMB_05 
		--,max(case when cast(RecModTS as date) <= date '2009-07-10' then TotalPermMB else 0 end) TotalPermMB_04 
		--,max(case when cast(RecModTS as date) >= date '2009-07-13' then TotalPermMB else 0 end) TotalPermMB_05 
		,TotalPermMB_05 - TotalPermMB_04 delta
  from prodbbymeadhocwrk.tableSizeHist
 where tablename <> 'All_Tables'
   and databasename = 'prodbbymeadhocdb'
   and cast(RecModTS as date) >= date '2009-04-23'
   and cast(RecModTS as date) <= date '2009-08-24'
group by 1,2,3
having delta < -100

having delta > 100

-- Table size change

select databasename
		,tablename
		,creatorName
		--,RecModTS
		--,cast(RecModTS as date)
		,max(case when cast(RecModTS as date) <= date '2010-01-13' then TotalPermMB else 0 end) TotalPermMB_04 
		,max(case when cast(RecModTS as date) >= date '2010-01-13' then TotalPermMB else 0 end) TotalPermMB_05 
		--,max(case when cast(RecModTS as date) <= date '2009-07-10' then TotalPermMB else 0 end) TotalPermMB_04 
		--,max(case when cast(RecModTS as date) >= date '2009-07-13' then TotalPermMB else 0 end) TotalPermMB_05 
		,TotalPermMB_05 - TotalPermMB_04 delta
  from prodbbymeadhocwrk.tableSizeHist
 where tablename <> 'All_Tables'
   and databasename = 'prodbbymeadhocdb'
   and cast(RecModTS as date) >= date '2010-01-10'
--   and cast(RecModTS as date) <= date '2009-07-24'
group by 1,2,3
having delta > 10

create view prodbbymeadhocvws.rasc_dbtbl_hist_7
 As Locking Row For Access
select databasename
		,tablename
		,creatorName
		--,RecModTS
		--,cast(RecModTS as date)
		,max(case when cast(RecModTS as date) <= date - 7/*date '2010-01-02'*/ then TotalPermMB else 0 end) TotalPermMB_04 
		,max(case when cast(RecModTS as date) >= date /*date '2009-01-03'*/ then TotalPermMB else 0 end) TotalPermMB_05 
		--,max(case when cast(RecModTS as date) <= date '2009-07-10' then TotalPermMB else 0 end) TotalPermMB_04 
		--,max(case when cast(RecModTS as date) >= date '2009-07-13' then TotalPermMB else 0 end) TotalPermMB_05 
		,TotalPermMB_05 - TotalPermMB_04 delta
from
(
select databasename, tablename, creatorName, TotalPermMB, date RecModTS
  from rasc_table_storage
 where databasename = 'prodbbymeadhocdb' --'prodbbymeadhocwrk'
   and TotalPermMB > 10
union all
select *
  from
(
select databasename, tablename, creatorName, Max(TotalPermMB) as TotalPermMB, date - 7 RecModTS
  from prodbbymeadhocwrk.tableSizeHist
 where tablename <> 'All_Tables'
   and databasename = 'prodbbymeadhocdb' --'prodbbymeadhocwrk'
   and cast(RecModTS as date) <= date - 7 --date '2010-01-03'
 group by 1,2,3,5
 ) x
) xx
group by 1,2,3
having delta > 10

select *
  from prodbbymeadhocvws.rasc_wrktbl_hist_7

select *
  from prodbbymeadhocvws.rasc_dbtbl_hist_7
  
select *
  from prodbbymeadhocwrk.tableSizeHist
  sample 10
  
select *
  from prodbbymeadhocvws.rasc_table_storage --rasc_db_space
 where databasename = 'prodbbymeadhocdb' --tablename = 'rasc_dbperf_detail' --'Vert00208_Basket_Suite'

  
-- Table Size Change

select
		databasename
		,tablename
		,creatorName
		,RecModTS
		,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 preceding and 1 preceding) TotalMBPreviousDay
		,TotalPermMB
		,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 following and 1 following) TotalMBFollowingDay
		--,case when TotalMBPreviousDay is null then TotalPermMB else TotalPermMB - TotalMBPreviousDay end MBIncrease
		,case when TotalMBPreviousDay is null then 0 /*TotalPermMB*/ else TotalPermMB - TotalMBPreviousDay end MBIncrease
  from prodbbymeadhocwrk.tableSizeHist
 where tablename not like 'bu%'
   and tablename <> 'All_Tables'
   and cast(RecModTS as date) > date '2009-10-01'
   and databasename = 'prodbbymeadhocwrk'
   --and tablename = 'BBYM_INV_ITEM'
order by MBIncrease DESC, RecModTS DESC
--order by RecModTS DESC, 1, MBIncrease DESC

DIAGNOSTIC STATHASHPART ON FOR SESSION;
--explain

select
		databasename
		,tablename
		,creatorName
		,RecModTS
		,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 preceding and 1 preceding) TotalMBPreviousDay
		,TotalPermMB
		,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 following and 1 following) TotalMBFollowingDay
		--,case when TotalMBPreviousDay is null then TotalPermMB else TotalPermMB - TotalMBPreviousDay end MBIncrease
		,case when TotalMBPreviousDay is null then 0 /*TotalPermMB*/ else TotalPermMB - TotalMBPreviousDay end MBIncrease
  from prodbbymeadhocwrk.tableSizeHist
 where tablename not like 'bu%'
   --and tablename <> 'All_Tables'
   --and cast(RecModTS as date) > date '2009-10-01'
   and databasename = 'prodbbymeadhocwrk'
   --and tablename = 'BBYM_INV_ITEM'
order by MBIncrease DESC, RecModTS DESC

help stats prodbbymeadhocwrk.tableSizeHist

collect stats column (tableName) on prodbbymeadhocwrk.tableSizeHist

collect stats column (databaseName) on prodbbymeadhocwrk.tableSizeHist

select
		databasename
		,tablename
		,creatorName
		,RecModTS
		--,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 preceding and 1 preceding) TotalMBPreviousDay
		,TotalPermMB
		--,sum(TotalPermMB) over (partition by databasename, tablename order by RecModTS rows between 1 following and 1 following) TotalMBFollowingDay
		--,case when TotalMBPreviousDay is null then TotalPermMB else TotalPermMB - TotalMBPreviousDay end MBIncrease
		--,case when TotalMBPreviousDay is null then 0 /*TotalPermMB*/ else TotalPermMB - TotalMBPreviousDay end MBIncrease
  from prodbbymeadhocwrk.tableSizeHist
 where tablename not like 'bu%'
   and tablename <> 'All_Tables'
   and cast(RecModTS as date) > date '2009-10-27'
   and databasename = 'prodbbymeadhocwrk'
   and TotalPermMB > 5000
   --and tablename = 'BBYM_INV_ITEM'
order by TotalPermMB DESC --MBIncrease DESC, RecModTS DESC

help stats prodbbymeadhocwrk.tableSizeHist

show table prodbbymeadhocwrk.tableSizeHist

collect stats index (databaseName ,tableName ,RecModTS) on prodbbymeadhocwrk.tableSizeHist 
;collect stats index (databaseName ,tableName) on prodbbymeadhocwrk.tableSizeHist 
;collect stats column (TotalPermMB) on prodbbymeadhocwrk.tableSizeHist 
;collect stats column (RecModTS) on prodbbymeadhocwrk.tableSizeHist 


select *
  from prodbbymeadhocwrk.tableSizeHist
 where tablename = 'BBYM_INV_ITEM'
order by RecModTS Desc

select databasename
		, tablename
		, max(lastAccessTimestamp)
		, max(TotalPermMB)
		, max(tableKind)
		, max(totalAccessCount) - min(totalAccessCount) /*over (partition by databasename, tablename)*/ AccessCountDiff
		, max(RecModTS)
		, max(creatorName)
		, max(createTimeStamp)
  from prodbbymeadhocwrk.tvmAccessHist
 where RecModTS > Timestamp '2009-07-24 00:00:00' 
   and databasename = 'prodbbymeadhocdb'
group by 1,2
 having AccessCountDiff < 10 
   and cast(max(RecModTS) as date) > date - 2

select databasename
		, tablename
		, max(lastAccessTimestamp) over (partition by 
		, max(totalAccessCount) - min(totalAccessCount) /*over (partition by databasename, tablename)*/ AccessCountDiff
  from prodbbymeadhocwrk.tvmAccessHist
 where RecModTS > Timestamp '2009-08-18 00:00:00' 


SELECT  
		databasename
		, tablename
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
  FROM dbc.TableSize 
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
   and tablename = 'FORT_ALERT_TRAN'
 group by 1,2
--having TotalPermMB > 500
order by 1,3,5,2

select *
  from prodbbymeadhocwrk.tableSizeHist
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
   and tablename = 'FORT_ALERT_TRAN'

select databasename
		, tablename
		, creatorName
		, max(TotalPermMB) - min(TotalPermMB) delta
		--, skewFactor
  from prodbbymeadhocwrk.tableSizeHist
 where tablename != 'All_Tables'
group by 1,2,3
having max(TotalPermMB) - min(TotalPermMB) > 100
order by 1,4,2

SELECT  min(currentperm) as MinPerm
		, avg(currentperm) as AvgPerm
		, max(currentperm) as MaxPerm 
		,  MaxPerm / MinPerm as MaxToMin 
  FROM dbc.TableSize 
 where databasename = 'prodbbymeadhocwrk'
and tablename = 'vert00091_Pas_bkup' ;

show table prodbbymeadhocwrk.tbend_meobjectAccess_hst

SELECT  
		databasename
		, tablename
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, min(currentperm) as MinPerm
		, avg(currentperm) as AvgPerm
		, max(currentperm) as MaxPerm 
		,  MaxPerm / MinPerm as MaxToMin 
  FROM dbc.TableSize 
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2
having maxToMin > 1000

--Use the following SQL query to determine how your data is distributed across the AMPs in your system. 

SELECT vproc
		,cast(SUM(maxperm)/(1024*1024) as decimal(16,2)) as mp
		,cast(SUM(currentperm)/(1024*1024) as decimal(16,2)) as cp
		,mp - cp as free
  FROM dbc.diskspace
 WHERE databasename = 'prodbbymeadhocdb'  --name of your offending database
group by 1 
order by 1

--Use the following SQL query to determine which tables on which VPROC are using the most space and determine if you can delete or drop the table(s).

SELECT 
	tablename
	,cast(sum(currentperm)/(1024*1024) as decimal(16,2)) PermUsedMB
FROM dbc.tablesize
WHERE databasename =  'prodbbymeadhocdb'   --name of your offending database
  AND vproc = 361 --344          --number of offending vprocs
group by 1
ORDER By 2 DESC;

SELECT  
		databasename
		, tablename
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
  FROM dbc.TableSize 
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2
having TotalPermMB > 500
order by 1,3,5,2

SELECT  
		databasename
		, tablename
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
  FROM dbc.TableSize 
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2
having SkewFactor > 10 and TotalPermMB > 50
order by 1,3,5,2

SELECT  
		databasename
		, tablename
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
  FROM dbc.TableSize 
 where databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
   and tablename = 'Naked_Basket_STG2_Temp'
 group by 1,2
--having TotalPermMB > 500
order by 1,3,5,2

SELECT  
		ts.databasename
		, ts.tablename
		, t.creatorName
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
  FROM dbc.TableSize ts 
  left outer join dbc.tables t
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2,3
having SkewFactor > 10 and TotalPermMB > 50
order by 1,4,6,2

SELECT  
		ts.databasename
		, ts.tablename
		, t.creatorName
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
  FROM dbc.TableSize ts 
  left outer join dbc.tables t
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2,3
having TotalPermMB > 500
order by 1,4,6,2

having maxToMin > 1000

SELECT  
		ts.databasename
		, ts.tablename
		, t.creatorName
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
		, t.createTimestamp
  FROM dbc.TableSize ts 
  left outer join dbc.tables t
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk', 'prodbbymeadhocvws')
   and ts.tablename not like 'bu%'
 group by 1,2,3,9
--having SkewFactor > 10 and TotalPermMB > 50
--order by 1,4,6,2
order by /*8,*/1,4 DESC,3,2

SELECT  
		t.databasename
		, t.tablename
		, coalesce(t.lastAlterName, t.creatorName) ownerName
		--, min(currentperm) as MinPerm
		--, avg(currentperm) as AvgPerm
		--, max(currentperm) as MaxPerm 
		--,  MaxPerm / MinPerm as MaxToMin 
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
		, coalesce(t.lastAlterTimeStamp, t.createTimestamp) LastAltered
  FROM dbc.tables t 
  left outer join dbc.TableSize ts
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where t.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk', 'prodbbymeadhocvws')
   and t.tablename not like 'bu%'
 group by 1,2,3,9
 having TotalAccess < 10
--having SkewFactor > 10 and TotalPermMB > 50
--order by 1,4,6,2
order by /*8,*/1,4 DESC,3,2

select 
		t.databasename
		, t.tablename
		, t.creatorName
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
		, max(lastAccessTimeStamp) lastAccessed
		, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
		, t.createTimestamp
  from dbc.tables t
  left outer join dbc.TableSize ts
  			on ts.databasename = t.databasename
			and ts.tablename = t.tablename
 where t.databasename in ('prodbbymeadhocdb','prodbbymeadhocwrk')
   and t.tablename like 'bbym%'
 group by 1,2,3,8
 order by 1,2,3

show table prodbbymeadhocwrk.TableSizeHist

show macro PRODBBYMEADHOCDB.FORT2_INSERT

show table PRODBBYMEADHOCDB.X_STEP_3_PEER_GRP_RPT_SRC

drop table PRODBBYMEADHOCDB.X_STEP_3_PEER_GRP_RPT_SRC

drop table prodbbymeadhocdb.psp_stg

show table prodbbymeadhocdb.BBY_COST_CENTERS_Err1

rename table prodbbymeadhocdb.bbym_loc_day_ts_summ_bkup to prodbbymeadhocdb.x_bbym_loc_day_ts_summ_bkup

drop table prodbbymeadhocdb.x_bbym_loc_day_ts_summ_bkup

select * from prodbbymeadhocdb.fort_job_wave_sql where lower(shellSQL) like lower('%MTRX_HOLIDAY_REVDOE_AVG_Backup%')

show table prodbbymeadhocdb.BRANDED_PAYMENT_FIN

show table PRODBBYMEADHOCDB.FORT_ALERT_TRAN_HIST          

select min(IssueTS), min(expireTS) from PRODBBYMEADHOCDB.FORT_ALERT_TRAN_HIST

show table prodbbymeadhocdb.Report_At_risk

select
        t.databasename, t.tablename, t.creatorName, l.FirstName || ' ' || l.LastName CreatorFullname
		,t.createTimeStamp, t.LastAlterTimeStamp
  from dbc.tables t
left join prodbbymeadhocdb.ldap_employee l
    on lower(t.creatorName) = lower(trim(l.mailNickName))
 where databasename = 'PRODBBYMEADHOCDB'
   and tablename = 'SHRINK_TREND_13_WEEK_LBR_DEPT' --'SHARE_LOC_SUBCLASS_TIME' --'LP_Excptn_data_stg' --'BBYM_ALL_TRANS_EMP' --'FORT_ALERT_TRAN_HIST' 

SELECT  
		ts.databasename
		, ts.tablename
		, t.creatorName
		, t.createTimeStamp
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
		, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
		, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
  FROM dbc.TableSize ts 
join dbc.tables t
	on t.databasename = ts.databasename
	and t.tablename = ts.tablename
 where ts.databasename = 'prodbbymeadhocdb'
   and (ts.tablename like 'X%' or ts.tablename like '%temp' or ts.tablename like '%backup')
 group by 1,2,3,4
order by 1,5,7,2

select *
  from prodbbymeadhocdb.fort_job_wave_sql
 where lower(shellSQL) like lower('%web_utilization%')

select *
  from prodbbymeadhocdb.fort_job
 where jobID = 5
  
show table PRODBBYMEADHOCDB.DWO_WK_SCLS

select * from dbc.tables where tablename = 'LP_Excptn_data_stg'

rename table prodbbymeadhocdb.FORTVault_Data to prodbbymeadhocdb.x_FORTVault_Data

drop table prodbbymeadhocdb.x_FORTVault_Data

show table prodbbymeadhocdb.Report_At_risk

drop table PRODBBYMEADHOCDB.fort_dat_fin_bkup

show table prodbbymeadhocdb.SHARE_LOC_SUBCLASS_TIME

show table prodbbymeadhocdb.STEP_3_PEER_GRP_RPT_SRC_DLY

drop table prodbbymeadhocdb.MTRX_HOLIDAY_REVDOE_AVG_Backup

drop table PRODBBYMEADHOCDB.branded_payment_fin_bkup

rename table prodbbymeadhocdb.SSR_LU_Trans_13Wks_wLY_Stg to prodbbymeadhocdb.x_SSR_LU_Trans_13Wks_wLY_Stg

show table prodbbymeadhocdb.x_SSR_LU_Trans_13Wks_wLY_Stg

delete prodbbymeadhocdb.x_SSR_LU_Trans_13Wks_wLY_Stg all

select count(distinct Username)
		,count(distinct ObjectTableName)
  from PRODBBYMEADHOCWRK.TBEND_MEOBJECTACCESS_HST

select jobID, waveID, sqlID, sqlName
  from prodbbymeadhocdb.fort_job_wave_sql s
 where lower(shellSQL) like '%mtrx_holiday_revdoe_avg_backup%'
   or lower(shellSQL) like '%vert42_holiday_base_fy2007_bck%'
   or lower(shellSQL) like '%bbym_loc_day_ts_summ_bkup%'
   or lower(shellSQL) like '%vert43_holiday_mtrx_fy2007_bck%'
   or lower(shellSQL) like '%step_3_peer_grp_rpt_src%'
   or lower(shellSQL) like '%fort_prj_report_prompt_value%'
   or lower(shellSQL) like '%step_3_peer_grp_rpt_src_dly%'
   or lower(shellSQL) like '%sc_dataflexservf_fl%'
   or lower(shellSQL) like '%vert124_contest_fy08_holiday_t%'
   or lower(shellSQL) like '%svc_fms_days_out%'
   or lower(shellSQL) like '%dwo_wk_scls%'
   or lower(shellSQL) like '%bby_wac_tran_hist%'
   or lower(shellSQL) like '%geek_ss_ollie%'
   or lower(shellSQL) like '%trpt_backtohomeappl_vert2%'
  
select --jobID, waveID, sqlID, sqlName
		sum(case when lower(shellSQL) like '%mtrx_holiday_revdoe_avg_backup%'   then 1 else 0 end)  c1
		,sum(case when lower(shellSQL) like '%mtrx_holiday_revdoe_avg_backup%'  then 1 else 0 end)  c2
        ,sum(case when lower(shellSQL) like '%vert42_holiday_base_fy2007_bck%'  then 1 else 0 end)  c3
        ,sum(case when lower(shellSQL) like '%bbym_loc_day_ts_summ_bkup%'       then 1 else 0 end)  c4
        ,sum(case when lower(shellSQL) like '%vert43_holiday_mtrx_fy2007_bck%'  then 1 else 0 end)  c5
        ,sum(case when lower(shellSQL) like '%step_3_peer_grp_rpt_src%'         then 1 else 0 end)  c6
        ,sum(case when lower(shellSQL) like '%fort_prj_report_prompt_value%'    then 1 else 0 end)  c7
        ,sum(case when lower(shellSQL) like '%step_3_peer_grp_rpt_src_dly%'     then 1 else 0 end)  c8
        ,sum(case when lower(shellSQL) like '%sc_dataflexservf_fl%'             then 1 else 0 end)  c9
        ,sum(case when lower(shellSQL) like '%vert124_contest_fy08_holiday_t%'  then 1 else 0 end)  c10
        ,sum(case when lower(shellSQL) like '%svc_fms_days_out%'                then 1 else 0 end)  c11
        ,sum(case when lower(shellSQL) like '%dwo_wk_scls%'                     then 1 else 0 end)  c12
        ,sum(case when lower(shellSQL) like '%bby_wac_tran_hist%'               then 1 else 0 end)  c13
        ,sum(case when lower(shellSQL) like '%geek_ss_ollie%'                   then 1 else 0 end)  c14
        ,sum(case when lower(shellSQL) like '%trpt_backtohomeappl_vert2%'       then 1 else 0 end)  c15
  from prodbbymeadhocdb.fort_job_wave_sql s
 where lower(shellSQL) like '%mtrx_holiday_revdoe_avg_backup%'
   or lower(shellSQL) like '%vert42_holiday_base_fy2007_bck%'
   or lower(shellSQL) like '%bbym_loc_day_ts_summ_bkup%'
   or lower(shellSQL) like '%vert43_holiday_mtrx_fy2007_bck%'
   or lower(shellSQL) like '%step_3_peer_grp_rpt_src%'
   or lower(shellSQL) like '%fort_prj_report_prompt_value%'
   or lower(shellSQL) like '%step_3_peer_grp_rpt_src_dly%'
   or lower(shellSQL) like '%sc_dataflexservf_fl%'
   or lower(shellSQL) like '%vert124_contest_fy08_holiday_t%'
   or lower(shellSQL) like '%svc_fms_days_out%'
   or lower(shellSQL) like '%dwo_wk_scls%'
   or lower(shellSQL) like '%bby_wac_tran_hist%'
   or lower(shellSQL) like '%geek_ss_ollie%'
   or lower(shellSQL) like '%trpt_backtohomeappl_vert2%'

select s.jobID, j.jobName, s.waveID, s.sqlID, s.shellSQL
  from prodbbymeadhocdb.fort_job_wave_sql s
 left join prodbbymeadhocdb.fort_job j
 	on s.jobID = j.jobID
 where lower(shellSQL) like '%gmr_stg2%'
 order by 1,3,4
 
SELECT  
		databasename
		, tablename
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPerm
		, min(currentperm) as MinPerm
		, avg(currentperm) as AvgPerm
		, max(currentperm) as MaxPerm 
		,  MaxPerm / MinPerm as MaxToMin 
  FROM dbc.TableSize 
 where databasename = 'prodbbymeadhocdb'
   and tablename in (
 'fort_prj_report_prompt_value'
,'step_3_peer_grp_rpt_src_dly'
,'sc_dataflexservf_fl'
,'vert124_contest_fy08_holiday_t'
,'dwo_wk_scls'
,'bby_wac_tran_hist'
,'geek_ss_ollie'
,'trpt_backtohomeappl_vert2'
)
 group by 1,2
 
select count(*) from prodbbymeadhocdb.STEP_3_PEER_GRP_RPT_SRC_DLY 

select * from dbc.tables where databasename = 'prodbbymeadhocdb' and tablename = 'STEP_3_PEER_GRP_RPT_SRC_DLY'

select --jobID, waveID, sqlID, sqlName
         sum(case when lower(shellSQL) like '%rptVert_Holiday_BU%'              then 1 else 0 end) c1
        ,sum(case when lower(shellSQL) like '%TBEND_MEOBJECTACCESS_HST%'        then 1 else 0 end) c2
        ,sum(case when lower(shellSQL) like '%BBYM_MUR_STDRD_2%'                then 1 else 0 end) c3
        ,sum(case when lower(shellSQL) like '%svc_cost_to_serve%'               then 1 else 0 end) c4
        ,sum(case when lower(shellSQL) like '%rptVertSuperBowl_WK3_BU%'         then 1 else 0 end) c5
        ,sum(case when lower(shellSQL) like '%BBFB_sls_ext%'                    then 1 else 0 end) c6
        ,sum(case when lower(shellSQL) like '%SVC_BACK%'                        then 1 else 0 end) c7
        ,sum(case when lower(shellSQL) like '%BBYM_MUR_STDRD%'                  then 1 else 0 end) c8
        ,sum(case when lower(shellSQL) like '%FORTvw_Alert_Distrib_Default%'    then 1 else 0 end) c9
        ,sum(case when lower(shellSQL) like '%tRpt_BackToHomeHT_Vert2%'         then 1 else 0 end) c10
        ,sum(case when lower(shellSQL) like '%SVC_FMS_DAYS_OUT%'                then 1 else 0 end) c11
  from prodbbymeadhocdb.fort_job_wave_sql s
 where lower(shellSQL) like '%rptVert_Holiday_BU%'
    or lower(shellSQL) like '%TBEND_MEOBJECTACCESS_HST%'
    or lower(shellSQL) like '%BBYM_MUR_STDRD_2%'
    or lower(shellSQL) like '%svc_cost_to_serve%'
    or lower(shellSQL) like '%rptVertSuperBowl_WK3_BU%'
    or lower(shellSQL) like '%BBFB_sls_ext%'
    or lower(shellSQL) like '%SVC_BACK%'
    or lower(shellSQL) like '%BBYM_MUR_STDRD%'
    or lower(shellSQL) like '%FORTvw_Alert_Distrib_Default%'
    or lower(shellSQL) like '%tRpt_BackToHomeHT_Vert2%'
    or lower(shellSQL) like '%SVC_FMS_DAYS_OUT%'

SELECT  
		databasename
		, tablename
        , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
        --, sum(currentperm) as TotalPerm
		, min(currentperm) as MinPerm
		, avg(currentperm) as AvgPerm
		, max(currentperm) as MaxPerm 
		,  MaxPerm / MinPerm as MaxToMin 
  FROM dbc.TableSize 
 where databasename = 'prodbbymeadhocwrk'
   and tablename in (
 'svc_cost_to_serve'
 ,'FORTvw_Alert_Distrib_Default'
 ,'SVC_FMS_DAYS_OUT'
)
group by 1,2

show table prodbbymeadhocdb.web_error_log

delete from prodbbymeadhocdb.web_error_log where cast(RECTS as date) < date - 30

select *  from dbc.tables where databasename = 'prodbbymeadhocwrk' and tablename = 'SVC_FMS_DAYS_OUT'

select *
  from prodbbymeadhocdb.fort_job_wave_sql
 where shellSQL like '%STEP_3_PEER_GRP_RPT_SRC%'
 
select *
  from prodbbymeadhocdb.fort_job
 where jobID in (
'3' ,'4' ,'6' ,'10' ,'45' ,'48' ,'51' ,'130' ,'138' ,'140' ,'141' ,'152' ,'213' ,'214' ,'257'
,'262' ,'300' ,'307' ,'998' ,'999' ,'1001' ,'1007' ,'1010' ,'1750' ,'2000' ,'6630' ,'10010'
,'11070' ,'11072' ,'11073' ,'12030' ,'12038' ,'12042' ,'12067' ,'12092' ,'12118' ,'12131' ,'12175'
)

select *
  from prodbbymeadhocdb.fort_job_wave_sql
 where jobID = 3

select   jobID, waveID, sqlID, sqlName
        ,case when position('MTRX_HOLIDAY_REVDOE_AVG_Backup'     in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert42_Holiday_Base_FY2007_bck'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bbym_loc_day_ts_summ_bkup'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert43_Holiday_MTRX_FY2007_bck'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('STEP_3_PEER_GRP_RPT_SRC'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('FORT_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('STEP_3_PEER_GRP_RPT_SRC_DLY'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('sc_dataflexservf_fl'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert124_Contest_FY08_Holiday_t'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('SVC_FMS_DAYS_OUT'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('DWO_WK_SCLS'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('BBY_WAC_TRAN_HIST'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('GEEK_SS_OLLIE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('tRpt_BackToHomeAppl_Vert2'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('BBYM_SAS_TRAFFIC_1104'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu1arpt_Alert_Trends'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu7arpt_Alert_Trends'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu0arpt_Alert_Trends'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu2arpt_Alert_Trends'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu4arpt_Alert_Trends'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert00091_Pas_bkup'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert00091_Pas_bkup2'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('vert42_Holiday_Base_FY2007_bck'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu6arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu3arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu2arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu7arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu4arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu0arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu5arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu1arpt_Alert_HealthUsage_GRPH'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('rptVert_Holiday_BU'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('TBEND_MEOBJECTACCESS_HST'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu0a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu1a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu2a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu3a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu4a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu5a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu6a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu7a_DIM_Employee'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('BBYM_MUR_STDRD_2'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu7a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu6a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu5a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu4a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu3a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu1a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu2a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu0a_ALERT_DISTRIBUTION'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('svc_cost_to_serve'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu0a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu1a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu2a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('rptVertSuperBowl_WK3_BU'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('BBFB_sls_ext'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('SVC_BACK'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('BBYM_MUR_STDRD'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('FORTvw_Alert_Distrib_Default'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('tRpt_BackToHomeHT_Vert2'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('SVC_FMS_DAYS_OUT'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('x_ecom_allocation_orig'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('x_ecom_allocation_order_orig'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu3a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu4a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu5a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu6a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end
        ||case when position('bu7a_PRJ_REPORT_PROMPT_VALUE'        in shellSQL) = 0 then 0 else 1 end as pos_vec
  from prodbbymeadhocdb.fort_job_wave_sql
 where lower(shellSQL) like lower('%MTRX_HOLIDAY_REVDOE_AVG_Backup%')
    or lower(shellSQL) like lower('%vert42_Holiday_Base_FY2007_bck%')
    or lower(shellSQL) like lower('%bbym_loc_day_ts_summ_bkup%')
    or lower(shellSQL) like lower('%vert43_Holiday_MTRX_FY2007_bck%')
    or lower(shellSQL) like lower('%STEP_3_PEER_GRP_RPT_SRC%')
    or lower(shellSQL) like lower('%FORT_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%STEP_3_PEER_GRP_RPT_SRC_DLY%')
    or lower(shellSQL) like lower('%sc_dataflexservf_fl%')
    or lower(shellSQL) like lower('%vert124_Contest_FY08_Holiday_t%')
    or lower(shellSQL) like lower('%SVC_FMS_DAYS_OUT%')
    or lower(shellSQL) like lower('%DWO_WK_SCLS%')
    or lower(shellSQL) like lower('%BBY_WAC_TRAN_HIST%')
    or lower(shellSQL) like lower('%GEEK_SS_OLLIE%')
    or lower(shellSQL) like lower('%tRpt_BackToHomeAppl_Vert2%')
    or lower(shellSQL) like lower('%BBYM_SAS_TRAFFIC_1104%')
    or lower(shellSQL) like lower('%bu1arpt_Alert_Trends%')
    or lower(shellSQL) like lower('%bu7arpt_Alert_Trends%')
    or lower(shellSQL) like lower('%bu0arpt_Alert_Trends%')
    or lower(shellSQL) like lower('%bu2arpt_Alert_Trends%')
    or lower(shellSQL) like lower('%bu4arpt_Alert_Trends%')
    or lower(shellSQL) like lower('%vert00091_Pas_bkup%')
    or lower(shellSQL) like lower('%vert00091_Pas_bkup2%')
    or lower(shellSQL) like lower('%vert42_Holiday_Base_FY2007_bck%')
    or lower(shellSQL) like lower('%bu6arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu3arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu2arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu7arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu4arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu0arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu5arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%bu1arpt_Alert_HealthUsage_GRPH%')
    or lower(shellSQL) like lower('%rptVert_Holiday_BU%')
    or lower(shellSQL) like lower('%TBEND_MEOBJECTACCESS_HST%')
    or lower(shellSQL) like lower('%bu0a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu1a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu2a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu3a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu4a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu5a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu6a_DIM_Employee%')
    or lower(shellSQL) like lower('%bu7a_DIM_Employee%')
    or lower(shellSQL) like lower('%BBYM_MUR_STDRD_2%')
    or lower(shellSQL) like lower('%bu7a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu6a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu5a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu4a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu3a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu1a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu2a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%bu0a_ALERT_DISTRIBUTION%')
    or lower(shellSQL) like lower('%svc_cost_to_serve%')
    or lower(shellSQL) like lower('%bu0a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu1a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu2a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%rptVertSuperBowl_WK3_BU%')
    or lower(shellSQL) like lower('%BBFB_sls_ext%')
    or lower(shellSQL) like lower('%SVC_BACK%')
    or lower(shellSQL) like lower('%BBYM_MUR_STDRD%')
    or lower(shellSQL) like lower('%FORTvw_Alert_Distrib_Default%')
    or lower(shellSQL) like lower('%tRpt_BackToHomeHT_Vert2%')
    or lower(shellSQL) like lower('%SVC_FMS_DAYS_OUT%')
    or lower(shellSQL) like lower('%x_ecom_allocation_orig%')
    or lower(shellSQL) like lower('%x_ecom_allocation_order_orig%')
    or lower(shellSQL) like lower('%bu3a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu4a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu5a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu6a_PRJ_REPORT_PROMPT_VALUE%')
    or lower(shellSQL) like lower('%bu7a_PRJ_REPORT_PROMPT_VALUE%')
	


 
select count(*) from prodbbymeadhocdb.MTRX_HOLIDAY_REVDOE_AVG_Backup

drop table prodbbymeadhocdb.MTRX_HOLIDAY_REVDOE_AVG_Bkup

Select 3,4, Rank() over (Order by TableName) as SQLID
	,'Build Backup: ' || trim(TableName) as SQLName
	,'Create Table prodbbymeadhocwrk.' || trim(BackupName) || ' as ( Select '  
 || min(case when ColOrder=1 then ColumnName else '' end) 
 || min(case when ColOrder=2 then ColumnName else '' end) 
 || min(case when ColOrder=3 then ColumnName else '' end) 
 || min(case when ColOrder=4 then ColumnName else '' end) 
 || min(case when ColOrder=5 then ColumnName else '' end) 
 || min(case when ColOrder=6 then ColumnName else '' end) 
 || min(case when ColOrder=7 then ColumnName else '' end) 
 || min(case when ColOrder=8 then ColumnName else '' end) 
 || min(case when ColOrder=9 then ColumnName else '' end) 
 || min(case when ColOrder=10 then ColumnName else '' end) 
 || min(case when ColOrder=11 then ColumnName else '' end) 
 || min(case when ColOrder=12 then ColumnName else '' end) 
 || min(case when ColOrder=13 then ColumnName else '' end) 
 || min(case when ColOrder=14 then ColumnName else '' end) 
 || min(case when ColOrder=15 then ColumnName else '' end) 
 || min(case when ColOrder=16 then ColumnName else '' end) 
 || min(case when ColOrder=17 then ColumnName else '' end) 
 || min(case when ColOrder=18 then ColumnName else '' end) 
 || min(case when ColOrder=19 then ColumnName else '' end) 
 || min(case when ColOrder=20 then ColumnName else '' end) 
 || min(case when ColOrder=21 then ColumnName else '' end) 
 || min(case when ColOrder=22 then ColumnName else '' end) 
 || min(case when ColOrder=23 then ColumnName else '' end) 
 || min(case when ColOrder=24 then ColumnName else '' end) 
 || min(case when ColOrder=25 then ColumnName else '' end) 
 || min(case when ColOrder=26 then ColumnName else '' end) 
 || min(case when ColOrder=27 then ColumnName else '' end) 
 || min(case when ColOrder=28 then ColumnName else '' end) 
 || min(case when ColOrder=29 then ColumnName else '' end) 
 || min(case when ColOrder=30 then ColumnName else '' end) 
 || min(case when ColOrder=31 then ColumnName else '' end) 
 || min(case when ColOrder=32 then ColumnName else '' end) 
 || min(case when ColOrder=33 then ColumnName else '' end) 
 || min(case when ColOrder=34 then ColumnName else '' end) 
 || min(case when ColOrder=35 then ColumnName else '' end) 
 || ',Current_Timestamp as BKUP_TS From prodbbymeadhocdb.' || trim(TableName) || ' ) With Data; ' as BuildSQL 
,'Y' as EmailOnFail
From 
(
Select t.TableName
,'bu0a' || trim(substr(t.TableName,5)) as BackupName
,Rank() Over (partition by t.TableName Order by c.ColumnID) as ColOrder
,case when ColOrder = 1 then ' ' else ',' end  || trim(c.ColumnName) as ColumnName
from dbc.Columns c, dbc.Tables t
where t.databasename=c.databasename
and t.tablename=c.tablename
and t.databasename = 'prodbbymeadhocdb'
and t.TableName like 'FORT%'
and t.TableName not like 'FORT_DAT%'
and c.TableName not like 'FORT_LOG%'
and c.databasename = 'prodbbymeadhocdb'
and c.TableName like 'FORT%'
and c.TableName not like 'FORT_DAT%'
and c.TableName not like 'FORT_LOG%'
and t.TableKind='T'
and c.IdColType is null 
) a
Group by TableName, BackupName

select *
  from prodbbymeadhocdb.fort_job_wave_sql
 where jobID = 3

select *
  from dbc.indices
 where databasename = 'prodbbymeadhocdb'
   and TableName like 'FORT%'
   and TableName not like 'FORT_DAT%'
   and TableName not like 'FORT_LOG%'
   and IndexType in ('P', 'Q')


select databasename, tablename, columnPosition, case when columnPosition = 1 then ' ' else ',' end || columnName
  from dbc.indices
 where databasename = 'prodbbymeadhocdb'
   and tablename = 'fort_bbym_job_xRef'
   and indexType in ('P' ,'Q')
order by columnPosition

select *
  from dbc.columns
 where databasename = 'prodbbymeadhocdb'
   and tablename = 'fort_bbym_job_xRef'

select *
  from dbc.columns
 where databasename = 'prodbbymeadhocdb'
   and IDColType is not null
   

select *
  from prodbbymeadhocdb.fort_job_wave_sql
 where lower(shellSQL) like lower('%AP_PO_XREF%')

select * from prodbbymeadhocdb.fort_job where jobID = 12202

select top 10 * from dbc.indices


 select distinct TImeLvl from prodbbymeadhocdb.fort_dat_fin
 
show table prodbbymeadhocdb.web_utilization

show table dbc.dbqlogTbl

select top 10 *
  from dbqlogTbl
 
 
delete from prodbbymeadhocdb.web_utilization_archive
 where cast(eventts as date) < date - 369
 
--alter table prodbbymeadhocdb.web_utilization
--	modify ProjectName compress ('Services Portal' ,'Miskeys' ,'Legacy' ,'Branded Payments Report' ,'Matrix Basket Reporting' ,'Shrink Barometer' ,'Services: RSS Geek Squad Reports' ,'End of Life' ,'Services: Labor Optimization Management Report' ,'BBYM Reporting' ,'RASC' ,'Field Services Portal' ,'Profit Solve' ,'Matrix P&L' ,'Shrink Barometer by Lbr Dept' ,'Services: Leadership Dashboard' ,'Ecom Ankowledgement Reports' ,'Daily Budgets' ,'Services: Agent Johnny Utah Reporting' ,'Hourly Reporting' ,'Reward Zone (Matrix)' ,'EOL Sendback Compliance' ,'Labor Reporting Suite' ,'Price Variance Report (FORT)' ,'Services: New PC Setup')
--	,modify ReportName compress ('Miskeys' ,'000262-matrixalerting' ,'Field Services Dashboard - Monthly (Prompted)' ,'Geek Squad PC Launch Page (Prompted)' ,'Branded Payment Report' ,'Basket Drill-Down Report (Monthly)' ,'Geek Squad MTD Summary' ,'Shrink Barometer' ,'citymark' ,'Total EOL Report' ,'LOMR -- DA' ,'RASC Report Access' ,'000186-pricevariance' ,'Shrink Barometer by Category' ,'Matrix P&L Links Page' ,'Geek Squad Install Launch Page (Prompted)' ,'Profit Solve - MTD (ME/Matrix version)' ,'Reward Zone Summary MTD' ,'.Com In-Store Pickup Report ( Location Summary )' ,'Shrink Barometer 13 Week Drill Down' ,'Best Buy Mobile  Sales Consultant Detail' ,'Services Business Review' ,'Agent Jonny Utah Reporting' ,'RZMC Payment Report' ,'Geek Squad Daily Summary')
--	,modify Category compress ('Service' ,'Market Analysis' ,'Basket' ,'Utility' ,'Unknown' ,'Miskeys' ,'Financial' ,'Other')
--	,modify REFERRER_URL compress ()
--	,modify URL_FILE compress ('fort.aspx' ,'alertdisplay.aspx' ,'webform1.aspx' ,'citymark.asp' ,'bestmarkcorp.asp' ,'index.php' ,'plquestion.aspx' ,'cachemanager.aspx' ,'docdetail.asp' ,'profitsolvemetricslocation.png' ,'source.aspx' ,'mainpage3.asp' ,'replaced.jpg' ,'newbasketannouncement.pdf' ,'new_matrix_labor_reports.pdf' ,'rascquestion.aspx' ,'webadminuser.aspx' ,'baskets_replaced.gif' ,'default.aspx' ,'bbfb retail leads performance report.pdf')


select *
from dbc.tables
where tablename like 'x%'
and LastAlterName = 'A645276'

select 'Drop Table '||trim(databasename)||'.'||trim(TableName)
		||' --'||trim(CreatorName)||':'||cast(LastAlterTimeStamp as varchar(50))
  from dbc.tables
 where tablename like 'x%'
   and LastAlterName = 'A645276'
order by LastAlterTimeStamp




-- find all tables with FK constraints

select ChildDB, ChildTable
  from dbc.All_RI_Children --dbc.RI_Child_TablesV
 where childDB in ('PRODBBYMEADHOCDB', 'PRODBBYMEADHOCWRK')
 group by 1,2
 
select *
  from prodbbymeadhocvws.rasc_table_storage
 where tablename='BBYM_EXCHG_DTL_TAB'

help stats PRODBBYRPTDB.TBENV_ALL_CHNL_MDSE_VDR_CUR  --PRODBBYMEADHOCDB.BBYM_TBEND_OF_ITEM--prodbbymeadhocwrk.BBYM_EXCHG_DTL_TAB

Select a.* 
  from PRODBBYMEADHOCVWS.BBYM_EXCHG_DTL_VW a, PRODBBYMEADHOCWRK.BBYM_DLY_ETL_DAYS DTS 
 where a.SLS_BSNS_DT = DTS.CALNDR_DT 
 
show view PRODBBYMEADHOCVWS.BBYM_EXCHG_DTL_VW 

show table PRODBBYMEADHOCWRK.BBYM_DLY_ETL_DAYS

show macro prodbbymeadhocdb.RASC_DBPerf_Detail_Inserts

Replace  Macro prodbbymeadhocdb.RASC_DBPerf_Detail_Inserts
 (fromDt(Date,Format 'yyyy-mm-dd')
 ,toDt(Date, Format 'yyyy-mm-dd')) As (
Delete From PRODBBYMEADHOCDB.RASC_DBPerf_Detail
  Where Calndr_Dt Between :fromDt And :toDt ; Insert Into PRODBBYMEADHOCDB.RASC_DBPerf_Detail
Select Cast(h.StartTime As Date) As Calndr_DT
     , Cast(Substring(Cast(h.StartTime as Varchar(30))
            From 12 For 11) As Dec(8,2) Format '99:99:99.99') As Calendr_Tm
     , Case When h.querytext Like '%* Job=%' Then 'Job'
            When h.querytext Like '%* Action=%' Then 'Action'
            When h.querytext Like '%* Alert=%' Then 'Alert'
            When h.querytext Like '%* FortRunner%' Then 'Internal'
            When h.querytext Like '%* Report=%' Then 'Report'
            Else Null 
       End As SQLType
     , Cast(Substring(h.QueryText
                      From Position('/* ' In h.QueryText) + 3 
                      For Position(' */' In h.QueryText) - Position('/* ' In h.QueryText) - 3)
            As VarChar(55)) As SQLIdText
     --, Null As Action_Id
     , Case When SQLType = 'Report'
              Then Case When Position('ReportGroup=' In SQLIDText) > 0
                          Then Substring(SQLIDText
                                         From Position('Report=' In SQLIDText) + 7
                                         For Position(',' In Substring(SQLIDText
                                                                       From Position('Report=' In SQLIDText) + 7)) - 1)
                          Else Substring(SQLIDText From Position('Report=' In SQLIDText) + 7)
                   End
              Else Null
       End (Integer) As Action_Id  -- Use Action_Id column to store Report_Id
     , Null As Alert_Id
     , Case When SQLType = 'Job' 
              Then Case When Position('Wave=' In SQLIDText) > 0
                          Then Substring(SQLIDText
                                         From Position('Job=' In SQLIDText) + 4
                                         For Position(',' In Substring(SQLIDText
                                                                       From Position('Job=' In SQLIDText) + 4)) - 1)
                          Else Substring(SQLIDText From Position('Job=' In SQLIDText) + 4)
                   End
              Else Null
       End (Integer) As Job_Id
     , Case When SQLType = 'Job' 
              Then Case When Position('Wave=' In SQLIDText) > 0
                          Then Substring(SQLIDText
                                         From Position('Wave=' In SQLIDText) + 5
                                         For Position(',' In Substring(SQLIDText
                                                                       From Position('Wave=' In SQLIDText) + 5)) - 1)
                        Else Null
                   End
              Else Null
       End (Integer) As Wave_Id
     , Case When SQLType = 'Job' And Position('Sql=' In SQLIDText) > 0
              Then Substring(SQLIDText From Position('Sql=' In SQLIDText) + 4)
            Else Null
       End (Integer) As SQL_Id
     , h.UserName
     , h.SessionId
     , h.RequestNum
     , h.AMPCPUTime
     , h.TotalIOCount
From PDCRINFO.DBQLogTbl_Hst h
Inner Join Sys_Calendar.Calendar c
 On h.LogDate = c.Calendar_Date
Where SQLType Is Not Null
  And Substring(QueryText From 1 For 100) Like '%/*%*/%' 
  and c.Calendar_Date Between :fromDt And :toDt ; );
  
show macro prodbbymeadhocdb.RASC_DBPerf_Detail_Inserts

exec prodbbymeadhocdb.rasc_dbperf_detail_Inserts (Date-3,Date-1)

 select *
   from prodbbymeadhocvws.rasc_table_storage
   
show view prodbbymeadhocvws.rasc_table_storage

Select	 Trim(FISC_WK_OF_MTH_NBR) || Trim(FISC_DAY_OF_WK_NBR)
From	PRODBBYVWS.TBEND_BU_FISC_DT
Where	CALNDR_DT = Date

show view prodbbymeadhocvws.FORTvw_ETL_Breaker

show table prodbbymeadhocdb.FORT_ETL_Breaker

select *
  from PDCRINFO.DBQLogTbl_Hst
  sample 10
  
drop table prodbbymeadhocwrk.ESC_Meta_RecCount 

create view prodbbymeadhocvws.rasc_storage_by_owner_sum as
 locking row for access
 SELECT
 t.creatorName
,ts.databasename
, cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
 FROM dbc.TableSize ts
 left outer join dbc.tables t
 on ts.databasename = t.databasename
 and ts.tablename = t.tablename
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2
 
Replace view prodbbymeadhocvws.rasc_storage_by_owner as
 locking row for access
 SELECT
 --ts.databasename
 --, ts.tablename
 t.creatorName
 , e.FirstName || ' ' || e.LastName ownerName
 , t.databasename
 , t.tablename
 , cast(sum(currentperm)/(1024*1024) as decimal(16,2)) as TotalPermMB
 --, cast(max(currentperm)/min(currentperm) as decimal(16,2)) as MaxToMin
 --, 100 - cast(AVG(CurrentPerm)/MAX(CurrentPerm)*100 as decimal(5,2)) AS SkewFactor
 --, max(lastAccessTimeStamp) lastAccessed
 --, sum(case when lastAccessTimeStamp > '2009-05-01 00:00:00' then AccessCount else 0 end) TotalAccess
 FROM dbc.TableSize ts
 left outer join dbc.tables t
 on ts.databasename = t.databasename
 and ts.tablename = t.tablename
 left outer join prodbbymeadhocvws.rasc_lu_ldap_employee e
 on t.creatorName = e.LDAP_ID
 where ts.databasename in ( 'prodbbymeadhocdb' , 'prodbbymeadhocwrk')
 group by 1,2,3,4

CREATE SET TABLE prodbbymeadhocwrk.ESC_Meta_RecCount ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      TableName varchar(30) NOT NULL,
	  CountDT   date NOT NULL default current_date,
	  Stage     integer not null,-- compress (0,1,2,3,4,5,6,7,8,9,10),
	  RecCount  bigint not null,
      RecModTS TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP(0)
)	 PRIMARY INDEX ( CountDT, Stage )
index (TableName);

--collect stats prodbbymeadhocwrk.ESC_Meta_RecCount index (TableName, CountDT)
collect stats prodbbymeadhocwrk.ESC_Meta_RecCount index (CountDT, Stage)
;collect stats prodbbymeadhocwrk.ESC_Meta_RecCount column (TableName, CountDT, Stage)
;collect stats prodbbymeadhocwrk.ESC_Meta_RecCount column (RecModTS)
;collect stats prodbbymeadhocwrk.ESC_Meta_RecCount column (Stage)
;collect stats prodbbymeadhocwrk.ESC_Meta_RecCount column (CountDT)
;collect stats prodbbymeadhocwrk.ESC_Meta_RecCount column (TableName)

show view prodbbymeadhocvws.rasc_dbperf_detail_v

SELECT TableName, CreatorName, a.TotalAccess, a.TotalPermMB, cast(a.lastAccessed as date) lastAccessDt, cast(a.CreateTimeStamp as date) createDt, date - lastAccessDt DaysSinceLastAccessed, date - createDt DaysCreated
  FROM PRODBBYMEADHOCVWS.rasc_tvmaccess_info a
 WHERE a.DatabaseName = 'prodbbymeadhocdb'
   AND TableKind = 'T'
   
SHOW TABLE PRODBBYMEADHOCDB.RASC_DBPerf_Detail

CREATE SET TABLE PRODBBYMEADHOCWRK.RASC_DBPerf_Detail ,NO FALLBACK ,
     NO BEFORE JOURNAL,
     NO AFTER JOURNAL,
     CHECKSUM = DEFAULT
     (
      Calndr_Dt DATE FORMAT 'YYYY-MM-DD' NOT NULL,
      Calndr_Tm DECIMAL(8,2) FORMAT '99:99:99.99' NOT NULL,
      SQLType CHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC COMPRESS ('Action                        ','Alert                         ','Internal                      ','Job                           '),
      SQLIdText VARCHAR(50) CHARACTER SET LATIN NOT CASESPECIFIC,
      ActionId INTEGER COMPRESS ,
      AlertId INTEGER COMPRESS ,
      JobId INTEGER COMPRESS ,
      WaveId INTEGER COMPRESS ,
      SQLId INTEGER COMPRESS ,
      UserName VARCHAR(30) CHARACTER SET LATIN NOT CASESPECIFIC,
      SessionId INTEGER NOT NULL,
      RequestNum INTEGER NOT NULL,
      Total_CPU DECIMAL(18,2) COMPRESS (0.00 ,3.00 ,1.00 ,4.00 ,2.00 ),
      Total_IO DECIMAL(18,0) COMPRESS (0. ,1. ,2. ,3. ,4. ,5. ,6. ,7. ,8. ,9. ,10. ,11. ,12. ,13. ,14. ,15. ,16. ,17. ,18. ,19. ,20. ))
UNIQUE PRIMARY INDEX UPI_RASC_DBPerf_Detail ( Calndr_Dt ,SessionId ,
RequestNum )
PARTITION BY RANGE_N(Calndr_Dt  BETWEEN DATE '2009-10-05' AND '2020-12-31' EACH INTERVAL '1' DAY ,
 NO RANGE, UNKNOWN);

insert into PRODBBYMEADHOCWRK.RASC_DBPerf_Detail 
SELECT *
  FROM PRODBBYMEADHOCDB.RASC_DBPerf_Detail
  
help STATISTICS PRODBBYMEADHOCDB.RASC_DBPerf_Detail   

COLLECT STATISTICS index (Calndr_Dt,SessionId,RequestNum) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column (Calndr_Dt) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column (SQLType) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column (ActionId) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column (JobId) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column (Calndr_Dt,UserName) on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail
;collect STATISTICS column partition on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail 

rename TABLE PRODBBYMEADHOCDB.RASC_DBPerf_Detail to PRODBBYMEADHOCDB.RASC_DBPerf_Detail_X

CREATE VIEW PRODBBYMEADHOCDB.RASC_DBPerf_Detail 
as
 locking row for access
SELECT *
  FROM PRODBBYMEADHOCWRK.RASC_DBPerf_Detail 
  
grant delete on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail to RASC_FORT_BCH with grant option

Grant DELETE  on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail to prodbbymeadhocdb WITH GRANT OPTION

Grant INSERT on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail to prodbbymeadhocdb WITH GRANT OPTION

Grant SELECT on PRODBBYMEADHOCWRK.RASC_DBPerf_Detail to prodbbymeadhocdb WITH GRANT OPTION

-- 618 Amps

SELECT x.DatabaseName, 
		CASE x.CreatorName 
				WHEN  'RASC_FORT_BCH' then 'RASC_FORT_BCH'
				WHEN 'DBAdmin' then 'DBAdmin'
				else 'Other'
				end creatorName
		,count(*)
  FROM PRODBBYMEADHOCVWS.rasc_tvmaccess_info x
GROUP BY 1,2

SELECT *
  FROM PRODBBYMEADHOCVWS.rasc_tvmaccess_info x
 WHERE x.DatabaseName = 'prodbbymeadhocdb'
   and x.TableName like 'ESC_%'
   and x.TableKind = 'T'
   --AND x.CreatorName = 'RASC_FORT_BCH'
   
SELECT cast(x.RecModTS as date), x.databaseName, sum(x.TotalPermMB)/1024
  from PRODBBYMEADHOCWRK.tableSizeHist x
 WHERE x.databaseName = 'prodbbymeadhocdb'
   and x.tableName like 'ESC_%'
  GROUP by 1
  ORDER by 1
 
SELECT *
  FROM PRODBBYMEADHOCVWS.rasc_tvmaccess_info x
 WHERE x.skewFactor > 50