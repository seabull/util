-- $Id: audit_tbl.sql,v 1.3 2005/05/09 15:37:54 yangl Exp $
--
create table audit_tbl
(    
	  id		number(10)
	, timestamp	date default sysdate
		constraint audittbl_ts_nn	not null
	, who		varchar2(30)
	, towner	varchar2(30)
		constraint audittbl_towner_nn	not null
	, tname		varchar2(30)
		constraint audittbl_tname_nn	not null
	, cname		varchar2(30)
		constraint audittbl_cname_nn	not null
	, old		varchar2(2000)
	, new		varchar2(2000)
	, ops		number
	, how		number
	, constraint audittbl_pk	primary key (id)
	, constraint audittbl_ops_fk	foreign key (ops) references audit_operations (id)
	-- , constraint audittbl_how_fk	foreign key (how) references 
)
tablespace costing_lg
/
-- tablespace audit_tbls

create sequence audit_seq maxvalue 9999999999;

create table audit_operations 
(
	id	number
	,name	varchar2(27)
		constraint auditops_name_nn NOT NULL
	,constraint auditops_pk primary key (id)
)
tablespace costing_lg
/

create table audit_applications
(
	id	number
	,name	varchar2(50)
		constraint auditapps_name_nn not null
	,description	varchar2(100)
	,constraint auditapps_pk primary key (id)
)
tablespace costing_lg
/
