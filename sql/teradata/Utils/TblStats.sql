-- vim: sw=4 ts=4 et ft=sql: 

--
-- The DBC.Indexes table contains a row for each column that is an index.
-- indexType
--      P (Nonpartitioned Primary)
--      Q (Partitioned Primary)
--      S (Secondary)
--      J (join index)
--      N (hash index)
--      K (primary key)
--      U (unique constraint)
--      V (value ordered secondary)
--      H (hash ordered ALL covering secondary)
--      O (valued ordered ALL covering secondary)
--      I (ordering column of a composite secondary index)
--      M (Multi-column statistics)     note:
--      D (Derived column partition statistics)
--      1 (field1 column of a join or hash index)
--      2 (field2 column of a join or hash index)
--
--
-- The DBC.TVFields table Contains one row for each occurrence of the following objects in the system:
--      * Column of a table, view, join index, and hash index.
--      * Parameter for a macro, stored procedure, user-defined type, user-defined method, userdefined function, and external stored procedure.
--
-- The DBC.TVM table contains one row for each table, view, trigger, stored procedure, join
--      index, hash index, macro, user-defined type, user-defined method, user-defined function,
--      external stored procedure, and JAR in the system.
-- 

-- DBC views related to indexes
--
-- View dbc.IndexStats provides information on statistics collected on multicolumn indexes, namely those
--      indexes for which two or more columns have been defined. When statistics are collected on
--      such indexes, the statistics are saved in DBC.Indexes, which is the underlying base table on
--      which the IndexStats view is defined. For information regarding statistics collected on single
--      column indexes, see “ColumnStats[V]”
--
-- View dbc.ColumnStats provides information on statistics collected on an individual column (other than a
--      system-derived column PARTITION). This includes individual non-indexed columns as well
--      as columns for which a single-column index has been defined. It is important to note that
--      when statistics are collected on a single-column index using the INDEX keyword in the
--      COLLECT STATISTICS syntax, the statistics are saved in DBC.TVFields, which is the
--      underlying base table on which the ColumnStats view is defined
-- 
-- View dbc.MultiColumnStats provides partition statistical (single-column or multicolumn
--      partition) information for groups of non-indexed columns. This view also includes
--      information about tables where partition statistics have been collected
-- 
--
-- The dbc.Indices view provides information about each indexed column from the DBC.Indexes table.
-- 

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


REPLACE VIEW DBC.ColumnStats
AS  SELECT  DBC.DBASE.DatabaseNameI (NAMED DatabaseName),
          DBC.TVM.TVMNameI(NAMED TableName),
          DBC.TVFields.FieldName(NAMED ColumnName),
          DBC.TVFields.FieldType(NAMED ColumnType),
          DBC.TVFields.MaxLength(NAMED ColumnLength, FORMAT 'Z,ZZZ,ZZZ,ZZ9'),
          DBC.TVFields.FieldFormat(NAMED ColumnFormat),
          DBC.TVFields.TotalDigits(NAMED DecimalTotalDigits, FORMAT 'Z9'),
          DBC.TVFields.ImpliedPoint(NAMED DecimalFractionalDigits, FORMAT 'Z9'),
          DBC.TVFields.FieldStatistics,
          DBC.TVFields.FieldID(NAMED SeqNumber)

FROM     DBC.TVFields,
         DBC.Dbase,
         DBC.TVM

WHERE    DBC.TVM.DatabaseId = DBC.DBASE.DatabaseId
AND      DBC.TVM.TVMid = DBC.TVFields.TableId with check option;


REPLACE VIEW DBC.MultiColumnStats AS
SELECT DBC.DBase.DatabaseNameI(NAMED DatabaseName),
       DBC.TVM.TVMNameI(NAMED TableName),
       DBC.Indexes.IndexNumber(NAMED StatisticsId),
       DBC.Indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9'),
       (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldName else Cast('PARTITION' as char(9))
 end)(NAMED ColumnName),
       (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldType else Cast('I' as char(1)) end)(NA
MED ColumnType),
       (case when DBC.indexes.fieldid > 0 then DBC.TVFields.MaxLength else 2 end)(NAMED ColumnLength, F
ORMAT 'Z,ZZZ,ZZZ,ZZ9 '),
       (case when DBC.indexes.fieldid > 0 then DBC.TVFields.FieldFormat else cast('ZZZZ9' as char(5)) e
nd) (NAMED ColumnFormat),
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



