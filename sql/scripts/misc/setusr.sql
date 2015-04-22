rem -----------------------------------------------------------------------------
rem Author:  Longjiang Yang, 2001
rem Name:    setusr.sql
rem Purpose: Setup environment to run scripts and DBA or non-DBA
rem Usage:   @setusr
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:
rem SeeAlso:
rem          12-Dec-01  Initial Draft
rem -----------------------------------------------------------------------------


define dba="sys.dba"
define dbms="sys.dbms"
define ora="all"
define oru="user"
define segown="user"
define indown="user"
define prvown="table_schema"
define prvgrt="username"

set termout off

column a1 new_value ora
column a2 new_value oru
column a3 new_value segown
column a4 new_value indown
column a5 new_value prvown
column a6 new_value prvgrt

rem check to see whether current user have DBA priv
select
  'sys.dba' a1
, 'sys.dba' a2
, 's.owner' a3
, 'i.owner' a4
, 'p.owner' a5
, 'p.grantee' a6
from session_roles s
where role='DBA'
;

column a1 clear
column a2 clear
column a3 clear
column a4 clear
column a5 clear

set termout on

