rem Author:  Longjiang Yang
rem Name:    analyze.sql
rem Purpose: Perform variable ANALYZE TABLE operations
rem Usage:   @analyze <%owner.table%> <%type%> <operation>
rem Subject: object
rem Attrib:  sql gen ddl
rem Descr:
rem Notes:   d=delete statistics
rem          e[til]=estiate statistics
rem            [t|i|l=for table|for all indexes|for all indexed columns]
rem          c[til]=compute statistics
rem          vs=validate structure
rem          vc=validate structure cascade
rem          lc=list chained rows
rem          For example:
rem          e=estimate
rem          et=estimate for table
rem SeeAlso: @estimate
rem History:
rem          14-feb-02  Initial release

@setup1
set heading off
define ty="upper('&&2')"
define pa="upper('&&3')"
define ft="decode(o.object_type,'TABLE','for table')"
define fi="decode(o.object_type,'TABLE','for all indexes')"
define fc="decode(o.object_type,'TABLE','for all indexed columns')"

spool analyze.tmp

select
  'analyze '||o.object_type||' '||o.owner||'.'||o.object_name||&&cr||
  decode(&&pa
  , 'D' , 'delete statistics'
  , 'E' , 'estimate statistics'
  , 'ET', 'estimate statistics '||&&ft
  , 'EI', 'estimate statistics '||&&fi
  , 'EC', 'estimate statistics '||&&fc
  , 'C' , 'compute statistics'
  , 'CT', 'compute statistics '||&&ft
  , 'CI', 'compute statistics '||&&fi
  , 'CC', 'compute statistics '||&&fc
  , 'VS', 'validate structure'
  , 'VC', 'validate structure cascade'
  , 'LC', 'list chained rows'
  )||';'
from &&ora._objects o
where o.owner not in ('SYS','SYSTEM')
and o.owner like &&o1
and o.object_name like &&n1
and o.object_type like &&ty
and o.object_type in ('TABLE','INDEX','CLUSTER')
order by o.owner, o.object_name
;

spool off
@sure
set feedback on
@analyze.tmp

undef ty pa ft fi fc

@setdefs



