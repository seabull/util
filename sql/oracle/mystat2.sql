--
-- $Author: yangl $
-- $Date: 2006/11/16 20:57:02 $
-- $RCSFile$
-- $Revision: 1.1 $
--

-- usage eg:
--      @mystat "redo size"
--      <some SQL statements>
--      @mystat2 
set echo off
set verify off

select
        a.name
        ,b.value V
        ,to_char(b.value-&V, '999,999,999,999') diff
  from v$statname a
        , v$mystat b
 where a.statistic# = b.statistic#
   and lower(a.name) like '%' || lower('&S') || '%'
/

set echo on
