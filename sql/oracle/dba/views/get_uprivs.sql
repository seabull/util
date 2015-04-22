set verify off  
set head off  
set feedback off  
set pages 20  
undef naam  
accept naam char prompt 'Enter username to show SYSTEM privileges of: '  
  
set termout off  
drop table testpriv;  
-- DBA_ROLE_PRIV indicates which role is granted to which user  
create table testpriv  
(grantee,granted_role,ptype)  
as  
select grantee,granted_role,'R'  
from sys.dba_role_privs;  
  
-- DBA_SYS_PRIV indicates which privilege is granted to which user  
--              directly (without using roles).  
insert into testpriv  
select distinct grantee,   
       decode(grantee, 'DBA', 'DBA-role (+- 80 privs)',  
                       'IMP_FULL_DATABASE','Role of 35 privs',  
                       'EXP_FULL_DATABASE','Role of 2 privs',  
                        privilege),   
       'P'  
from sys.dba_sys_privs  
--where grantee != 'DBA'  
;  
  
set termout on  
  
-- testpriv now contains:  
--  (user, role)  
--  (role, privs)  
--  (user, privs)  
-- So display it in a connect by format:  
col title format a30 heading "System privileges" trunc  
prompt SYSTEM PRIVILEGES  
break on title  
  
select lpad(grantee,length(grantee)+level*3) title,   
       decode (ptype,'R',null,'P',granted_role)  
from testpriv  
connect by grantee = prior granted_role  
start with grantee = upper('&naam')  
/  

-- END TFSSYPRV.SQL 

SET ECHO off 
REM NAME:  TFSOBPRV.SQL 
REM USAGE:"@path/tfsobprv" 
REM -------------------------------------------------------------------------- 
REM REQUIREMENTS: 
REM    SELECT ANY TABLE 
REM -------------------------------------------------------------------------- 
REM AUTHOR:  
REM    Geert De Paep       
REM -------------------------------------------------------------------------- 
REM PURPOSE: 
REM   Will report what OBJECT privileges are related to a certain user  
REM    (for GRANTOR as well as GRANTEE)  
REM --------------------------------------------------------------------------- 
REM EXAMPLE: 
REM    Enter user to evaluate:  sys 
REM 
REM    Table privileges GIVEN: 
REM    ====================== 
REM    SELECT     ON SYS.ACCESSIBLE_TABLES  TO PUBLIC               +GRANT OPT  
REM    SELECT     ON SYS.ALL_ARGUMENTS      TO PUBLIC               +GRANT OPT 
REM    SELECT     ON SYS.ALL_CATALOG        TO PUBLIC               +GRANT OPT  
REM    SELECT     ON SYS.ALL_CLUSTERS       TO PUBLIC               +GRANT OPT 
REM    SELECT     ON SYS.ALL_CLUSTER_HASH_E TO PUBLIC               +GRANT OPT 
REM    SELECT     ON SYS.ALL_COL_COMMENTS   TO PUBLIC               +GRANT OPT  
REM    SELECT     ON SYS.ALL_COL_GRANTS_MAD TO PUBLIC   
REM                                
REM    Table privileges RECEIVED: 
REM    ========================== 
REM    SELECT     ON SYSTEM.DEF$_CALL       FROM SYSTEM            +GRANT OPT 
REM    SELECT     ON SYSTEM.DEF$_ERROR      FROM SYSTEM            +GRANT OPT  
REM    SELECT     ON SYSTEM.DEF$_DESTINATIO FROM SYSTEM            +GRANT OPT 
REM    SELECTON   SYSTEM.DEF$_CALLDEST      FROM SYSTEM            +GRANT OPT 
REM    SELECT     ON SYSTEM.REPCAT$_REPSCHE FROM SYSTEM            +GRANT OPT  
REM 
REM    Column privileges GIVEN: 
REM    ======================== 
REM 
REM    Column privileges RECEIVED: 
REM    =========================== 
REM  
REM --------------------------------------------------------------------------- 
REM DISCLAIMER: 
REM This script is provided for educational purposes only. It is NOT  
REM supported by Oracle World Wide Technical Support. 
REM The script has been tested and appears to work as intended. 
REM You should always run new scripts on a test instance initially. 
REM -------------------------------------------------------------------------- 
REM Main text of script follows: 
 
set head off  
set verify off  
set feed off  
set pause off  
col pr format a10  
col tn format a22  
col tn2 format a30  
col gr format a20  
accept person char prompt 'Enter user to evaluate:  '  
ho clear  
  
prompt      Table privileges GIVEN:  
prompt      ======================  
select  privilege pr,  
        'ON',   
        owner||'.'||table_name tn,  
        'TO',  
     grantee gr,  
        decode(grantable,'YES','+GRANT OPT')  
from sys.dba_tab_privs  
where owner = upper('&person');  
  
prompt  
prompt      Table privileges RECEIVED:  
prompt      ==========================  
select  privilege pr,  
  'ON',   
        owner||'.'||table_name tn,  
        'FROM',  
        grantor gr,  
        decode(grantable,'YES','+GRANT OPT')  
from sys.dba_tab_privs  
where grantee = upper('&person');  
  
prompt  
prompt  
prompt      Column privileges GIVEN:  
prompt      ========================  
select  privilege pr,  
        'ON',   
        owner||'.'||table_name||'('||column_name||')' tn2,  
        '-->',  
      grantee gr,  
        decode(grantable,'YES','+GRANT OPT')  
from sys.dba_col_privs  
where owner = upper('&person');  
  
prompt  
prompt      Column privileges RECEIVED:  
prompt      ===========================  
select  privilege pr,  
     'ON',   
        owner||'.'||table_name||'('||column_name||')' tn2,  
 'FROM',  
        grantor gr,  
        decode(grantable,'YES','+GRANT OPT')  
from sys.dba_col_privs  
where grantee = upper('&person');  
  
set head on  
set verify on  
set feed on  
