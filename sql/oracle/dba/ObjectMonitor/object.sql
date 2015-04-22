set pagesize 5000
set linesize 80
set heading off
set echo off
set newpage 0
set termout off
set show off

connect / as sysdba

column owner heading owner format a10
column object_name heading obj_name format a28
--column subobject_name heading subobj format a8
column object_type heading type format a12

column constraint_name heading cons_name format a16
column table_name heading table format a20
column deferrable heading deferrable format a8
column deferred heading deferred format a8

--spool obj_changed.lst
spool &&1
select '*****Objects changed since '
||to_char(sysdate-7)
||'*****'
from dual
/
set heading on
select 
owner
,o.object_name
--,o.subobject_name
,o.OBJECT_TYPE 
,to_char(o.last_ddl_time,'MON-DD-YY-HH24:MI') last_updated
,to_char(o.created,'MM-DD-YY') created
from dba_objects o
where 
o.owner not like 'SYS%'
and 
o.last_ddl_time > sysdate-7
and o.status='VALID'
order by 
o.last_ddl_time
,o.owner
/

set heading off
select '*****Constraints changed since '
||to_char(sysdate-7)
||'*****'
from dual
/
set heading on
select
owner
,constraint_name
,table_name
,deferrable
,deferred
,to_char(last_change,'MM-DD-YYYY-HH24:MI') last_updated
from dba_constraints
where 
owner not like 'SYS%'
and last_change > sysdate-7
order by 
last_change
,owner
/
spool off
quit

