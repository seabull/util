--   To verify free space in tablespaces
--   Minimum amount of free space
--   document your thresholds:
--   <tablespace_name> = <amount> m
--

connect / as sysdba

set newpage none
set space 0
set feedback off
set linesize 400
--set heading off
set echo off
--set termout off
set trimspool on
set define on

spool &1

select 'To verify free space in tablespaces' from dual;
SELECT  tablespace_name, sum ( blocks ) as free_blk , trunc ( sum ( bytes ) / (1024*1024) ) as free_m
, max ( bytes ) / (1024) as big_chunk_k, count (*) as num_chunks
FROM dba_free_space
GROUP BY tablespace_name;

--
-- To check free, pct_free, and allocated space within a tablespace
--
select 'To check free, pct_free and allocated space within a tablespace' from dual;
SELECT tablespace_name, largest_free_chunk
     , nr_free_chunks, sum_alloc_blocks, sum_free_blocks
     , to_char(100*sum_free_blocks/sum_alloc_blocks, '09.99') || '%' 
       AS pct_free
FROM ( SELECT tablespace_name
            , sum(blocks) AS sum_alloc_blocks
       FROM dba_data_files
       GROUP BY tablespace_name
     )
   , ( SELECT tablespace_name AS fs_ts_name
            , max(blocks) AS largest_free_chunk
            , count(blocks) AS nr_free_chunks
            , sum(blocks) AS sum_free_blocks
               FROM dba_free_space
               GROUP BY tablespace_name )
WHERE tablespace_name = fs_ts_name;

--
-- verify rollback segment
--
select 'verify rollback segments' from dual;
select * from v$rollstat;

select * from dba_rollback_segs;

select n.name, s.optsize from v$rollname n, v$rollstat s
where n.usn=s.usn;

-- analyze_comp.sql
-- 
select 'Analyze Compute' from dual;
BEGIN
   sys.dbms_utility.analyze_schema ( 'HOSTDB','COMPUTE');
END ; 
/

-- pop_vol.sql
-- 
insert into utl_vol_facts
select table_name
     , NVL ( num_rows, 0) as num_rows
     , trunc ( last_analyzed ) as meas_dt
from all_tables           -- or just user_tables
where owner in ('HOSTDB','COSTING','COSTING@CS.CMU.EDU') -- or a comma-separated list of owners
/
commit
/

select 'utl_vol_facts populated' from dual;
select * from utl_vol_facts where meas_dt > sysdate - 1;

-- verify IO weighting
select 'verify IO weighting' from dual;
select substr(df.name, 1, 5) Drive, df.name file_name, fs.phyblkrd+fs.phyblkwrt total_io, 100*(fs.phyblkrd+fs.phyblkwrt)/maxio weight
from v$filestat fs, v$datafile df,
(select max(phyblkrd+phyblkwrt) maxio from v$filestat)
where df.file#=fs.file#
order by drive, weight desc;

spool off
quit;
