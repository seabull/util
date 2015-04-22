-# valixs.sql
-# use this script to capture index statistics from the validate index command.
-# comment out truncate command if you wish to keep a history of index statistics.

-- truncate table index_stats_check;

set pagesize 0
set verify off
set echo off
set heading off
set linesize 100

spool valyixs.lst

select 'validate index '||owner||'.'||index_name||';',
    'insert intoindex_stats_check (select a.*,'''||owner||''',
    sysdate from index_stats a);'
 from dba_indexes
 where owner not in ('SYS','SYSTEM')
/
spool off

set echo on
set verify on
set heading on


