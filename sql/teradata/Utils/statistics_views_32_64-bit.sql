/** Additional info on collected statistics, including Date, Time, Rowcount...
    2003-03-12 dn initial version
    2003-07-22 dn modified to use dbc.???Stats views instead of base tables
    2004-01-20 dn added ColumnCount
    2004-11-08 dn added StatsVersion
                  fixed SampleSize for pre-V2R5 stats, now displays 100%
    2004-11-15 dn added version based on base tables to display CollectDuration,
                  modified/reformatted source code
    2007-05-22 dn added pseudo-column PARTITION (V2R6.1+)
    2007-08-09 dn modified to work for both 32-bit and 64-bit versions
    2007-10-22 dn added FORMAT for date/timestamp typecasts to prevent errors
    2007-11-02 dn implemented changes for version 3 statistics (TD12),
                  added NumAMPs (TD12), NumIntervals, AvgAmpRPV (TD12), NumAllNulls (TD12)
    2008-07-02 dn fixed bug for TD12 64-bit, thanks to Bill Gregg
    2008-07-25 dn split into two different scripts for 32-bit and 64-bit
    2009-10-01 dn fixed: 3798 in ANSI mode 
    2009-10-10 dn fixed: the column list for multi-column stats including PARTITION was invalid
    2008-10-16 dn added a version using nested views on base tables instead of Derived Tables. 
                  Only one of those views is dependant on 32- vs- 64-bit, so it's easier to maintain.
    2010-05-11 dn TD12.0.3.1/TD13.0.0.21: new stats version "4". 
                  Fixed the (stupid) old calculation of StatsVersion and added OneAMPSampleEst and AllAMPSampleEst 

    For bug reports: dnoeth@gmx.de

       Encoding changed for 64-bit version:
       8 Bytes added (byte[13..16] and [29..32]) usually, but not always '00'XB.
       To align on 8 byte boundaries?

       There's no way to check for 32/64 bit using SQL, so this must be hardcoded.
       After lots of 3610 (because of nested aliases) i decided to split the query into two versions, 32- and 64-bit.
       And i changed the bytes-extracting to become more readable using CASEs, so it will be much easier, 
       if the encoded stats will ever change again. I started on V2R4 when there was no 64-bit, yet :-) 
**/


/**
  CAUTION use the right version for your system:
  Change the view name at the end of the script from
  stats_basics_??bit to stats_basics_32bit or stats_basics_64bit 
**/

Create VIEW prodbbymeadhocvws.rasc_stats_data AS
SELECT
  d.databasename AS DatabaseName,
  t.tvmname AS TableName,
  MAX(CASE WHEN i.FieldPosition = 1
      THEN (CASE WHEN i.FieldId = 0 THEN 'PARTITION'
                 ELSE TRIM(c.FieldName)
            END)
      ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 2  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 3  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 4  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 5  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 6  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 7  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 8  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 9  THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 10 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 11 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 12 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 13 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 14 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 15 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition = 16 THEN ',' || TRIM(c.FieldName) ELSE '' END) ||
  MAX(CASE WHEN i.FieldPosition > 16 THEN ',...' ELSE '' END) AS ColumnName,
  MAX(i.LastAlterTimestamp) AS LastAlterTimestamp,
  COUNT(*) AS ColumnCount,
  CASE IndexType
    WHEN 'M' THEN 'M'
    WHEN 'D' THEN 'D'
    ELSE 'I'
  END AS StatsType,
  CAST(MAX(SUBSTR(i.IndexStatistics, 1, 128)) AS VARBYTE(128)) AS STATS
FROM dbc.Indexes i
JOIN dbc.tvm t
  ON t.TVMid = i.tableid
JOIN dbc.dbase d
  ON t.databaseid = d.databaseid
LEFT JOIN dbc.tvfields c
  ON c.tableid = i.tableid
  AND c.fieldid = i.fieldid
GROUP BY
  DatabaseName,
  TableName,
  StatsType,
  i.IndexNumber
