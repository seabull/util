rem Author:  Longjiang Yang
rem Name:    colstat.sql
rem Purpose: List columns
rem Usage:   @colstat <%owner.table%> <%column_name%> <%type%>
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

column tname format a25 heading "TABLE"
column column_name format a23 heading "COLUMN"
column num_distinct format 999,990 heading "DIST"
column density format 0.999 heading "DENS"
column num_nulls format 999,990 heading "NULLS"
column num_buckets format 990 heading "BUCK" 

select
c.owner||'.'||c.table_name tname
,c.column_name
,num_distinct
,density
,num_nulls		-- 7.3
,num_buckets	-- 7.3
from &&ora._tab_columns c
where c.owner like &&o1
and c.table_name like &&n1
and c.column_name like &&col
and c.data_type like &&typ
order by c.column_name, c.owner, c.table_name;

undef col typ

@setdefs

