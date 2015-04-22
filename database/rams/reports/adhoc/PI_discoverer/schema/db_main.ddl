-- Users
spool db_main.lst
create user ramsreport identified by ramstestnow
        default tablespace apps
        quota unlimited on apps
        temporary tablespace temp
        quota 512M on temp
	quota 1024M on indx
        account unlock;

grant create session
        , create table
        , create view
        , create procedure
        , create sequence
to ramsreport;

create role pireport_view;
create role pireport_change;

-- Tables Section
-- _____________ 

@connect 'ramsreport/ramstestnow'

create table ACCOUNTS (
	ACCT_ID number(6) not null,
	STRING varchar2(26) not null,
	TYPE char(1) not null,
	FLAG char(1) ,
	constraint ACCOUNTS_ID_PK primary key (ACCT_ID)
);

create table ACCT_ROLE (
	ACCT_ID number(6) not null,
	EMP_NUM number(7) not null,
	ROLE varchar2(80) not null,
	constraint ACCTROLE_PK primary key (ACCT_ID, EMP_NUM)
);

create table CHARGES (
	ENTITY_ID	varchar2(8) not null
	, NAME		varchar2(50) not null
	, TYPE		char(1) not null
	, ACCT_ID	number(6) not null
	, CHARGE	number(6,2) not null
	, PCT		number(5,2) not null
	, AMOUNT	number(6,2) not null
	, TRANS_DATE	date not null
	, JNL_ID	number(5) not null
	, Account_Flag	char(1)
	, constraint CHARGES_PK primary key (ACCT_ID, JNL_ID, ENTITY_ID)
);

create table INVESTIGATOR (
	EMP_NUM number(7) not null,
	PRINC varchar2(8) not null,
	NAME varchar2(50) not null,
);
	--constraint INVESTIGATOR_PK primary key (EMP_NUM)

create table JOURNALS (
	JNL_ID number(5) not null,
	POST_DATE date not null,
	TYPE char(1) not null,
	constraint JOURNALS_PK primary key (JNL_ID)
);


-- Constraints Section
-- ___________________ 

alter table ACCT_ROLE add constraint ACCTROLE_EMP_FK
	foreign key (EMP_NUM)
	references INVESTIGATOR;

alter table ACCT_ROLE add constraint ACCTROLE_ACCTID_FK
	foreign key (ACCT_ID)
	references ACCOUNTS;

alter table CHARGES add constraint CHARGES_JNL_FK
	foreign key (JNL_ID)
	references JOURNALS;

alter table CHARGES add constraint CHARGES_ACCTID_FK
	foreign key (ACCT_ID)
	references ACCOUNTS;

-- Index Section
-- _____________ 

create index ACCTROLE_EMP_IDX
	on ACCT_ROLE (EMP_NUM);

create index CHARGES_ACCTID_IDX
	on CHARGES (ACCT_ID);

create index CHARGES_JNL_IDX
	on CHARGES (JNL_ID);

create index CHARGES_EID_IDX
	on CHARGES (ENTITY_ID);

create index JOURNALS_PDATE_IDX
	on JOURNALS (POST_DATE);

create index investigator_empnum_IDX
	on investigator (emp_num);

grant select on ramsreport.charges to pireport_view;
grant select on ramsreport.accounts to pireport_view;
grant select on ramsreport.journals to pireport_view;
grant select on ramsreport.investigator to pireport_view;
grant select on ramsreport.acct_role to pireport_view;

grant insert, update, delete on ramsreport.charges to pireport_change;
grant insert, update, delete on ramsreport.accounts to pireport_change;
grant insert, update, delete on ramsreport.journals to pireport_change;
grant insert, update, delete on ramsreport.investigator to pireport_change;
grant insert, update, delete on ramsreport.acct_role to pireport_change;

@connect '/ as sysdba'
grant pireport_view to pireport_change;
spool off
