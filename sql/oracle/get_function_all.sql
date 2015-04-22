set heading off
set echo off
--set termout off
set feedback off
set pagesize 50000
set linesize 112
set newpage none
--set space 0
set null ''
set wrap off

column line heading line format 9999
--column text heading content format a100

break on name skip page
connect / as sysdba

prompt Enter schema owner
--set termout off
spool func_&&owner
  select 
  -------------------------
     --line,
     text
  -------------------------
  from all_source 
 where owner=upper('&&owner') 
   and (
         type='FUNCTION'
      or type='PROCEDURE'
       )
 order by 
            owner
          , name
          , type
          , line
/
spool off
quit

 Name                            Null?    Type
 ------------------------------- -------- ----
 OWNER                                    VARCHAR2(30)
 NAME                                     VARCHAR2(30)
 TYPE                                     VARCHAR2(12)
 LINE                                     NUMBER
 TEXT                                     VARCHAR2(4000)


