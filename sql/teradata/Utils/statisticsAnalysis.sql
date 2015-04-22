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
       SUM(COALESCE(NumOfValues,0)) VALUES_SUM
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

