-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/tables/table_add.sql,v 1.4 2006/07/13 18:01:50 yangl Exp $

create sequence ccreport.acctexp_logs_seq
	start with 1
	nocache
	nocycle
/

create sequence ccreport.acctexp_config_idseq
	start with 1
	nocache
	nocycle
/

create table ccreport.acctexp_logs
(
	id		number	primary key
	,generate_date	date	default sysdate	not null	
	,status		char(1) 
)
tablespace report01
/

--grant select, insert, delete, update on acctexp_logs to costing_change;
--grant select on acctexp_logs to costing_view;

create sequence ccreport.acctexpfact_seq
	start with 1
	nocache
	nocycle
/

create table ccreport.acctexp_fact
(
	id			number		primary key
	,log_id			number		not null
	,pta			varchar2(24)	not null
	,name			varchar2(50)	
	,entity_id		varchar2(9)	not null
	,entity_type		char(1)		not null
	,sponsor		varchar2(10)	not null	-- princ plus flag for machines
	,charge_src		varchar2(20)	not null
	,amount			number(6,2)	not null
	,unitcharge		number(6,2)	not null
	,reasoncode		number(2)	not null
	,expdate_code		varchar2(100)	not null
)
tablespace report01
/

create index acctexpfact_logid_idx on ccreport.acctexp_fact (log_id)
	tablespace report01
/

create index acctexpfact_logidreason_idx on ccreport.acctexp_fact (log_id, reasoncode)
	tablespace report01
/

alter table ccreport.acctexp_fact add constraint acctexpfact_row_uq unique (log_id, pta, entity_id)
	enable
/

--grant select, insert, delete, update on acctexp_fact to costing_change;
--grant select, insert, delete, update on acctexp_fact to costing_admin;
--grant select on acctexp_fact to costing_view;

create table ccreport.acctexp_reasoncodes
(
	reasoncode		number(2)	primary key
	,keyword		varchar2(40)	not null
	,description		varchar2(100)
)
organization index
tablespace report01
nocompress
logging
/

insert into ccreport.acctexp_reasoncodes (reasoncode, keyword, description)
values (1, 'Project Status Invalid','Project Status is Closed, Pending close, unapproved, or submitted');
insert into ccreport.acctexp_reasoncodes (reasoncode, keyword, description)
values (2, 'Award Status Invalid','Award Status is Closed or On_hold.');
insert into ccreport.acctexp_reasoncodes (reasoncode, keyword, description)
values (3, 'Task Not Chargeable','Task Charge Flag is not chargeable.');
insert into ccreport.acctexp_reasoncodes (reasoncode, keyword, description)
values (4, 'PTA Dates','PTA start dates and/or end dates makes the transaction not chargeable to the PTA.');

create table ccreport.acctexp_config
(
	id		number	primary key
	,datecount	number	not null
	,monthend_flag	char(1) default 'Y'	not null 
	,startdate	date	default trunc(sysdate)	not null 
	,constraint acctexpconfig_flag_chk check ( monthend_flag in ('Y','N') )
	,constraint acctexpconfig_datecnt_chk check ( datecount >= 0 )
)
tablespace report01
/

insert into ccreport.acctexp_config
	(id, datecount, monthend_flag, startdate)
select ccreport.acctexp_config_idseq.nextval, 45, 'Y', trunc(sysdate)
  from dual
/