HAVING STATS IS NOT NULL
UNION ALL
SELECT
  d.databasename AS DatabaseName,
  t.tvmname AS TableName,
  c.fieldname AS ColumnName,
  c.LastAlterTimestamp,
  1 AS ColumnCount,
  'C' AS StatsType,
  CAST(SUBSTR(c.fieldstatistics, 1, 128) AS VARBYTE(128)) AS STATS
FROM
  dbc.dbase d
JOIN dbc.tvm t
  ON d.databaseid = t.databaseid
JOIN dbc.tvfields c
  ON t.tvmid = c.tableid
WHERE STATS IS NOT NULL
;


Create VIEW prodbbymeadhocvws.rasc_stats_basics_64bit AS
/** CAUTION: use the right version for your system.
    This is the 64-bit version for Teradata on Linux and Windows.
**/
SELECT
  DatabaseName,
  TableName,
  ColumnName,
  LastAlterTimestamp,
  ColumnCount,
  StatsType,
    /** TD12 changed the HASHBUCKET function (16 bit vs. 20 bit),
        on TD12 (using 20 bits for HashBuckets) the result must be divided by 16 **/
  ((HASHBUCKET()+1)/65536) AS TD12,
  SUBSTR(STATS, 1, 4) AS CollectDate_,
  SUBSTR(STATS, 5, 4) AS CollectTime_,
  HASHBUCKET ('00'xb || SUBSTR(STATS, 9, 1) (BYTE(4))) / TD12 AS StatsVersion,
  CASE
    WHEN HASHBUCKET ('00'xb || SUBSTR(STATS, 11, 1) (BYTE(4))) / TD12 = 1
    THEN HASHBUCKET ('00'xb || SUBSTR(STATS, 12, 1) (BYTE(4))) / TD12
  END AS SampleSize,
/*** Differences between 32- and 64-bit start here ---> ***/
  SUBSTR(STATS, 13 + 4, 8) AS NumNulls_,
  SUBSTR(STATS, 21 + 4, 2) AS NumIntervals_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 25 + 8, 8)
  END AS NumAllNulls_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 33 + 8 , 8)
  END AS AvgAmpRPV_,
  CASE
    WHEN StatsVersion > 3 THEN SUBSTR(STATS, 41 + 8, 8)
  END AS OneAMPSampleEst_,
  CASE
    WHEN StatsVersion > 3 THEN SUBSTR(STATS, 49 + 8, 8)
  END AS AllAMPSampleEst_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 57 + 8, 2)
  END AS NumAMPs_,
  CASE
    WHEN SUBSTR(STATS, 23 + 4, 1)  = '01'xb THEN 16
    ELSE 32
  END AS Offset,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset, 8)
    ELSE SUBSTR(STATS, 73 + Offset, 8)
  END AS ModeFreq_,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset + 8, 8)
    ELSE SUBSTR(STATS, 73 + Offset + 8, 8)
  END AS NumValues_,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 33 + Offset + 16, 8)
    ELSE SUBSTR(STATS, 73 + Offset + 16, 8)
  END AS NumRows_
/*** Differences between 32- and 64-bit end here <--- ***/
FROM prodbbymeadhocvws.rasc_stats_data
;


Create VIEW prodbbymeadhocvws.rasc_stats_basics_32bit AS
/** CAUTION: use the right version for your system.
    This is the 32-bit version for Teradata on MP-RAS and Teradata Express
**/
SELECT
  DatabaseName,
  TableName,
  ColumnName,
  LastAlterTimestamp,
  ColumnCount,
  StatsType,
    /** TD12 changed the HASHBUCKET function (16 bit vs. 20 bit),
        on TD12 (using 20 bits for HashBuckets) the result must be divided by 16 **/
  ((HASHBUCKET()+1)/65536) AS TD12,
  SUBSTR(STATS, 1, 4) AS CollectDate_,
  SUBSTR(STATS, 5, 4) AS CollectTime_,
  HASHBUCKET ('00'xb || SUBSTR(STATS, 9, 1) (BYTE(4))) / TD12 AS StatsVersion,
  CASE
    WHEN HASHBUCKET ('00'xb || SUBSTR(STATS, 11, 1) (BYTE(4))) / TD12 = 1
    THEN HASHBUCKET ('00'xb || SUBSTR(STATS, 12, 1) (BYTE(4))) / TD12
  END AS SampleSize,
