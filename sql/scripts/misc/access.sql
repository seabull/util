rem Author:  Longjiang Yang
rem Name:    access.sql
rem Purpose: Show objects currently in use in the database
rem Usage:   @access <%owner.name%> <%type%> <%username%>
rem Subject: tuning
rem Attrib:  sql dba
rem Descr:
rem Notes:
rem SeeAlso: @locks
rem History:
rem          14-feb-02  Initial release

@setup1
define typ="upper('&&2')"
define usr="upper('&&3')"

column uname format a20 heading "USERNAME"
column oname format a30 heading "OBJECT_NAME"


SELECT
	s.username||','||s.sid uname
	,a.owner||'.'||a.object oname
	,a.type
FROM	v$access a, v$session s
WHERE	a.sid = s.sid
	and s.username like &&usr
	and a.owner like &&o1
	and a.object like &&n1
	and a.type like &&typ
ORDER BY s.username, a.owner, a.object, a.type;

undef usr typ

@setdefs