REPLACE VIEW DBC.Indices
AS SELECT dbase.DatabaseName,
          tvm.TVMName(NAMED TableName),
          indexes.IndexNumber(FORMAT 'ZZ9'),
          indexes.IndexType,
          indexes.UniqueFlag,
          indexes.Name (NAMED IndexName),
          tvfields.FieldName(NAMED ColumnName),
          indexes.FieldPosition(NAMED ColumnPosition,FORMAT 'Z9'),
          DB1.DatabaseName (named CreatorName),
          indexes.CreateTimeStamp,
          DB2.DatabaseName (named LastAlterName),
          indexes.LastAlterTimeStamp,
          indexes.IndexMode,
          indexes.AccessCount,
          indexes.LastAccessTimeStamp
FROM DBC.indexes
         LEFT OUTER JOIN DBC.Dbase DB1
                      ON DBC.indexes.CreateUID = DB1.DatabaseID
         LEFT OUTER JOIN DBC.Dbase DB2
                      ON DBC.indexes.LastAlterUID = DB2.DatabaseID,
     DBC.dbase, DBC.tvm, DBC.tvfields
WHERE   tvm.DatabaseId = dbase.DatabaseId
AND     tvm.tvmid = indexes.tableid
AND     tvm.tvmid = tvfields.tableid
AND     indexes.IndexType NOT IN ('M','D')
AND     tvfields.fieldid = indexes.fieldid WITH CHECK OPTION;

--------------------------------------------------------
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
                on lower(T.creatorName) = lower(trim(l.mailNickName))
WHERE  T.DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
  AND T.TABLEKIND ='T'
  AND COALESCE(S.COUNT_ZERO_STATS, 999) > 0
ORDER BY 1,2


select
  from prodbbymeadhocdb.fort_job_wave_sql sql
join (select trim(t.databasename)||'.'||trim(t.tablename) as tblname
            ,t.creatorName
            ,t.createTimestamp
        from dbc.tables t
    left outer join (   select databasename, tablename
                			    , sum(CASE WHEN ZEROSTATS='Y'  THEN 1 ELSE 0 END) AS COUNT_ZERO_STATS
                		  FROM  prodbbymeadhocvws.rasc_tbl_stats_info
                		 WHERE databasename in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
                		GROUP BY 1,2
                    ) S
                    ON t.DATABASENAME = S.DATABASENAME
                    AND t.TABLENAME = S.TABLENAME
    left outer join prodbbymeadhocdb.ldap_employee l
                    on lower(T.creatorName) = lower(trim(l.mailNickName))
    WHERE  T.DATABASENAME in ( 'PRODBBYMEADHOCDB','PRODBBYMEADHOCVWS','PRODBBYMEADHOCWRK')
      AND T.TABLEKIND ='T'
      AND COALESCE(S.COUNT_ZERO_STATS, 999) > 0
    ) x


--
--  generate Collect Stats script on indexes w/o stats
--
SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) 
        || Case When    indextype = 'M' Then ' column (' 
                Else    ' index (' 
            End     
        || indexcols || ');' 
