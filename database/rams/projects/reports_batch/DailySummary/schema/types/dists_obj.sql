-- $Id: dists_obj.sql,v 1.1 2006/08/08 14:43:08 yangl Exp $

create or replace type distacct_type as object
	authid current_user
(
	acct_id		number(6)
	,acct_string	varchar2(24)
	,acct_type	varchar2(2)
	,pct		number(6,3)
	,member function toString return varchar2
	,map member function mapping_function return varchar2
)
/

create or replace type body distacct_type
as
	member function toString return varchar2
	is
	begin
		return rtrim(acct_string) || '@' || pct ;
	end;

	map member function mapping_function return varchar2
	is
	begin
		return acct_type || toString;
	end;
end;
/

create or replace type distacct_array_type as varray(30) of distacct_type;

create or replace type Distribution
	as object
(
	dist		number(6)
	,accounts_lst	distacct_array_type
	,member function toString return varchar2
	,map member function mapping_function return varchar2
)
/

create or replace type body Distribution
as
	member function toString return varchar2
	is
	begin
		for 
	    if ( street_addr2 is not NULL )
	    then
	        return street_addr1 || chr(10) ||
	               street_addr2 || chr(10) ||
	               city || ', ' || state || ' ' || zip_code;
	    else
	        return street_addr1 || chr(10) ||
	               city || ', ' || state || ' ' || zip_code;
	    end if;
	end;
	
	map member function mapping_function return varchar2
	is
	begin
	    return to_char( nvl(zip_code,0), 'fm00000' ) ||
	           lpad( nvl(city,' '), 30 ) ||
	           lpad( nvl(street_addr1,' '), 25 ) ||
	           lpad( nvl(street_addr2,' '), 25 );
	end;
end;
/


--create table people
--( name           varchar2(10),
--  home_address   address_type,
--  work_address   address_type
--)
--/
--
--declare
--    l_home_address address_type;
--    l_work_address address_type;
--begin
--    l_home_address := Address_Type( '123 Main Street', null,
--                                    'Reston', 'CA', 45678 );
--    l_work_address := Address_Type( '1 Oracle Way', null,
--                                    'Redwood', 'VA', 23456 );
--  
--    insert into people
--    ( name, home_address, work_address )
--    values
--    ( 'Tom Kyte', l_home_address, l_work_address );
--end;
--/
