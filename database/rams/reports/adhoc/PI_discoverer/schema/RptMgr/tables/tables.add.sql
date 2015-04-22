-- $Id: tables.add.sql,v 1.7 2007/04/30 17:50:57 yangl Exp $

--spool tables.add.lst

create sequence pireport.rptmgr_idseq 
	start with 1
	increment by 1
	nocycle
/

create sequence pireport.acctrole_idseq 
	start with 1
	increment by 1
	nocycle
/


create sequence pireport.charges_idseq 
	start with 1
	increment by 1
	nocycle
/

-- Tables Section
-- _____________ 

create table pireport.ACCTS (
	ACCT_ID		number(6) not null,
	ACCT_STR	varchar2(26) not null,
	TYPE		char(2) not null,
	FLAG		char(1) ,
    proj_name   varchar2(30),
	constraint ACCTS_ID_PK primary key (ACCT_ID)
)
tablespace report01
;

-- princ is 8 chars but report manager tables have it as 10 chars.
create table pireport.ACCT_ROLE (
	NID		        number      not null
	,ACCT_ID		number(6)   not null
	,PRINC  		varchar2(10) not null
	,EMP_NUM		number(7)   --not null
	,ROLE		    varchar2(80) not null
    ,VALID          varchar2(1) default 'Y' not null check (VALID in ('Y','N'))
	,constraint ACCTROLE_PK primary key (NID)
)
tablespace report01
/

create table pireport.CHARGES (
	NID		        number not null
	, ENTITY_ID	    varchar2(8) not null
	, NAME		    varchar2(50) not null
	, SCS_ID	    varchar2(50) not null
	, TYPE		    char(1) not null
	, ACCT_ID	    number(6) not null
	, CHARGE	    number(6,2) not null
	, PCT		    number(5,2) not null
	, AMOUNT	    number(6,2) not null
	, TRANS_DATE	date not null
	, JNL_ID	    number(5) not null
	, Account_Flag	char(1)
    --
	, acct_string	varchar2(24) not null
	, services  	varchar2(24) not null
	--, dist_vec  	varchar2(4000) not null
    --
	, constraint CHARGES_PK primary key (NID)
)
partition by range (jnl_id)
(
	partition c_fy05	values less than (238)
		tablespace report01
	,partition c_fy06	values less than (277)
		tablespace report01
	,partition c_currfy	values less than (MAXVALUE)
		tablespace report01
)
enable row movement
/

create table pireport.INVESTIGATOR (
	NID		    number      not null
	,EMP_NUM	number(7)   -- not null
	,PRINC		varchar2(10) not null
	,NAME		varchar2(50) not null
	,constraint INVESTIGATOR_PK primary key (NID)
)
tablespace report01
/
	-- should make sure (emp_num,princ) is unique by either constraint or index
	--constraint INVESTIGATOR_PK primary key (EMP_NUM)

-- Should it be changed to use partitioned IOT?
create table pireport.JNLS (
	JNL_ID		number(5) not null,
	POST_DATE	date not null,
	TYPE		char(1) not null,
	constraint JNLS_PK primary key (JNL_ID)
)
partition by range (jnl_id)
(
	partition jnl_fy05	values less than (238)
		tablespace report01
	,partition jnl_fy06	values less than (277)
		tablespace report01
	,partition jnl_currfy	values less than (MAXVALUE)
		tablespace report01
)
enable row movement
/


-- Constraints Section
-- ___________________ 

--alter table pireport.ACCT_ROLE add constraint ACCTROLE_EMP_FK
	--foreign key (EMP_NUM)
	--references pireport.INVESTIGATOR;

alter table pireport.ACCT_ROLE add constraint ACCTROLE_ACCTID_FK
	foreign key (ACCT_ID)
	references pireport.ACCTS;

alter table pireport.CHARGES add constraint CHARGES_JNL_FK
	foreign key (JNL_ID)
	references pireport.JNLS;

alter table pireport.CHARGES add constraint CHARGES_ACCTID_FK
	foreign key (ACCT_ID)
	references pireport.ACCTS;

-- Index Section
-- _____________ 

create index pireport.ACCTROLE_EMP_IDX
	on pireport.ACCT_ROLE (EMP_NUM);

--create index pireport.ACCTROLE_VALID_IDX
--	on pireport.ACCT_ROLE (VALID);

--create index pireport.ACCTROLE_ACCTIDEMP_IDX
--	on pireport.ACCT_ROLE (account_id, emp_num);

create index pireport.CHARGES_ACCTID_IDX
	on pireport.CHARGES (ACCT_ID)
	local 
/

create index pireport.CHARGES_JNL_IDX
	on pireport.CHARGES (JNL_ID)
	local
/

create index pireport.CHARGES_EID_IDX
	on pireport.CHARGES (ENTITY_ID)
	local
/

create index pireport.charges_type_idx
	on pireport.charges (type)
	local
/

create index pireport.charges_name_idx
	on pireport.charges (name)
	local
/

-- this is a candidate to convert to global
create index pireport.charges_tdate_idx
	on pireport.charges (trans_date)
	local
/

create index pireport.JNLS_PDATE_IDX
	on pireport.JNLS (POST_DATE)
	local
/

create index pireport.investigator_empnum_IDX
	on pireport.investigator (emp_num);

--
create index pireport.investigator_princ_idx
	on pireport.investigator (princ)
/

--create index accts_acctid_idx
--	on accts (acct_id)
--/

create index pireport.ACCTROLE_ACCTID_IDX
	on pireport.ACCT_ROLE (ACCT_ID)
/

-- grant select on charges to pireport_view;
-- grant select on accts to pireport_view;
-- grant select on jnls to pireport_view;
-- grant select on investigator to pireport_view;
-- grant select on acct_role to pireport_view;
-- 
-- grant insert, update, delete on charges to pireport_change;
-- grant insert, update, delete on accts to pireport_change;
-- grant insert, update, delete on jnls to pireport_change;
-- grant insert, update, delete on investigator to pireport_change;
-- grant insert, update, delete on acct_role to pireport_change;
-- 
-- @connect '/ as sysdba'
-- grant pireport_view to pireport_change;

--drop table ACCT_ROLE ;
--drop table INVESTIGATOR;
--drop table charges;
--drop table jnls;
--drop table accts ;
--drop sequence pi_idseq;
--drop sequence acctrole_idseq;
--drop sequence charges_idseq;
