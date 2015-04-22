rem 
rem  Generate DDL to drop phantom synonyms in your database 
rem  Excludes SYS and SYSTEM users 
rem 

spool alias_rmGENERATED.sql
set pages 0 feed off
select 'drop '||decode(owner,'PUBLIC',' public ',null)||
       'synonym '||
       decode(owner,'PUBLIC',null,owner||'.')||
       synonym_name||';'
from dba_synonyms s
where owner not in('SYSTEM','SYS')
      and 
      table_owner not in ('SYSTEM','SYS','CTXSYS' ,'MDSYS' ,'ODM' ,'OLAPSYS' ,'ORDSYS' ,'WKSYS' ,'XDB') 
      and
      db_link is null
      and
      not exists(select 1 from all_objects o
                    where object_type
                    in('TABLE','VIEW','SYNONYM',
                    'SEQUENCE','PROCEDURE',
                    'PACKAGE','FUNCTION')
      and
      s.table_owner=o.owner
      and
      s.table_name=o.object_name);
spool off
PROMPT ***************************************************************
PROMPT * You can execute alias_rmGENERATED.sql to drop the synonyms. *
PROMPT ***************************************************************