FROM    ( 
        SELECT  databasename , tablename , indexnumber , indextype
                ,      MAXIMUM ( CASE WHEN    columnposition = 1 THEN TRIM ( columnname ) END ) 
                    || MAXIMUM ( CASE WHEN    columnposition = 2 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 3 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 4 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 5 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 6 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 7 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 8 THEN ',' || TRIM ( columnname ) ELSE '' END )
                AS indexcols 
        FROM    (
                SELECT  c.databasenamei AS databasename 
                        , b.tvmnamei AS tablename 
                        , d.indexnumber AS indexnumber 
                        , d.indextype AS indextype 
                        , d.fieldposition AS columnposition 
                        , a.fieldname AS columnname 
                FROM    dbc.tvfields a 
                        , dbc.tvm b 
                        , dbc.dbase c 
                        , dbc.indexes d 
                WHERE   a.tableid = b.tvmid 
                  AND   b.databaseid = c.databaseid 
                  AND   d.fieldid = a.fieldid 
                  AND   d.tableid = b.tvmid 
                  AND   d.databaseid = c.databaseid 
                  AND   ( d.databaseid , d.tableid , d.indexnumber )  IN 
                        (
                            SELECT  databaseid , tableid , indexnumber 
                            FROM    dbc.indexes 
                            WHERE   fieldposition = 1 
                              AND     indexstatistics IS NULL 
                              --AND     indexstatistics IS NOT NULL 
                        ) 
                  AND   databasename = 'prodbbymeadhocdb' 
                ) a 
        GROUP   BY 1 , 2 , 3, 4 
    ) b 

--
-- Revised by LJ
--
-- indexType
--      P (Nonpartitioned Primary)
--      Q (Partitioned Primary)
--      S (Secondary)
--      J (join index)
--      N (hash index)
--      K (primary key)
--      U (unique constraint)
--      V (value ordered secondary)
--      H (hash ordered ALL covering secondary)
--      O (valued ordered ALL covering secondary)
--      I (ordering column of a composite secondary index)
--      M (Multi-column statistics)
--      D (Derived column partition statistics)
--      1 (field1 column of a join or hash index)
--      2 (field2 column of a join or hash index)
--
SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) 
        || Case When    indextype = 'M' Then ' column (' 
                Else    ' index (' 
            End     
        || indexcols || ');' 
(
select
        databasename , tablename , indexnumber , indextype, indexcols
        --,offset, Stats
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
FROM    ( 
        SELECT  databasename , tablename , indexnumber , indextype
                ,offset, Stats
                ,      MAXIMUM ( CASE WHEN    columnposition = 1 THEN TRIM ( columnname ) END ) 
                    || MAXIMUM ( CASE WHEN    columnposition = 2 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 3 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 4 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 5 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 6 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 7 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 8 THEN ',' || TRIM ( columnname ) ELSE '' END )
                AS indexcols 
        FROM    (
                    SELECT  databasename 
                            , tablename 
                            , indexnumber 
                            , indextype 
                            , columnposition 
                            , columnname 
                            , IndexStatistics
                            , MAX(CASE WHEN SUBSTR(IndexStatistics, 27, 1) = '00'XB
                                       THEN 16
                                       ELSE 0
                                    END) AS Offset
                            , MAX( SUBSTR(IndexStatistics, 1, 128) ) AS Stats
                    from (
                            SELECT  c.databasenamei AS databasename 
                                    , b.tvmnamei AS tablename 
                                    , d.indexnumber AS indexnumber 
                                    , d.indextype AS indextype 
                                    , d.fieldposition AS columnposition 
                                    , a.fieldname AS columnname 
                                    , coalesce(indexStatistics, fieldStatistics) IndexStatistics
                            FROM    dbc.tvfields a 
                                    , dbc.tvm b 
                                    , dbc.dbase c 
                                    , dbc.indexes d 
                            WHERE   a.tableid = b.tvmid 
                              AND   b.databaseid = c.databaseid 
                              AND   d.fieldid = a.fieldid 
                              AND   d.tableid = b.tvmid 
                              AND   d.databaseid = c.databaseid 
                              AND   ( d.databaseid , d.tableid , d.indexnumber )  IN 
                                    (
                                        SELECT  databaseid , tableid , indexnumber 
                                        FROM    dbc.indexes 
                                        WHERE   fieldposition = 1 
                                          --AND     indexstatistics IS NULL 
                                          --AND     indexstatistics IS NOT NULL 
                                    ) 
                              AND   databasename in ( 'prodbbymeadhocdb','prodbbymeadhocvws','prodbbymeadhocwrk' )
                              and   tvmnamei not like 'XX%'
                        ) i
                group by 1,2,3,4,5,6,7
                ) a 
        GROUP   BY 1 , 2 , 3, 4 ,5,6,7
    ) b 
)
 where Collect_date > date - 14

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

