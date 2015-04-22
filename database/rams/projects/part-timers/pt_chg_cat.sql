-- $Id: pt_chg_cat.sql,v 1.1 2005/05/25 14:59:42 yangl Exp $
--

create table hostdb.pt_chg_cat
(
	cat		char(1)
	,pct		number(6,3)
		constraint ptchgcat_pct_nn not null
	,description	varchar2(50)
)
tablespace costing
/

alter table hostdb.pt_chg_cat add constraint ptchgcat_pk 
	primary key (cat)
	using index
	tablespace indx
/

/*
-- do not keep hist any more, use audit trail.
create sequence hostdb.ptchgcathist_seq maxvalue 99999 cycle;

create table hostdb.pt_chg_cat_hist
(
	id		number(5)
		constraint ptchgcathist_pk primary key using index tablespace indx
	,trans_date	date default sysdate
	,user_id	varchar2(30)
	,operation	varchar2(1)
	--,application	varchar2(30)
	,cat		char(1)
	,pct		number(6,3)
)
tablespace costing
/

create trigger hostdb.pt_chg_cat_chgd 
	after insert or update or delete of cat, pct on hostdb.pt_chg_cat
	referencing old as old new as new
	for each row
declare
	l_op	pt_chg_cat_hist.operation%TYPE;
	l_cat	pt_chg_cat_hist.cat%TYPE;
	l_pct	pt_chg_cat_hist.pct%TYPE;
begin
	if (deleting) then
		l_op := 'd';
		l_cat := :old.cat;
		l_pct := :old.pct;
	else	if (inserting) then
			l_op := 'i';
			l_cat := :new.cat;
			l_pct := :new.pct;
		else
			l_op := 'u';
			l_cat := :new.cat;
			l_pct := :new.pct;
		end if;
	end if;

	insert into pt_chg_cat_hist
	(
		id
		,trans_date
		,user_id
		,operation
		,cat
		,pct
	) 
	select ptchgcathist_seq.nextval
		,sysdate
		,user
		,l_op
		,l_cat
		,l_pct
	  from dual;	
end;
/
*/

-- create a new charge source to indicate case 3 part-time users turn into residue, i.e. 
-- the time card data do not show up and they fall into the default account
 --Name                                                  Null?    Type
 ------------------------------------------------------- -------- ------------------------------------
 --KIND                                                  NOT NULL VARCHAR2(3)
 --DESCRIPTION                                           NOT NULL VARCHAR2(70)
 --ATTR                                                  NOT NULL VARCHAR2(4)
 --PRI                                                   NOT NULL NUMBER(3)
 --ORG                                                            VARCHAR2(6)

/*
insert into charge_sources (kind, description, attr, pri)
values
('x','Residue for part-time users', 'p', 1)
/
*/


/*
dist
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 DIST                                                  NOT NULL NUMBER(6)
 ACCOUNT                                               NOT NULL NUMBER(6)
 PCT                                                   NOT NULL NUMBER(6,3)
 TPCT                                                  NOT NULL NUMBER(6,3)

hostdb@FAC_03.APOGEE.FAC.CS.CMU.EDU> select * from dist where dist=2880;
      DIST    ACCOUNT        PCT       TPCT
---------- ---------- ---------- ----------
      2880      16448         50         50
      2880      16475         50         50

2 rows selected.

hostdb@FAC_03.APOGEE.FAC.CS.CMU.EDU> desc dist_names
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 DIST                                                  NOT NULL NUMBER(6)
 NAME                                                  NOT NULL VARCHAR2(30)
 SUBNAME                                               NOT NULL VARCHAR2(12)
 USER_ONLY                                                      CHAR(1)
 SRC                                                   NOT NULL VARCHAR2(3)
 PCT                                                            NUMBER(5,2)


*/
