rem Author:  Longjiang Yang
rem Name:    coldist.sql
rem Purpose: Calculate distribution statistics about a column
rem Usage:   @coldist <owner.table> <colexpr>
rem Subject: tuning
rem Attrib:  sql n80
rem Descr:
rem Notes:
rem SeeAlso:
rem History:
rem          10-feb-02  Initial release

@setup1

rem column avggrp new_value av
rem column stdgrp new_value sd

column totrecs format 999,999,990 heading "TOTAL|RECORDS" justify center
column totgrps format 999,990 heading "TOTAL|GROUPS" justify center
column avggrp  format 999,990 heading "AVG RECS|GROUP" justify center
column maxgrp  format 999,990 heading "MAX RECS|GROUP" justify center
column stdgrp  format 999,990 heading "STD DEV |GROUP" justify center
column minblks format 9,990 heading "MIN BL|KEY" justify center
column avgblks format 9,990 heading "AVG BL|KEY" justify center
column maxblks format 9,990 heading "MAX BL|KEY" justify center
column stdblks format 9,990 heading "STD BL|KEY" justify center


select
  sum(count(*)) totrecs,
  count(count(*)) totgrps,
  avg(count(*)) avggrp,
  max(count(*)) maxgrp,
  stddev(count(*)) stdgrp,
  min(count(distinct substr(rowid, 1, 8))) minblks,
  avg(count(distinct substr(rowid, 1, 8))) avgblks,
  max(count(distinct substr(rowid, 1, 8))) maxblks,
  stddev(count(distinct substr(rowid, 1, 8))) stdblks
from &&1
group by &&2;

set term off
/*
SET HEADING OFF
SELECT count(count(*))||' groups with over '||TO_CHAR(&&av+&&sd)||
  ' members (AVG+STDDEV)'
FROM &&1 a
WHERE &&av+&&sd < (
  SELECT count(*)
  FROM &&1
  WHERE &&2 = a.&&2
)
GROUP BY &&2;

SET HEADING ON

SELECT
  num_rows,
  blocks,
  empty_blocks,
  avg_space,
  chain_cnt,
  avg_row_len
FROM sys.dba_tables
WHERE owner = &&o1
AND table_name = &&n1
;
*/
set term on

@setdefs
