set heading off
set feedback off
select 
	'grant '
	||privilege
	||' on '||owner||'.'||table_name
	||' to '||grantee
	||';'
  from dba_tab_privs 
 where table_name='EMP' 
   and owner='HOSTDB';
set heading on
set feedback on
