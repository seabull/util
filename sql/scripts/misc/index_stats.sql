
column A heading "Index Name"   format a30
column B heading "Rows"         format 999,999,990
column C heading "Deleted|Rows" format 999,999,990
column D heading "% Del"        format 990.0

SELECT name A,
       lf_rows B,
       del_lf_rows C,
       (del_lf_rows  * 100 ) / lf_rows D
FROM index_stats;

