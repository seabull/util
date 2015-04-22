-- $Id: name_error_tbl.sql,v 1.1 2005/04/20 21:21:21 yangl Exp $
--
create table hostdb.name_error
(
	bid		NUMBER(4)
	,id		NUMBER(6)
	,princ		VARCHAR(50)
	,lname		VARCHAR(50)
	,emp_name	VARCHAR(50)
	,emp_num	VARCHAR(50)
	,andrew_id	VARCHAR(100)
)
tablespace apps
/

create sequence hostdb.nm_error_seq maxvalue 999999;
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

