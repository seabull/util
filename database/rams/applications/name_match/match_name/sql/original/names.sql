-- $Id: names.sql,v 1.1 2005/04/20 21:21:54 yangl Exp $
--
--set autotrace on traceonly
/*
create table hostdb.name_error
(
	bid		NUMBER(4)
	,id		NUMBER(5)
	,princ		VARCHAR(50)
	,lname		VARCHAR(50)
	,emp_name	VARCHAR(50)
	,emp_num	VARCHAR(50)
	,andrew_id	VARCHAR(100)
)
tablespace apps
/

create sequence hostdb.nm_error_seq maxvalue 99999;
-- create sequence hostdb.nm_errorbid maxvalue 9999 cycle;
create table hostdb.name_error_bids
(
	id		NUMBER(4)
	,post_date	DATE
)
tablespace apps
/
alter table hostdb.name_error_bids add constraint nm_errorids_pk primary key (id)
	using index
	tablespace INDX
/

alter table hostdb.name_error add constraint nm_error_pk primary key (id)
	using index
	tablespace INDX
/

alter table hostdb.name_error add constraint nm_error_fk foreign key (bid) 
	references hostdb.name_error_bids (id)
	enable
/
*/

create or replace trigger hostdb.nmerror_id_trg 
	before insert on hostdb.name_error
	for each row
begin
	if (:new.id is null) then
		select hostdb.nm_error_seq.nextval into :new.id
		  from dual;
	end if;
end;
/


create or replace package hostdb.matchnames_pkg as
	xc_invalid_id	Exception;

	constDEBUGLEVEL_A	pls_integer	:= 2;
	constDEBUGLEVEL_B	pls_integer	:= 4;
	constDEBUGLEVEL_C	pls_integer	:= 8;
	constDEBUGLEVEL_D	pls_integer	:= 16;
	constDEBUGLEVEL_E	pls_integer	:= 32;

	procedure init_bids ;
	procedure match_fullname;
	procedure match_firstlast;
end matchnames_pkg;
/

create or replace package body hostdb.matchnames_pkg as
	procedure init_bids IS
	l_cnt	pls_integer := 0;
	l_bid	pls_integer := 0;
	begin
		select count(*)
		  into l_cnt
		  from name_error_bids;

		if l_cnt < 1 then
			insert into name_error_bids (id, post_date)
			select l_bid
				, sysdate
			  from dual;
		end if;
	
	end;

	procedure match_firstlast IS
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.match_firstlast.');
		traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_firstlast Normal');
	exception
		when others then
			traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_firstlast Exception, %s, %s', SQLCODE,SQLERRM);
	end match_firstlast; 

	procedure match_fullname IS
	l_bid	pls_integer	:= 0;
	begin
		traceit.log(constDEBUGLEVEL_A,'Enter hostdb.matchnames_pkg.match_fullname.');

		select 
			max(id)+1
			-- nm_errorbid.nextval
		  into l_bid
		  from name_error_bids;
		traceit.log(constDEBUGLEVEL_C,'batch id=%s',l_bid);

		if l_bid is null then
			traceit.log(constDEBUGLEVEL_A,'l_bid is null. set it to 1');
			l_bid := 1;
		end if;

		if l_bid < 1 then
			traceit.log(constDEBUGLEVEL_A,'Invalid batch id=%s',l_bid);
			raise xc_invalid_id;
		end if;

		insert into name_error_bids (id, post_date)
			select nvl(l_bid, 1), sysdate
			  from dual;

		insert into hostdb.name_error 
			( bid
			 ,princ
			 ,lname
			 ,emp_name
			 ,emp_num
			 ,andrew_id
			)
		 select
			l_bid
			,n1.princ
			,n1.lname
			,e1.emp_name
			,e1.emp_num
			,e1.andrew_id
		   from hostdb.emp e1
			,hostdb.name n1
		  where e1.emp_name in 
			(
				select 
					e.emp_name
					--,count(e.emp_num) 
				  from hostdb.emp e
					,hostdb.name n
				 where 
					n.emp_num is null
					and lower(n.lname)=lower(e.emp_name)
					and n.pri=0
				group by 
					e.emp_name
				having count(e.emp_num)>1
			)
			and lower(n1.lname)=lower(e1.emp_name)
			and n1.emp_num is null
		;

		traceit.log(constDEBUGLEVEL_A,'%s rows inserted into hostdb.name_error', SQL%ROWCOUNT);
		util.log(SQL%ROWCOUNT||' rows inserted into hostdb.name_error');
				
		-- we will have audit in place any way.
		-- save the first 5 letters of the user here.
		update name n
		   set (emp_num,last_update,last_updated_by)=( select e.emp_num
									,sysdate
									,substr(user, 1, 5)||'.mf'
				   from hostdb.emp e
				  where lower(n.lname)=lower(e.emp_name)
				)
		 where n.emp_num is null
		   and n.lname not in (
					select lname 
					  from name_error
					 where bid=l_bid
					)
		   and exists (	select emp_num
				  from emp e2
				 where lower(n.lname)=lower(e2.emp_name)
				)
		   and n.pri=0
			;

		traceit.log(constDEBUGLEVEL_C,'%s rows updated in hostdb.name', SQL%ROWCOUNT);
		util.log(SQL%ROWCOUNT||' rows updated in hostdb.name');
		traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Normal');
	exception
		when xc_invalid_id then
			raise_application_error(X.oops,'Invalid id is generated for name_error. bid='||l_bid);

		when others then
			traceit.log(constDEBUGLEVEL_A,'Exit matchnames_pkg.match_fullname Exception, %s, %s', SQLCODE,SQLERRM);
			raise_application_error(X.oops,'Exception when doing match. '||SQLERRM);
			
	end match_fullname;
