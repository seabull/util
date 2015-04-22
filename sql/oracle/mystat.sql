--
-- $Author: yangl $
-- $Date: 2006/11/16 20:57:02 $
-- $RCSFile$
-- $Revision: 1.1 $
--

-- usage eg:
--      @mystat "redo size"
--      <some SQL statements>
--      @mystat2 "redo size"
set echo off
set verify off
column value new_val V
define S="&1"

set autotrace off
select
        a.name
        ,b.value
  from v$statname a
        , v$mystat b
 where a.statistic# = b.statistic#
   and lower(a.name) like '%' || lower('&S') || '%'
/

set echo on
