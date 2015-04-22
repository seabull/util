--
-- This query takes a quick look at the type of compression applied to each table, 
-- pointing to opportunities for further compression. 
-- It looks at table 10GB in size or greater...adjust to your site's needs
--
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
;

