rem Author:  Longjiang Yang 
rem Name:    setup1.sql
rem Purpose: Setup for script with 1 argument
rem Usage:   @setup1
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:   Define macros for spliting <%owner.name%> arguments
rem          Owner default to USER if not specified, even with "%"
rem          to wildcard all objects use "%.%"
rem SeeAlso:
rem History:
rem          01-feb-98  Initial release

@setup

rem extract user part and replace wild card '*' with '%'
define o1="replace(replace(decode(instr('&&1','.'),0,user,upper(substr('&&1',1,instr('&&1', '.')-1))),'*','%'),'?','_')"
define n1="replace(replace(upper(substr('&&1',instr('&&1','.')+1)),'*','%'),'?','_')"

