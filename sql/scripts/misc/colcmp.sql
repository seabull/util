rem Author:  Longjiang Yang
rem Name:    colcmp.sql
rem Purpose: Compares columns in two tables
rem Usage:   @colcmp <owner.table1> <owner.table2>
rem Subject: object:table:column
rem Attrib:  sql
rem Descr:
rem Notes:
rem SeeAlso: @cols @miscols
rem History:
rem          05-mar-02  Initial release

@setup2

column table1 format a25
column table2 format a25
column text format a27 wrap

select
  c1.column_name table1, c2.column_name table2,
  decode(c2.data_type,
    null, 'not found in 2',
    c1.data_type, c1.data_type||
      decode(c1.data_type,
        'VARCHAR2', decode(c1.data_length,c2.data_length,'',
                   ' '||to_char(c1.data_length)||'/'||to_char(c2.data_length)),
        'CHAR', decode(c1.data_length,c2.data_length,'',
                   ' '||to_char(c1.data_length)||'/'||to_char(c2.data_length)),
        ''
      ),
    c1.data_type||'/'||c2.data_type
  ) text
from &&ora._tab_columns c1, &&ora._tab_columns c2
where c1.owner = &&o1 and c1.table_name = &&n1
and c2.owner(+) = &&o2 and c2.table_name(+) = &&n2
and c1.column_name = c2.column_name(+)
union all
select null, c2.column_name,'not found in 1'
from &&ora._tab_columns c2
where owner = &&o2 and table_name = &&n2
and not exists (
  select 0
  from &&ora._tab_columns
  where owner = &&o1 and table_name = &&n1
  and column_name = c2.column_name
)
order by 1,2
;

@setdefs