--begin
	--null;
end matchnames_pkg;
/

-- 
--
--
/*
create role names_view not identified;
create role names_change not identified;

grant select on hostdb.name_error to names_view;
grant select on hostdb.name_error_bids to names_view;

grant names_view to names_change;
grant update,insert,delete on hostdb.name_error to names_change;
grant update,insert,delete on hostdb.name_error_bids to names_change;
grant select,alter on hostdb.name_error_bids to names_change;
grant execute on hostdb.matchnames_pkg to names_change;


grant names_change to "COSTING@CS.CMU.EDU";
grant names_change to "KZM@CS.CMU.EDU";
grant names_view to "TFAULK@CS.CMU.EDU";

*/

/*
insert into hostdb.name_error (bid,princ, lname, emp_name, emp_num)
(
select 
	hostdb.nm_mismatchid.nextval
	,n1.princ
	,n1.lname
	,e1.emp_name
	,e1.emp_num
	,e1.andrew_id
from hostdb.emp e1
	,hostdb.name n1
where e1.emp_name not in 
(
select 
	e.emp_name
	--,count(e.emp_num) 
from hostdb.emp e
	,hostdb.name n
where 
	n.emp_num is null
	and lower(n.lname)=lower(e.emp_name)
	-- if a user has two different princ, the following does not work.
	-- and n.pri=(select min(pri) from name n2 where n2.princ=n.princ)
	and n.pri=0
group by 
	e.emp_name
having count(e.emp_num)>1
)
and lower(n1.lname)=lower(e1.emp_name)
and n1.emp_num is null
/


hostdb@FAC_02.APOGEE.FAC.CS.CMU.EDU> desc emp
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 EMP_NAME                                              NOT NULL VARCHAR2(50)
 FIRST                                                          VARCHAR2(50)
 MIDDLE                                                         VARCHAR2(50)
 LAST                                                           VARCHAR2(50)
 SSN                                                            NUMBER(9)
 EMP_NUM                                                        NUMBER(7)
 CREATION_DATE                                                  DATE
 CREATED_BY                                                     VARCHAR2(30)
 LAST_UPDATE                                                    DATE
 LAST_UPDATE_BY                                                 VARCHAR2(30)
 ANDREW_ID                                                      VARCHAR2(100)

hostdb@FAC_02.APOGEE.FAC.CS.CMU.EDU> desc name
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 PRINC                                                 NOT NULL VARCHAR2(8)
 NAME                                                  NOT NULL VARCHAR2(50)
 LCNAME                                                NOT NULL VARCHAR2(50)
 PRI                                                   NOT NULL NUMBER(3)
 LNAME                                                 NOT NULL VARCHAR2(51)
 SSN                                                            NUMBER(9)
 EMP_NUM                                                        NUMBER(7)
 CREATION_DATE                                                  DATE
 CREATED_BY                                                     VARCHAR2(8)
 LAST_UPDATE                                                    DATE
 LAST_UPDATED_BY                                                VARCHAR2(8)

*/
