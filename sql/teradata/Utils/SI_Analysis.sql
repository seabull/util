SELECT pti.DatabaseName,
       pti.TableName,
       pds.CURRENT_PERM,
       SUM(CASE WHEN pti.IndexType NOT IN ('P','Q','K')
            THEN 1 ELSE 0 END) SEC_INDEX_CNT
FROM DBC.INDICES pti,
     (SELECT databasename,
             tablename,
             SUM(CurrentPerm)/(1024*1024) CURRENT_PERM_In_MB
       FROM DBC.tablesize
       GROUP BY 1,2
     ) pds
WHERE pti.DATABASENAME IN ('prodbbymeadhocdb','prodbbymeadhocwrk')
  AND pti.DATABASENAME = pds.DATABASENAME
  AND pti.TABLENAME = pds.TABLENAME
  AND pti.columnposition = 1
HAVING SEC_INDEX_CNT = 0
   AND CURRENT_PERM > 1000000000 --10000000000
GROUP BY 1,2,3
ORDER BY 1,3 DESC, 2,4
;

