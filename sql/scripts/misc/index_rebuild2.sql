-- validate_idx.sql
-- by Brian Peasland
-- Database Administrator
-- Raytheon / EROS Data Center
-- 3 February 2000
--
-- This script will check indexes to find candidates for rebuilding.
-- Run this script in SQL*Plus as a user with SELECT ANY TABLE
-- privileges.
--
-- This script can be used and modified without permission. Run this
-- script at your own risk! The script author is not responsible for
-- any problems that may arise from running this script.

set serveroutput on size 100000

DECLARE
  vOwner   dba_indexes.owner%TYPE;            /* Index Owner            */
  vIdxName dba_indexes.index_name%TYPE;       /* Index Name             */
  vAnalyze VARCHAR2(100);                     /* String of Analyze Stmt */
  vCursor  NUMBER;                            /* DBMS_SQL cursor        */
  vNumRows INTEGER;                           /* DBMS_SQL return rows   */
  vHeight  index_stats.height%TYPE;           /* Height of index tree   */
  vLfRows  index_stats.lf_rows%TYPE;          /* Index Leaf Rows        */
  vDLfRows index_stats.del_lf_rows%TYPE;      /* Deleted Leaf Rows      */
  vDLfPerc   NUMBER;                          /* Del lf Percentage      */
  vMaxHeight NUMBER;                          /* Max tree height        */
  vMaxDel    NUMBER;                          /* Max del lf percentage  */
  CURSOR cGetIdx IS SELECT owner,index_name
     FROM dba_indexes WHERE OWNER NOT LIKE 'SYS%';
BEGIN
  /* Define maximums. This section can be customized. */
  vMaxHeight := 3;
  vMaxDel    := 20;

  /* For every index, validate structure */
  OPEN cGetIdx;
  LOOP
     FETCH cGetIdx INTO vOwner,vIdxName;
     EXIT WHEN cGetIdx%NOTFOUND;
     /* Open DBMS_SQL cursor */
     vCursor := DBMS_SQL.OPEN_CURSOR;
     /* Set up dynamic string to validate structure */
     vAnalyze := 'ANALYZE INDEX ' || vOwner || '.' || vIdxName || ' VALIDATE STRUCTURE';
     DBMS_SQL.PARSE(vCursor,vAnalyze,DBMS_SQL.V7);
     vNumRows := DBMS_SQL.EXECUTE(vCursor);
     /* Close DBMS_SQL cursor */
     DBMS_SQL.CLOSE_CURSOR(vCursor);
     /* Does index need rebuilding?  */
     /* If so, then generate command */
     SELECT height,lf_rows,del_lf_rows INTO vHeight,vLfRows,vDLfRows
        FROM INDEX_STATS; 
     IF vDLfRows = 0 THEN         /* handle case where div by zero */
        vDLfPerc := 0;
     ELSE
        vDLfPerc := (vDLfRows / vLfRows) * 100;
     END IF;
     IF (vHeight > vMaxHeight) OR (vDLfPerc > vMaxDel) THEN 
        DBMS_OUTPUT.PUT_LINE('ALTER INDEX ' || vOwner || '.' || vIdxName || ' REBUILD;');
     END IF;

  END LOOP;
  CLOSE cGetIdx;
END;
/


