--set heading off
set echo off
--set termout off
set feedback off
set pagesize 50000
set linesize 112
set newpage none
--set space 0
set null ''
set wrap off

column constraint_name heading cons_name format a20
column constraint_type heading type format a4
column table_name heading table format a20
column r_owner heading r_owner format a10
column r_constraint_name heading r_cons_name format a20
column def heading deferrable format a12
column deferred heading deferred format a10
--column last_change heading last_chg format 'MM-DD-YYYY'
column last_change heading last_chg format a10
connect / as sysdba

prompt report file name and owner of constraint, owner should be in capital
spool &&rpt
  select 
  -------------------------
     constraint_name
    ,constraint_type
    ,table_name
    , substr(deferrable, 1, 10) def
    , deferred
    ,r_owner
    ,r_constraint_name
    , to_char(last_change, 'MM-DD-YYYY') last_change 
  -------------------------
  from dba_constraints 
 where owner='&&owner' 
   and status='ENABLED'
 order by table_name
          , constraint_type
/
spool off
quit

 Name                            Null?    Type
 ------------------------------- -------- ----
 OWNER                           NOT NULL VARCHAR2(30)
 CONSTRAINT_NAME                 NOT NULL VARCHAR2(30)
 CONSTRAINT_TYPE                          VARCHAR2(1)
 TABLE_NAME                      NOT NULL VARCHAR2(30)
 SEARCH_CONDITION                         LONG
 R_OWNER                                  VARCHAR2(30)
 R_CONSTRAINT_NAME                        VARCHAR2(30)
 DELETE_RULE                              VARCHAR2(9)
 STATUS                                   VARCHAR2(8)
 DEFERRABLE                               VARCHAR2(14)
 DEFERRED                                 VARCHAR2(9)
 VALIDATED                                VARCHAR2(13)
 GENERATED                                VARCHAR2(14)
 BAD                                      VARCHAR2(3)
 LAST_CHANGE                              DATE
