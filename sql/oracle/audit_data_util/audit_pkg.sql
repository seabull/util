-- $Id: audit_pkg.sql,v 1.3 2005/05/09 15:06:00 yangl Exp $
--
create or replace package audit_pkg
as
	procedure check_val(	
				l_who in varchar2
				, l_ops in number
				,l_owner	in varchar2
				,l_tname in varchar2
				,l_cname in varchar2
				,l_new in varchar2
				,l_old in varchar2 
				,l_how in number default 0
			);
 
	procedure check_val(	
				l_who in varchar2
				, l_ops in number
				, l_owner	in varchar2
				, l_tname in varchar2
				, l_cname in varchar2
				, l_new in date
				, l_old in date 
				, l_how in number default 0
			);
 
	procedure check_val( 	
				l_who in varchar2
				, l_ops in number
				, l_owner	in varchar2
				, l_tname in varchar2
				, l_cname in varchar2
				, l_new in number
				, l_old in number 
				, l_how in number default 0
			);
end;
/
 
 
create or replace package body audit_pkg
as
	procedure check_val(	
				l_who in varchar2
				, l_ops in number
				, l_owner	in varchar2
				, l_tname in varchar2
				, l_cname in varchar2
				, l_new in varchar2
				, l_old in varchar2 
				, l_how in number default 0
			)
	is
	begin
		if ( l_new <> l_old 
			or (l_new is null and l_old is not NULL)
			or (l_new is not null and l_old is NULL) )
		then
			insert into audit_tbl 
			(
				id
				, timestamp
				, who
				, towner
				, tname
				, cname
				, old
				, new
				, ops
				, how
			)
			values
				( 
				audit_seq.nextval
				, sysdate
				, user
				, upper(l_owner)
				, upper(l_tname)
				, upper(l_cname)
				, l_old
				, l_new 
				, l_ops
				, l_how
				);
		end if;
	end;
 
	procedure check_val( 
				l_who in varchar2
				, l_ops in number
				, l_owner	in varchar2
				, l_tname in varchar2
				, l_cname in varchar2
				, l_new in date
				, l_old in date 
				, l_how in number default 0
			)
	is
	begin
		if ( l_new <> l_old 
			or (l_new is null and l_old is not NULL) 
			or (l_new is not null and l_old is NULL) )
		then
			insert into audit_tbl 
			(
				id
				, timestamp
				, who
				, towner
				, tname
				, cname
				, old
				, new
				, ops
				, how
			)
			values
				( 
				audit_seq.nextval
				, sysdate
				, user
				, upper(l_owner)
				, upper(l_tname)
				, upper(l_cname)
				, to_char( l_old, 'dd-mon-yyyy hh24:mi:ss' )
				, to_char( l_new, 'dd-mon-yyyy hh23:mi:ss' )
				, l_ops
				, l_how
			);
		end if;
	end;
 
	procedure check_val( 
				l_who in varchar2
				, l_ops in number
				, l_owner	in varchar2
				, l_tname in varchar2
				, l_cname in varchar2
				, l_new in number
				, l_old in number 
				, l_how in number default 0
			)
	is
	begin
		if ( l_new <> l_old 
			or (l_new is null and l_old is not NULL) 
			or (l_new is not null and l_old is NULL) )
		then
			insert into audit_tbl 
			(
				id
				, timestamp
				, who
				, towner
				, tname
				, cname
				, old
				, new
				, ops
				, how
			)
			values
				( 
				audit_seq.nextval
				, sysdate
				, user
				, upper(l_owner)
				, upper(l_tname)
				, upper(l_cname)
				, l_old
				, l_new 
				, l_ops
				, l_how
			);
		end if;
	end;
 
end audit_pkg;
/