/*** Differences between 32- and 64-bit start here ---> ***/
  SUBSTR(STATS, 13, 8) AS NumNulls_,
  SUBSTR(STATS, 21, 2) AS NumIntervals_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 25, 8)
  END AS NumAllNulls_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 33, 8)
  END AS AvgAmpRPV_,
  CASE
    WHEN StatsVersion > 3 THEN SUBSTR(STATS, 41, 8)
  END AS OneAMPSampleEst_,
  CASE
    WHEN StatsVersion > 3 THEN SUBSTR(STATS, 49, 8)
  END AS AllAMPSampleEst_,
  CASE
    WHEN StatsVersion >= 3 THEN SUBSTR(STATS, 57, 2)
  END AS NumAMPs_,
  CASE
    WHEN SUBSTR(STATS, 23, 1)  = '01'xb THEN 16
    ELSE 32
  END AS Offset,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 25 + Offset, 8)
    ELSE SUBSTR(STATS, 59 + Offset, 8)
  END AS ModeFreq_,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 25 + Offset + 8, 8)
    ELSE SUBSTR(STATS, 59 + Offset + 8, 8)
  END AS NumValues_,
  CASE
    WHEN StatsVersion < 3 THEN SUBSTR(STATS, 25 + Offset + 16, 8)
    ELSE SUBSTR(STATS, 59 + Offset + 16, 8)
  END AS NumRows_
/*** Differences between 32- and 64-bit end here <--- ***/
FROM prodbbymeadhocvws.rasc_stats_data
;

