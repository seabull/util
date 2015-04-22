rem Author:  Longjiang Yang
rem Name:    clustat.sql
rem Purpose: List cluster statistics
rem Usage:   @clustat <%owner.cluster%> <%tablespace%>
rem Subject: object:cluster
rem Attrib:  sql
rem Descr:
rem Notes:   Theses columns in SYS.DBA_TABLES are calculated by ANALYZE
rem SeeAlso: @clus
rem History:
rem          01-mar-02  Initial release

@setup1
define ts="upper('&&2')"

column cname format a25 heading "CLUSTER_NAME"
column tablespace_name format a15 heading "TABLESPACE"
column avg_blocks_per_key format 9990 heading "AVG_BLK_KEY"

select
  owner||'.'||cluster_name cname,
  tablespace_name,  
  avg_blocks_per_key
from &&ora._clusters
where owner like &&o1
and cluster_name like &&n1
and tablespace_name like &&ts
order by owner, cluster_name
;

undef ts

@setdefs
