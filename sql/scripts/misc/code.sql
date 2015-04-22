rem Author:  LOngjiang Yang
rem Name:    code.sql
rem Purpose: Display stored object information
rem Usage:   @code <%owner.name%> <%type%>
rem Subject: plsql
rem Attrib:  sql dba
rem Descr:
rem Notes:
rem SeeAlso: @list
rem History:
rem          01-mar-02  Initial release

@setup1
define typ="upper('&&2')"

column oname format a30 heading "OBJECT NAME"
column type format a12 heading "TYPE"
column source format 999,990 heading "SOURCE"
column parsed format 999,990 heading "PARSED"
column code format 999,990 heading "CODE"
column error format 999,990 heading "ERROR"

select
  s.owner||'.'||s.name oname,
  s.type,
  s.source_size source,
  s.parsed_size parsed,
  s.code_size code,
  s.error_size error
from sys.dba_object_size s
where s.owner like &&o1
and s.name like &&n1
and type like &&typ
order by s.owner, s.name, s.type
;

undef typ

@setdefs