Create VIEW prodbbymeadhocvws.rasc_stats_details AS
SELECT
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
    /** Time needed to collect stats
        I don't know if it's really correct, because CollectDuration is
        sometimes negative for sample stats, That's why i use ABS 
    **/
  ABS(CollectDuration) AS CollectDuration,
    /** V2R5: sample size used for collect stats, NULL if not sampled **/
  SampleSize,
    /** Version
       1: pre-V2R5
       2: V2R5
       3: TD12
       4: TD12.0.3.1/TD13.0.0.21
    **/
  StatsVersion,
    /** TD12: Number of AMPs on the system **/
  NumAMPs,
    /** Number of intervals **/
  NumIntervals,
    /** TD12: All-AMPs average of the average number of rows per NUSI value
        per individual AMP, Estimated WHEN Sampled **/
  AvgAmpRPV,
    /** TD12.0.3.1/TD13.0.0.21: Estimated cardinality based on a single-AMP sample **/
  OneAMPSampleEst,
    /** TD12.0.3.1/TD13.0.0.21: Estimated cardinality based on an all-AMP sample **/
  AllAmpSampleEst,
    /** Row Count, Estimated when Sampled **/
  NumRows (DECIMAL(18,0)),
    /** Distinct Values, Estimated when Sampled **/
  NumValues (DECIMAL(18,0)),
    /** Number of partly null and all null rows,
        Estimated when Sampled **/
  NumNulls (DECIMAL(18,0)),
    /** TD12: Number of all null rows in the column or index set,
        Estimated when Sampled **/
  NumAllNulls (DECIMAL(18,0)),
    /** Maximum number of rows / value, Estimated when Sampled **/
  ModeFreq (DECIMAL(18,0))
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
    (
     (HASHBUCKET
       (SUBSTR(CollectDate_, 2, 1) ||
        SUBSTR(CollectDate_, 1, 1) (BYTE(4))
       ) / TD12 - 1900
     ) * 10000
     +
     (HASHBUCKET
       ('00'xb || SUBSTR(CollectDate_, 3, 1) (BYTE(4))
       ) / TD12
     ) * 100
     +
     (HASHBUCKET
       (
        '00'xb || SUBSTR(CollectDate_, 4, 1) (BYTE(4))
       ) / TD12
     ) (DATE, FORMAT 'yyyy-mm-ddB')
    ) AS CollectDate,
    (
     (HASHBUCKET
       (CAST('00'xb || SUBSTR(CollectTime_, 1, 1) AS BYTE(4))
        ) / TD12 (FORMAT '99:')
      ) ||
      (HASHBUCKET
        (CAST('00'xb || SUBSTR(CollectTime_, 2, 1) AS BYTE(4))
        ) / TD12 (FORMAT '99:')
      ) ||
      (HASHBUCKET
        (CAST('00'xb || SUBSTR(CollectTime_, 3, 1) AS BYTE(4))
        ) / TD12 (FORMAT '99.')
      ) ||
      (HASHBUCKET
        (CAST('00'xb || SUBSTR(CollectTime_, 4, 1) AS BYTE(4))
        ) / TD12 (FORMAT '99')
      ) (TIME(2), FORMAT 'hh:mi:ss.s(2)')
    ) AS CollectTime,
    (CollectDate || (CollectTime (CHAR(11))))
      (TIMESTAMP(2), FORMAT 'yyyy-mm-ddBhh:mi:ss.s(2)') AS CollectTimestamp,
    CollectTimestamp-
     (
      COALESCE(
         MAX(CollectTimestamp) OVER (
               PARTITION BY DatabaseName, TableName, LastAlterTimestamp
               ORDER BY CollectTimestamp
               ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        ,LastAlterTimestamp)
     ) HOUR(4) TO SECOND(2)
    AS CollectDuration,
    HASHBUCKET(SUBSTR(NumNulls_, 8, 1)
            || SUBSTR(NumNulls_, 7, 1) (BYTE(4))) / TD12 AS NumNullsw1,
    HASHBUCKET(SUBSTR(NumNulls_, 6, 1)
            || SUBSTR(NumNulls_, 5, 1) (BYTE(4))) / TD12 AS NumNullsw2,
    HASHBUCKET(SUBSTR(NumNulls_, 4, 1)
            || SUBSTR(NumNulls_, 3, 1) (BYTE(4))) / TD12 AS NumNullsw3,
    HASHBUCKET(SUBSTR(NumNulls_, 2, 1)
            || SUBSTR(NumNulls_, 1, 1) (BYTE(4))) / TD12 AS NumNullsw4,
    CASE WHEN NumNulls_ = '00'xb THEN 0
    ELSE
      (-1**(NumNullsw1 / 32768))
      * (2**((NumNullsw1/16 MOD 2048) - 1023))
      * (1 + ((NumNullsw1 MOD 16) * 2**-4) + (NumNullsw2 * 2**-20)
           + (NumNullsw3 * 2**-36) + (NumNullsw4 * 2**-52))
    END AS NumNulls,
    HASHBUCKET(SUBSTR(NumIntervals_, 2, 1)
            || SUBSTR(NumIntervals_, 1, 1) (BYTE(4))) / TD12 AS NumIntervals,
    HASHBUCKET(SUBSTR(NumAllNulls_, 8, 1)
            || SUBSTR(NumAllNulls_, 7, 1) (BYTE(4))) / TD12 AS NumAllNullsw1,
    HASHBUCKET(SUBSTR(NumAllNulls_, 6, 1)
            || SUBSTR(NumAllNulls_, 5, 1) (BYTE(4))) / TD12 AS NumAllNullsw2,
    HASHBUCKET(SUBSTR(NumAllNulls_, 4, 1)
            || SUBSTR(NumAllNulls_, 3, 1) (BYTE(4))) / TD12 AS NumAllNullsw3,
    HASHBUCKET(SUBSTR(NumAllNulls_, 2, 1)
            || SUBSTR(NumAllNulls_, 1, 1) (BYTE(4))) / TD12 AS NumAllNullsw4,
    CASE WHEN NumAllNulls_ = '00'xb THEN 0
    ELSE
      (-1**(NumAllNullsw1 / 32768))
      * (2**((NumAllNullsw1/16 MOD 2048) - 1023))
      * (1 + ((NumAllNullsw1 MOD 16) * 2**-4) + (NumAllNullsw2 * 2**-20)
           + (NumAllNullsw3 * 2**-36) + (NumAllNullsw4 * 2**-52))
    END AS NumAllNulls,


    HASHBUCKET(SUBSTR(AvgAmpRPV_, 8, 1)
            || SUBSTR(AvgAmpRPV_, 7, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw1,
    HASHBUCKET(SUBSTR(AvgAmpRPV_, 6, 1)
            || SUBSTR(AvgAmpRPV_, 5, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw2,
    HASHBUCKET(SUBSTR(AvgAmpRPV_, 4, 1)
            || SUBSTR(AvgAmpRPV_, 3, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw3,
    HASHBUCKET(SUBSTR(AvgAmpRPV_, 2, 1)
            || SUBSTR(AvgAmpRPV_, 1, 1) (BYTE(4))) / TD12 AS AvgAmpRPVw4,
    CASE WHEN AvgAmpRPV_ = '00'xb THEN 0
    ELSE
      (-1**(AvgAmpRPVw1 / 32768))
      * (2**((AvgAmpRPVw1/16 MOD 2048) - 1023))
      * (1 + ((AvgAmpRPVw1 MOD 16) * 2**-4) + (AvgAmpRPVw2 * 2**-20)
           + (AvgAmpRPVw3 * 2**-36) + (AvgAmpRPVw4 * 2**-52))
    END AS AvgAmpRPV,
    HASHBUCKET(SUBSTR(OneAMPSampleEst_, 8, 1)
            || SUBSTR(OneAMPSampleEst_, 7, 1) (BYTE(4))) / TD12 AS OneAMPSampleEstw1,
    HASHBUCKET(SUBSTR(OneAMPSampleEst_, 6, 1)
            || SUBSTR(OneAMPSampleEst_, 5, 1) (BYTE(4))) / TD12 AS OneAMPSampleEstw2,
    HASHBUCKET(SUBSTR(OneAMPSampleEst_, 4, 1)
            || SUBSTR(OneAMPSampleEst_, 3, 1) (BYTE(4))) / TD12 AS OneAMPSampleEstw3,
    HASHBUCKET(SUBSTR(OneAMPSampleEst_, 2, 1)
            || SUBSTR(OneAMPSampleEst_, 1, 1) (BYTE(4))) / TD12 AS OneAMPSampleEstw4,
    CASE WHEN OneAMPSampleEst_ = '00'xb THEN 0
    ELSE
      (-1**(OneAMPSampleEstw1 / 32768))
      * (2**((OneAMPSampleEstw1/16 MOD 2048) - 1023))
      * (1 + ((OneAMPSampleEstw1 MOD 16) * 2**-4) + (OneAMPSampleEstw2 * 2**-20)
           + (OneAMPSampleEstw3 * 2**-36) + (OneAMPSampleEstw4 * 2**-52))
    END AS OneAMPSampleEst,
    HASHBUCKET(SUBSTR(AllAMPSampleEst_, 8, 1)
            || SUBSTR(AllAMPSampleEst_, 7, 1) (BYTE(4))) / TD12 AS AllAMPSampleEstw1,
    HASHBUCKET(SUBSTR(AllAMPSampleEst_, 6, 1)
            || SUBSTR(AllAMPSampleEst_, 5, 1) (BYTE(4))) / TD12 AS AllAMPSampleEstw2,
    HASHBUCKET(SUBSTR(AllAMPSampleEst_, 4, 1)
            || SUBSTR(AllAMPSampleEst_, 3, 1) (BYTE(4))) / TD12 AS AllAMPSampleEstw3,
    HASHBUCKET(SUBSTR(AllAMPSampleEst_, 2, 1)
            || SUBSTR(AllAMPSampleEst_, 1, 1) (BYTE(4))) / TD12 AS AllAMPSampleEstw4,
    CASE WHEN AllAMPSampleEst_ = '00'xb THEN 0
    ELSE
      (-1**(AllAMPSampleEstw1 / 32768))
      * (2**((AllAMPSampleEstw1/16 MOD 2048) - 1023))
      * (1 + ((AllAMPSampleEstw1 MOD 16) * 2**-4) + (AllAMPSampleEstw2 * 2**-20)
           + (AllAMPSampleEstw3 * 2**-36) + (AllAMPSampleEstw4 * 2**-52))
    END AS AllAMPSampleEst,
    HASHBUCKET(SUBSTR(NumAMPs_, 2, 1)
            || SUBSTR(NumAMPs_, 1, 1) (BYTE(4))) / TD12
    AS NumAMPs,
    HASHBUCKET(SUBSTR(ModeFreq_, 8, 1)
            || SUBSTR(ModeFreq_, 7, 1) (BYTE(4))) / TD12 AS ModeFreqw1,
    HASHBUCKET(SUBSTR(ModeFreq_, 6, 1)
            || SUBSTR(ModeFreq_, 5, 1) (BYTE(4))) / TD12 AS ModeFreqw2,
    HASHBUCKET(SUBSTR(ModeFreq_, 4, 1)
            || SUBSTR(ModeFreq_, 3, 1) (BYTE(4))) / TD12 AS ModeFreqw3,
    HASHBUCKET(SUBSTR(ModeFreq_, 2, 1)
            || SUBSTR(ModeFreq_, 1, 1) (BYTE(4))) / TD12 AS ModeFreqw4,
    CASE WHEN ModeFreq_ = '00'xb THEN 0
    ELSE
      (-1**(ModeFreqw1 / 32768))
      * (2**((ModeFreqw1/16 MOD 2048) - 1023))
      * (1 + ((ModeFreqw1 MOD 16) * 2**-4) + (ModeFreqw2 * 2**-20)
           + (ModeFreqw3 * 2**-36) + (ModeFreqw4 * 2**-52))
    END AS ModeFreq,
    HASHBUCKET(SUBSTR(NumValues_, 8, 1)
            || SUBSTR(NumValues_, 7, 1) (BYTE(4))) / TD12 AS NumValuesw1,
    HASHBUCKET(SUBSTR(NumValues_, 6, 1)
            || SUBSTR(NumValues_, 5, 1) (BYTE(4))) / TD12 AS NumValuesw2,
    HASHBUCKET(SUBSTR(NumValues_, 4, 1)
            || SUBSTR(NumValues_, 3, 1) (BYTE(4))) / TD12 AS NumValuesw3,
    HASHBUCKET(SUBSTR(NumValues_, 2, 1)
            || SUBSTR(NumValues_, 1, 1) (BYTE(4))) / TD12 AS NumValuesw4,
    CASE WHEN NumValues_ = '00'xb THEN 0
    ELSE
      (-1**(NumValuesw1 / 32768))
      * (2**((NumValuesw1/16 MOD 2048) - 1023))
      * (1 + ((NumValuesw1 MOD 16) * 2**-4) + (NumValuesw2 * 2**-20)
           + (NumValuesw3 * 2**-36) + (NumValuesw4 * 2**-52))
    END AS NumValues,
    HASHBUCKET(SUBSTR(NumRows_, 8, 1)
            || SUBSTR(NumRows_, 7, 1) (BYTE(4))) / TD12 AS NumRowsw1,
    HASHBUCKET(SUBSTR(NumRows_, 6, 1)
            || SUBSTR(NumRows_, 5, 1) (BYTE(4))) / TD12 AS NumRowsw2,
    HASHBUCKET(SUBSTR(NumRows_, 4, 1)
            || SUBSTR(NumRows_, 3, 1) (BYTE(4))) / TD12 AS NumRowsw3,
    HASHBUCKET(SUBSTR(NumRows_, 2, 1)
            || SUBSTR(NumRows_, 1, 1) (BYTE(4))) / TD12 AS NumRowsw4,
    CASE WHEN NumRows_ = '00'xb THEN 0
    ELSE
      (-1**(NumRowsw1 / 32768))
      * (2**((NumRowsw1/16 MOD 2048) - 1023))
      * (1 + ((NumRowsw1 MOD 16) * 2**-4) + (NumRowsw2 * 2**-20)
           + (NumRowsw3 * 2**-36) + (NumRowsw4 * 2**-52))
    END AS NumRows
/** CAUTION use the right version for your system:
    - stats_basics_32bit for Teradata on MP-RAS and Teradata Express on Windows
    - stats_basics_64bit for Teradata on Linux and Windows Server 
**/
  FROM prodbbymeadhocvws.rasc_stats_basics_64bit
 ) dt
;
