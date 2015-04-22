rem Author:  
rem Name:    hostdbcols.sql
rem Purpose: List columns
rem Usage:   @hostdbcols
rem Subject: object:table:column
rem Attrib:  sql
rem Descr:
rem Notes:
rem SeeAlso: @coldefs @colstat
rem History:
rem          01-feb-98  Initial release

rem -- @setup1
set echo off
set embedded on
set feedback off
set heading on
set linesize 60
rem -- set pagesize 9999
set pagesize 40
set recsep off
set verify off

rem define sqllib="lang_util"

define cr="chr(10)"
define am="chr(38)"
define qt="chr(39)"

column tname noprint new_value tblvar
column owner noprint new_value ownervar
break on tname skip page on owner
ttitle RIGHT 'OWNER: ' ownervar LEFT 'TABLE:  ' tblvar SKIP 2

btitle CENTER '************************************************************'

rem column tname       format a27 heading "TABLE NAME"
rem -- column column_id   format 999 heading "COL#"
column column_name format a23 heading "COLUMN NAME"
column dtype   	   format a14 heading "DATATYPE"
column nulls       format a3  heading "NUL"
column default_length format 90 heading "DEF"

column data_default format a13 heading "DEFAULT"

select
  c.owner
, c.table_name tname
, c.column_name
, c.data_type||decode(c.data_length, 0, '', '('||c.data_length||
    decode(c.data_precision, null, '', ','||c.data_precision)||')') dtype
, decode(nullable, 'Y', 'YES', 'NO ') nulls
, default_length
, data_default
from dba_tab_columns c
where c.owner like 'HOSTDB'
order by c.table_name
;
rem order by c.table_name, c.column_name

undef col typ
set linesize 84
set pagesize 50000

ttitle off
btitle off

clear breaks
clear computes
clear columns

set embedded off
set feedback on
set heading on
set recsep wrap
set space 1
set verify on

set termout on
set echo off
