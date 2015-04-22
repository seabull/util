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
rem SeeAlso:
rem History:
rem          08-feb-02  Initial release

@setup
set heading off

set termout off
spool /tmp/become.tmp
select
  'alter user &&1 identified by &&1;'||&&cr||
  'connect &&1/&&1'||&&cr||
  'alter user &&1 identified by values '||&&qt||u.password||&&qt||';'
from sys.dba_users u
where u.username = upper('&&1')
and u.username <> user
;
spool off
@/tmp/become.tmp
select '' from dual;
set termout on
select 'Connected as '||USER||'.' from dual;

@setdefs










