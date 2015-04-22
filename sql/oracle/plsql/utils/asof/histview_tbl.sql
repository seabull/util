-- $Header: c:\\Repository/sql/oracle/plsql/utils/asof/histview_tbl.sql,v 1.2 2006/03/02 21:24:46 yangl Exp $

create global temporary table histview_param
(
	id      number          primary key
	,flag   char(1)         default 'h' not null
	,ts     timestamp       not null
) on commit preserve rows
/

grant select, insert, delete, update on histview_param to public
/

--create trigger 