--
-- ReCreate Collect Stats script
--
SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) 
        || Case When    indextype = 'M' Then ' column (' 
                Else    ' index (' 
            End     
        || indexcols || ');' 
FROM    ( 
        SELECT  databasename , tablename , indexnumber , indextype
                ,      MAXIMUM ( CASE WHEN    columnposition = 1 THEN TRIM ( columnname ) END ) 
                    || MAXIMUM ( CASE WHEN    columnposition = 2 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 3 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 4 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 5 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 6 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 7 THEN ',' || TRIM ( columnname ) ELSE '' END )
                    || MAXIMUM ( CASE WHEN    columnposition = 8 THEN ',' || TRIM ( columnname ) ELSE '' END )
                AS indexcols 
        FROM    (
                SELECT  c.databasenamei AS databasename 
                        , b.tvmnamei AS tablename 
                        , d.indexnumber AS indexnumber 
                        , d.indextype AS indextype 
                        , d.fieldposition AS columnposition 
                        , a.fieldname AS columnname 
                FROM    dbc.tvfields a 
                        , dbc.tvm b 
                        , dbc.dbase c 
                        , dbc.indexes d 
                WHERE   a.tableid = b.tvmid 
                  AND   b.databaseid = c.databaseid 
                  AND   d.fieldid = a.fieldid 
                  AND   d.tableid = b.tvmid 
                  AND   d.databaseid = c.databaseid 
                  AND   ( d.databaseid , d.tableid , d.indexnumber )  IN 
                        (
                            -- only 1st field in a multiColumn Index/stats
                            SELECT  databaseid , tableid , indexnumber 
                            FROM    dbc.indexes 
                            WHERE   fieldposition = 1 
                              --AND     indexstatistics IS NULL 
                              --AND     indexstatistics IS NOT NULL 
                        ) 
                  AND   databasename = 'prodbbymeadhocdb' 
                ) a 
        GROUP   BY 1 , 2 , 3, 4 
    ) b 

UNION 

SELECT  'collect statistics on ' || TRIM ( databasename ) || '.' || TRIM ( tablename ) || ' column (' || indexcols || ');'
  FROM    ( 
        SELECT  databasename , tablename , TRIM ( columnname ) AS indexcols 
        FROM    ( 
                SELECT  c.databasenamei AS databasename , b.tvmnamei AS tablename , a.fieldname AS columnname 
                FROM    dbc.tvfields a 
                        , dbc.tvm b 
                        , dbc.dbase c 
                WHERE   a.tableid = b.tvmid 
                  AND   b.databaseid = c.databaseid 
                  AND   a.fieldstatistics IS NOT NULL 
                  AND   databasename = 'prodbbymeadhocdb' 
                 ) a 
        GROUP   BY 1 , 2 , 3 
        ) b ; 



select
        i.indexType
        ,i.indexstatistics
        ,d.databasenamei    databasename
        ,t.tvmnamei         tablename
        ,f.fieldname        columnname
  from dbc.indexes  i
        ,dbc.tvm    t
        ,dbc.tvfields f
        ,dbc.dbase  d
 where t.databaseid = d.databaseid
   and i.databaseid = d.databaseid
   and i.tableid    = t.tvmid
   and f.tableid    = t.tvmid
   and f.databaseid = d.databaseid
   and f.fieldid    = i.fieldid
   and d.databasenamei = 'prodbbymeadhocdb'
   and i.indexstatistics is not null
group by 1, 2, 3, 4, 5


select *
  from dbc.tables
 where tableKind = 'T'
    and trim(databasename) in ('prodbbymeadhocdb','prodbbymeadhocvws','prodbbymeadhocwrk')
 --   and (trim(tableName) like  ('%_ERR1' or trim(tablename) like '%_ERR2')
    and trim(tableName) like ANY ('%Z_ERR1',  '%Z_ERR2') ESCAPE 'Z'
--    and cast(createTimestamp as date) < date - 7
order by createTimestamp Desc

