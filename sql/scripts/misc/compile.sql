rem Author:  Longjiang Yang
rem Name:    compile.sql
rem Purpose: Recompile invalid database objects
rem Usage:   @compile <%owner.name%> <%type%>
rem Subject: plsql
rem Attrib:  sql gen ddl
rem Descr:
rem Notes:
rem SeeAlso: @invalid
rem History:
rem          01-feb-02  Initial release

@setup1
set heading off

define ty="upper('&&2')"

spool /tmp/compile.lis
select
  'ALTER '||o.object_type
  ||' '||o.owner||'.'||o.object_name||' COMPILE;'
from &&ora._objects o
where o.owner like &&o1
and (user='SYS' or o.owner<>'SYS')
and o.object_name like &&n1
and o.object_type like &&ty
and o.object_type <> 'PACKAGE BODY'
and status = 'INVALID'
union all
select
  'ALTER PACKAGE '
  ||' '||o.owner||'.'||o.object_name||' COMPILE BODY;'
from &&ora._objects o
where o.owner like &&o1
and (user='SYS' or o.owner<>'SYS')
and o.object_name like &&n1
and o.object_type = 'PACKAGE BODY'
and status = 'INVALID'
and exists (
  select 0
  from &&ora._objects 
  where owner = o.owner
  and object_name = o.object_name
  and object_type = 'PACKAGE'
  and status = 'VALID'
)
;

spool off
@doit
set feedback on
@/tmp/compile.lis

undef ty

@setdefs







