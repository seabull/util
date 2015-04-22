-- $Header
--
create sequence empid_seq
	start with 1
	increment by 1
	nocycle
/

create table emp_tbl
(
 	id			number
		constraint emptbl_pk primary key 
 	,full_name		varchar2(50)
 	,emp_num		number(7)
 	,andrew_uid		varchar2(100)
 	,last_name		varchar2(50)
 	,first_name		varchar2(50)
 	,middle_name		varchar2(50)
	,flag			char(1)
	,last_active		date
	,creation_date		date
)
tablespace costing
/

create index emptbl_empnum_idx on emp_tbl (emp_num)
/

create index emptbl_flag_idx on emp_tbl (flag)
/

create index emptbl_fullname_idx on emp_tbl (full_name)
/

create or replace trigger emptbl_insert_trg
	before insert
	on emp_tbl
	for each row
	when (new.last_name is null)
begin
	names.parse(:new.full_name,:new.last_name,:new.middle_name,:new.first_name);
	:new.creation_date := sysdate;
	:new.last_active := sysdate;
end;
/

create or replace trigger emptbl_updatename_trg
before update of full_name , emp_num ,andrew_uid
on emp_tbl
begin
	raise_application_error(X.oops, 'updates not allowed for full_name/emp_num of emp_tbl');
end;
/

drop table hostdb.emp
/

create or replace view emp
as 
select
	full_name EMP_NAME
 	,first_name FIRST
 	,middle_name MIDDLE
	,last_name LAST
	,null SSN
	,emp_num EMP_NUM
	,creation_date CREATION_DATE
	,sysdate CREATED_BY
	,last_active LAST_UPDATE
	,null LAST_UPDATE_BY
	,andrew_uid ANDREW_ID
  from emp_tbl
 where flag='A'
/

create or replace view emp_v 
as 
select
	full_name EMP_NAME
 	,first_name FIRST
 	,middle_name MIDDLE
	,last_name LAST
	,null SSN
	,emp_num EMP_NUM
	,creation_date CREATION_DATE
	,sysdate CREATED_BY
	,last_active LAST_UPDATE
	,null LAST_UPDATE_BY
	,andrew_uid ANDREW_ID
  from emp_tbl
 where flag='A'
/

create sequence namecand_idseq
	start with 1
	increment by 1
	nocycle
/

create table name_candidates
(
	candidate_id		number
		constraint namecand_pk primary key
 	,eid			number
 	,emp_num		number(7)
	,princ			varchar2(8)
	,bid			number
	,pri			number(3)
	,reason			char(1)
	,constraint nc_eid_fk foreign key (eid)
			references emp_tbl (id)
	,constraint nc_princ_fk foreign key (princ)
			references principal (name)
)
tablespace apps
/

create or replace view name_candidates_v 
as
select
	unique
	nc.candidate_id
	,nc.bid
	,nc.eid
	,e.full_name	andrew_name
	,e.emp_num	emp_num
	,e.andrew_uid	andrew_princ
	,nc.princ	cs_princ
	,n.name		cs_name
	,n.pri		cs_pri
	,n.emp_num	cs_empnum
  from name_candidates nc
	,name n
	,emp_tbl e
 where 
	nc.eid=e.id
   and nc.princ=n.princ
/
