-# blkidxstats.sql
-# use this script to report on statistics captured from validate index command.

set echo off
set feedback off

set verify off

set linesize 132

set pagesize 25


col height              for     990     head 'Height'                   just l

col blocks              for     9990            head 'Alloc|Blocks'             just l

col name                for     a35     head 'Name'                     just l

col lf_rows             for     99990           head 'Leaf|Rows'                just l
col lf_blks             for     99990           head 'Leaf|Blocks'              just l
col lf_rows_len         for     9999990         head 'Leaf|Rows|Len'            just l
col lf_blk_len          for     99990           head 'Usable|Leaf|Block|Space'  just l
col br_rows             for     99990           head 'Branch|Rows'              just l
col br_blks             for     99990           head 'Branch|Blocks'            just l
col br_rows_len         for     99990           head 'Branch|Rows|Len'          just l
col br_blk_len          for     99990           head 'Usable|Branch|Block|Space' just l
col del_lf_rows         for     99990           head 'Deleted|Leaf|Rows'        just l
col del_lf_rows_len     for     99990           head 'Deleted|Leaf|Rows|Len'    just l
col distinct_keys       for     99990           head 'Nbr|Dist|Keys'            just l
col most_repeated_key   for     99990           head 'Most|Repeat|Key'          just l
col btree_space         for     999990          head 'B-Tree|Space|(K)'         just l
col used_space          for     999990          head 'Used|Space|(K)'           just l
col pct_used            for     990.99          head 'Pct|Used'                 just l
col rows_per_key        for     999990          head 'Rows|Per|Key'             just l
col blks_gets_per_access for    99990           head 'Const|Gets|Per|Access'   just l
col owner               for     a08             head 'Owner'                    just l

spool blkixsts.lst

select
   owner||'.'||name     name,
   lf_blks              lf_blks,
   lf_blk_len           lf_blk_len,
   br_rows              br_rows,
   br_blks              br_blks,
   br_blk_len           br_blk_len,
   del_lf_rows          del_lf_rows,
   del_lf_rows_len      del_lf_rows_len,
   most_repeated_key    most_repeated_key,
   rows_per_key         rows_per_key,
   blks_gets_per_access blks_gets_per_access,
   btree_space/1024     btree_space,
   used_space/1024      used_space,
   pct_used             pct_used
 from index_stats_check
where owner not in ('SYS','SYSTEM')
/
spool off

set verify on
set echo on
set feedback on

