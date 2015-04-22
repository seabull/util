rem Author:  Longjiang Yang
rem Name:    cols.sql
rem Purpose: List columns
rem Usage:   @cols <%owner.table%> <%column_name%> <%type%>
rem Subject: object:table:column
rem Attrib:  sql
rem Descr:
rem Notes:
rem SeeAlso: @coldefs @colstat
rem History:
rem          01-feb-02  Initial release

@setup1
define col="upper('&&2')"
define typ="upper('&&3')"

column tname       format a27 heading "TABLE NAME"
column column_id   format 999 heading "COL#"
column column_name format a23 heading "COLUMN NAME"
column dtype   	   format a14 heading "DATATYPE"
column nulls       format a3  heading "NUL"
column default_length format 90 heading "DEF"

select
  c.owner||'.'||c.table_name tname
, c.column_id
, c.column_name
, c.data_type||decode(c.data_length, 0, '', '('||c.data_length||
    decode(c.data_precision, null, '', ','||c.data_precision)||')') dtype
, decode(nullable, 'Y', 'YES', 'NO ') nulls
, default_length
from &&ora._tab_columns c
where c.owner like &&o1
and c.table_name like &&n1
and c.column_name like &&col
and c.data_type like &&typ
order by c.column_name,c.owner,c.table_name
;

undef col typ

@setdefs

