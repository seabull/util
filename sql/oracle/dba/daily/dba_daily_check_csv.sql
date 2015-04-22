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
set heading off
set echo off
set termout off
set trimspool on
set define on

spool &1

select ','||',' from dual;
select 'To verify free space in tablespaces' from dual;
select 'tablespace_name'
       ||','||'free_blk'
       ||','||'free_m'
       ||','||'big_chunk_k'
       ||','||'num_chunks'
from dual;
SELECT  tablespace_name
        ||','||sum ( blocks ) 
        ||','||trunc ( sum ( bytes ) / (1024*1024) ) 
        ||','||max ( bytes ) / (1024) 
        ||','||count (*)
FROM dba_free_space
GROUP BY tablespace_name;

--
-- To check free, pct_free, and allocated space within a tablespace
--
select ','||',' from dual;
select 'To check free, pct_free and allocated space within a tablespace' from dual;
select 'tablespace_name'
       ||','||'largest_free_chunk'
       ||','||'nr_free_chunks'
       ||','||'sum_alloc_blocks'
       ||','||'sum_free_blocks'
       ||','||'pct_free'
from dual;
SELECT tablespace_name
       ||','||largest_free_chunk
       ||','||nr_free_chunks
       ||','||sum_alloc_blocks
       ||','||sum_free_blocks
       ||','||to_char(100*sum_free_blocks/sum_alloc_blocks, '09.99') || '%' 
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
select ','||',' from dual;
select 'verify rollback segments' from dual;
select 
'USN'                               
||','||'LATCH'     
||','||'EXTENTS'   
||','||'RSSIZE'    
||','||'WRITES'    
||','||'XACTS'    
||','||'GETS'      
||','||'WAITS'     
||','||'OPTSIZE'   
||','||'HWMSIZE'   
||','||'SHRINKS'   
||','||'WRAPS'     
||','||'EXTENDS'   
||','||'AVESHRINK' 
||','||'AVEACTIVE' 
||','||'STATUS'    
||','||'CUREXT'    
||','||'CURBLK'  
from dual;
select USN                               
||','||LATCH     
||','||EXTENTS   
||','||RSSIZE    
||','||WRITES    
||','||XACTS    
||','||GETS      
||','||WAITS     
||','||OPTSIZE   
||','||HWMSIZE   
||','||SHRINKS   
||','||WRAPS     
||','||EXTENDS   
||','||AVESHRINK 
||','||AVEACTIVE 
||','||STATUS    
||','||CUREXT    
||','||CURBLK  
from v$rollstat;

select ','||',' from dual;
select 
'SEGMENT_NAME'    
||','||'OWNER'           
||','||'TABLESPACE_NAME' 
||','||'SEGMENT_ID'      
||','||'FILE_ID'         
||','||'BLOCK_ID'        
||','||'INITIAL_EXTENT'  
||','||'NEXT_EXTENT'     
||','||'MIN_EXTENTS'     
||','||'MAX_EXTENTS'     
||','||'PCT_INCREASE'    
||','||'STATUS'          
||','||'INSTANCE_NUM'    
||','||'RELATIVE_FNO'
from dual;
select  
SEGMENT_NAME    
||','||OWNER           
||','||TABLESPACE_NAME 
||','||SEGMENT_ID      
||','||FILE_ID         
||','||BLOCK_ID        
||','||INITIAL_EXTENT  
||','||NEXT_EXTENT     
||','||MIN_EXTENTS     
||','||MAX_EXTENTS     
||','||PCT_INCREASE    
||','||STATUS          
||','||INSTANCE_NUM    
||','||RELATIVE_FNO
from dba_rollback_segs;

select ','||',' from dual;
select 'Name'
       ||','||'optsize'
from dual;

select n.name
       ||','||s.optsize 
from v$rollname n, v$rollstat s
where n.usn=s.usn;

-- analyze_comp.sql
-- 
--/* This takes some time
select 'Analyze compute' from dual;
BEGIN
   sys.dbms_utility.analyze_schema ( 'HOSTDB','COMPUTE');
END ; 
/
select 'Analyze compute Done' from dual;
--*/

-- pop_vol.sql
-- 
--/*
insert into utl_vol_facts
select table_name
     , NVL ( num_rows, 0) as num_rows
     , trunc ( last_analyzed ) as meas_dt
from all_tables           -- or just user_tables
where owner in ('HOSTDB','COSTING','COSTING@CS.CMU.EDU') -- or a comma-separated list of owners
/
commit
/
--*/

select ','||',' from dual;
select 'utl_vol_facts populated' from dual;
select 
'TABLE_NAME'
||','||'NUM_ROWS'
||','||'MEAS_DT'    
from dual;

select 
TABLE_NAME
||','||NUM_ROWS
||','||MEAS_DT    
from utl_vol_facts where meas_dt > sysdate - 1;

-- verify IO weighting
select ','||',' from dual;
select 'verify IO weighting' from dual;
select 
'Drive'
||','||'File_name'
||','||'Total_IO'    
||','||'Weight'    
from dual;
select Drive
       ||','||file_name 
       ||','||total_io 
       ||','||weight
from
(
select substr(df.name, 1, 5) Drive, RTRIM(df.name) file_name, fs.phyblkrd+fs.phyblkwrt total_io, 100*(fs.phyblkrd+fs.phyblkwrt)/maxio weight
from v$filestat fs, v$datafile df,
(select max(phyblkrd+phyblkwrt) maxio from v$filestat)
where df.file#=fs.file#
order by Drive, Weight
)
select substr(df.name, 1, 5)
       ||','||RTRIM(df.name) 
       ||','||TO_CHAR(fs.phyblkrd+fs.phyblkwrt)
       ||','||100*(fs.phyblkrd+fs.phyblkwrt)/maxio 
from v$filestat fs, v$datafile df,
(select max(phyblkrd+phyblkwrt) maxio from v$filestat)
where df.file#=fs.file#
order by df.name;

spool off
quit;

