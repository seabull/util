rem Author:  Longjiang Yang
rem Name:    become.sql
rem Purpose: Become another user (local database only)
rem Usage:   @become <user>
rem Subject: sql gen ddl dba
rem Attrib:
rem Descr:
rem Notes:   Only use against LOCAL database; determined by
rem          ORACLE_SID / TWO_TASK on UNIX, or LOCAL on Windows
rem          user require ALTER USER privilege
rem SeeAlso: connect.sql
rem History:
rem          08-feb-02  Initial release
rem          08-Apr-05  Make it depend on only connect.sql

set echo off
set embedded on
set feedback off
set linesize 80
set pagesize 9999
set recsep off
set verify off

set heading off
set termout off

define cr="chr(10)"
define am="chr(38)"
define qt="chr(39)"
define dqt="chr(34)"

spool .become.tmp
-- connect script turns termout back on, so turn it off.
select
  'alter user &&1 identified by &&1;'||&&cr||
  '@connect &&1/&&1'||&&cr||
  'set termout off'||&&cr||
  'alter user &&1 identified by values '||&&qt||u.password||&&qt||';'
from sys.dba_users u
where u.username = upper('&&1')
and u.username <> user
;
spool off

@.become.tmp
select '' from dual;
!\rm -f .become.tmp
set termout on
set feedback off
select 'Connected as '||USER||'.' from dual;

set feedback on
set heading on
set termout on
