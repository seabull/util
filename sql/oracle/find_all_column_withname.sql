REM Get all the tables that have the column name
spool /tmp/YgetNameY.sql
select  'alter table '||rtrim(owner)||'.'
||ltrim(table_name)
||'modify('
||column_name
||' '
||data_type 
||'('
||data_length
||')'
from dba_tab_cols
where column_name like '&&1%'
