rem Author:  Longjiang Yang
rem Name:    coldict.sql
rem Purpose: Determine use of common column names/types across tables
rem Usage:   @coldict <%owner.table%> <%colname%> <%coltype%>
rem Subject: object:table:column
rem Attrib:  sql
rem Descr:
rem Notes:
rem SeeAlso: @cols
rem History:
rem          01-mar-02  Initial release

@setup1
define col="upper('&&2')"
define typ="upper('&&3')"

column_name format a25
column data_type format a12 heading "TYPE"
column data_length format 9999 heading "LENGTH"
column data_precision format 99 heading "PREC"
column data_scale format 99 heading "SCALE"
column cnt format 999 heading "CNT"

select
  column_name,
  data_type,
  data_length,
  data_precision,
  data_scale,
  count(*) cnt
from &&ora._tab_columns
where owner like &&o1
and table_name like &&n1
and column_name like &&col
and data_type like &&typ
group by column_name, data_type, data_length, data_precision, data_scale
;

undef col typ

@setdefs


