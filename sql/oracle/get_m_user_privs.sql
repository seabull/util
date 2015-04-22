rem ################################################################
rem This script shows all table and system privileges granted to a user.
rem The script also takes into acount those privileges assigned
rem via roles granted via roles
rem ################################################################

set echo off
set verify off
set pages 200
set pagesize 5000
set linesize 120

col grantee form a20 trun
col granted_role form a20
col owner form a12 trun
col table_name form a27
col privilege form a27

connect / as sysdba
ACCEPT username  prompt 'Enter Username : '

spool privs.lst
PROMPT Roles granted to user
SELECT grantee, granted_role,admin_option,default_role
  FROM dba_role_privs
 WHERE grantee like UPPER('&username')
 ORDER BY
       grantee
      ,granted_role;

PROMPT Table Privileges granted to a user through roles

SELECT roles.grantee, granted_role, owner, table_name, privilege
  FROM ( SELECT grantee, granted_role
           FROM dba_role_privs 
          WHERE grantee like UPPER('&username')
       UNION
         SELECT role, granted_role
           FROM role_role_privs
          WHERE role in (SELECT granted_role
                            FROM dba_role_privs 
                           WHERE grantee like UPPER('&username')
                         )
        ) roles, dba_tab_privs dtp
 WHERE granted_role=dtp.grantee
ORDER BY
       grantee
      ,granted_role
      ,owner
      ,table_name
      ,privilege;

PROMPT System Privileges assigned to a user through roles
SELECT roles.grantee, granted_role, privilege
  FROM ( SELECT grantee, granted_role
           FROM dba_role_privs 
          WHERE grantee like UPPER('&username')
       UNION
         SELECT role, granted_role
           FROM role_role_privs
          WHERE role in ( SELECT granted_role
                            FROM dba_role_privs 
                           WHERE grantee like UPPER('&username')
                        )
        ) roles, dba_sys_privs dsp
 WHERE granted_role=dsp.grantee
ORDER BY
       grantee
      ,granted_role
      ,privilege
;

PROMPT Table privileges assigned directly to a user
SELECT grantee, owner, table_name, privilege
  FROM dba_tab_privs
 WHERE grantee like UPPER('&username')
ORDER BY
       grantee
      ,owner
      ,table_name
      ,privilege;

PROMPT System privileges assigned directly to a user
SELECT grantee, privilege, admin_option
  FROM  dba_sys_privs
 WHERE grantee like UPPER('&username')
ORDER BY
       grantee
      ,privilege;

spool off

quit
