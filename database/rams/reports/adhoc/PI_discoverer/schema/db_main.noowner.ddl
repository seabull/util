-- Users
spool db_main.noowner.lst

--create role pireport_view;
--create role pireport_change;

create sequence pi_idseq 
	start with 1
	increment by 1
	nocycle
/

create sequence acctrole_idseq 
	start with 1
	increment by 1
	nocycle
/


create sequence charges_idseq 
	start with 1
	increment by 1
	nocycle
/

-- Tables Section
-- _____________ 

create table ACCTS (
	ACCT_ID		number(6) not null,
	ACCT_STR	varchar2(26) not null,
	TYPE		char(1) not null,
	FLAG		char(1) ,
	constraint ACCTS_ID_PK primary key (ACCT_ID)
);

create table ACCT_ROLE (
	NID		number not null
	,ACCT_ID		number(6) not null
	,EMP_NUM		number(7) not null
	,ROLE		varchar2(80) not null
	,constraint ACCTROLE_PK primary key (NID)
);

create table CHARGES (
	NID		number not null
	, ENTITY_ID	varchar2(8) not null
	, NAME		varchar2(50) not null
	, TYPE		char(1) not null
	, ACCT_ID	number(6) not null
	, CHARGE	number(6,2) not null
	, PCT		number(5,2) not null
	, AMOUNT	number(6,2) not null
	, TRANS_DATE	date not null
	, JNL_ID	number(5) not null
	, Account_Flag	char(1)
	, constraint CHARGES_PK primary key (NID)
)
partition by range (jnl_id)
(
	partition c_fy05	values less than (238)
		tablespace costing_lg
	,partition c_currfy	values less than (MAXVALUE)
		tablespace costing_lg
)
enable row movement
;

create table INVESTIGATOR (
	NID		number not null
	,EMP_NUM	number(7) not null
	,PRINC		varchar2(8) not null
	,NAME		varchar2(50) not null
	,constraint INVESTIGATOR_PK primary key (NID)
);
	-- should make sure (emp_num,princ) is unique by either constraint or index
	--constraint INVESTIGATOR_PK primary key (EMP_NUM)

-- Should it be changed to use partitioned IOT?
create table JNLS (
	JNL_ID		number(5) not null,
	POST_DATE	date not null,
	TYPE		char(1) not null,
	constraint JNLS_PK primary key (JNL_ID)
)
partition by range (jnl_id)
(
	partition jnl_fy05	values less than (238)
		tablespace costing_lg
	,partition jnl_currfy	values less than (MAXVALUE)
		tablespace costing_lg
)
enable row movement
/


-- Constraints Section
-- ___________________ 

--alter table ACCT_ROLE add constraint ACCTROLE_EMP_FK
	--foreign key (EMP_NUM)
	--references INVESTIGATOR;

alter table ACCT_ROLE add constraint ACCTROLE_ACCTID_FK
	foreign key (ACCT_ID)
	references ACCTS;

alter table CHARGES add constraint CHARGES_JNL_FK
	foreign key (JNL_ID)
	references JNLS;

alter table CHARGES add constraint CHARGES_ACCTID_FK
	foreign key (ACCT_ID)
	references ACCTS;

-- Index Section
-- _____________ 

create index ACCTROLE_EMP_IDX
	on ACCT_ROLE (EMP_NUM);

create index CHARGES_ACCTID_IDX
	on CHARGES (ACCT_ID)
	local 
/

create index CHARGES_JNL_IDX
	on CHARGES (JNL_ID)
	local
/

create index CHARGES_EID_IDX
	on CHARGES (ENTITY_ID)
	local
/

create index charges_type_idx
	on charges (type)
	local
/

create index charges_name_idx
	on charges (name)
	local
/

-- this is a candidate to convert to global
create index charges_tdate_idx
	on charges (trans_date)
	local
/

create index JNLS_PDATE_IDX
	on JNLS (POST_DATE)
	local
/

create index investigator_empnum_IDX
	on investigator (emp_num);

--
create index investigator_princ_idx
	on investigator (princ)
/

--create index accts_acctid_idx
--	on accts (acct_id)
--/

create index ACCTROLE_ACCTID_IDX
	on ACCT_ROLE (ACCT_ID)
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
spool off
