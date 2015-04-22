-- $Header: c:\\Repository/sql/oracle/plsql/utils/stats_pkg.sql,v 1.2 2006/02/06 22:08:46 yangl Exp $

-- Usage:
-- 	stats_pkg.inc('procedure_name');
--
--	exec stats_pkg.show(true);
create or replace package utility.stats_pkg
as
	procedure reset;
	procedure inc( p_name in varchar2, p_amt in number default 1 );
	procedure show( p_reset in boolean default false )  ;
end;
/
show errors

create or replace package body utility.stats_pkg
as
	procedure reset
	is
	begin
		for x in ( select attribute
		             from session_context
		            where namespace = 'STATS_CTX' )
		loop
			dbms_session.set_context( 'stats_ctx', x.attribute, 0 );
		end loop;
	end;
	
	
	procedure inc( p_name in varchar2, p_amt in number default 1 )
	is
	begin
		dbms_session.set_context( 'stats_ctx', p_name, 
			nvl(sys_context('stats_ctx',p_name),0)+p_amt );  
	end;  
	
	procedure show( p_reset in boolean default false )  
	is  
	begin
		for x in ( select attribute, value
		             from session_context
		            where namespace = 'STATS_CTX'
		            order by attribute )
		loop
			dbms_output.put_line( rpad( x.attribute, 32 ) || x.value );
			if ( p_reset )
			then
				dbms_session.set_context( 'stats_ctx', x.attribute, 0);
			end if;
		end loop;
	end;

end;
/

