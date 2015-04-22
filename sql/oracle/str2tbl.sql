-- $Id: str2tbl.sql,v 1.1 2005/09/08 18:21:48 yangl Exp $
--
-- Usage example:
-- 	select *
-- 	  from table (cast (str2tbl('85058') AS str2tblType)) A;
--	select * 
--	  from test where id in (
--		select * from table(str2tbl('10,20,30,40'))
--		);
--

create or replace type str2tblType as table of varchar2(80)
/
                                                                                
create or replace function str2tbl ( p_str in varchar2
				, p_delim in varchar2 default ',' ) 
	return str2tblType
	PIPELINED
as
	l_str      long default p_str || p_delim;
	l_n        number;
begin
	loop
		l_n := instr( l_str, p_delim );
		exit when (nvl(l_n,0) = 0);
		pipe row( ltrim(rtrim(substr(l_str,1,l_n-1))) );
		l_str := substr( l_str, l_n+1 );
	end loop;
	return;
end;
/
