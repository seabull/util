-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/tables/table_add.sql,v 1.1 2006/04/11 20:43:55 yangl Exp $
--
-- table to control the views
create global temporary table histview_param
(
	id	number		primary key
	,flag	char(1)		not null
	,ts	timestamp	not null
) on commit preserve rows
/

grant select, insert, delete, update on histview_param to public
/

create sequence ccreport_id_seq
	start with 1
	nocache
	nocycle
/

create table ccreport_logs
(
	ccreport_id	number			primary key
	,ts_old		timestamp		not null
	,ts_new		timestamp		not null	
	,rpttype	char(1)	default 'R'	not null	-- R - Regular, A - Adhoc
	,rptsubtype	char(1)	default 'W'	not null	-- W - Weekly, L - Labor
	,generated	date	default sysdate	not null 
	,status		char(1) default 'I'	not null	-- I - init, P - in process, R - recorded
)
--organization index
tablespace report01
logging
nocompress
/

create bitmap index ccreportlogs_rpttype_idx on ccreport_logs (rpttype);

create or replace view ccreport_logs_r
as
select
	*
  from ccreport_logs
 where rpttype='R'
/

grant select on ccreport_logs to "COSTING@CS.CMU.EDU";
grant select on ccreport_logs_r to "COSTING@CS.CMU.EDU";

--create table charge_dist_logs
--as
--(
--	charge_dist_id	number primary key
--	,charge_dist	varchar2(4000)
--	,constraint chargedistlogs_pk primary key (charge_dist_id)
--)
--organization index
--tablespace report01
--logging
--nocompress
--/

create sequence who_charge_changed_seq
	start with 1
	nocycle
/

create table who_charge_changed
(
	who_charge_changed_id	number	not null
	,report_log_id		number	not null
	,princ			varchar2(8) not null
	--,charge_dist_from	number
	--	constraint wcc_distfrom foreign key references charge_dist_logs (charge_dist_id)
	--,charge_dist_to		number
	--	constraint wcc_distto foreign key references charge_dist_logs (charge_dist_id)
)
tablespace report01
/

CREATE OR REPLACE TRIGGER who_charge_changed_id 
	BEFORE INSERT OR UPDATE OF who_charge_changed_id ON who_charge_changed 
	FOR EACH ROW
BEGIN
	IF (:new.who_charge_changed_id IS NULL) THEN
		SELECT who_charge_changed_seq.nextval INTO :new.who_charge_changed_id FROM dual;
	END IF;
END;
/

create sequence who_conf_changed_seq
	start with 1
	nocycle
/

create table who_conf_changed
(
	who_conf_changed_id	number	primary key
	,report_log_id		number	not null
	,princ			varchar2(8)	not null
	,name			varchar2(50)	not null
	,charge_by		char(1)		not null
	,sponsor		varchar2(8)	not null
	,PctUser		number(6,3)	not null
	,service_vec		varchar2(4000)	not null
	,dist_id		number(6)	not null	-- add foreign key 
	,ChargeAmount		number(6,2)	not null
	,LastChanged		timestamp	not null
	,change_flag		varchar2(3)	not null
)
--tablespace report01
partition by range (report_log_id)
(
        partition c_current	values less than (MAXVALUE)
                tablespace report01
)
enable row movement
/

CREATE OR REPLACE TRIGGER who_conf_changed_id 
	BEFORE INSERT OR UPDATE OF who_conf_changed_id ON who_conf_changed 
	FOR EACH ROW
BEGIN
	IF (:new.who_conf_changed_id IS NULL) THEN
		SELECT who_conf_changed_seq.nextval INTO :new.who_conf_changed_id FROM dual;
	END IF;
END;
/

create index whoconfchanged_id_idx on who_conf_changed (report_log_id);
--
-- machines
--

create sequence host_charge_changed_seq
	start with 1
	nocycle
/

create table host_charge_changed
(
	host_charge_changed_id	number	not null
	,report_log_id		number	not null
	,assetno		varchar2(9) not null
	,pri			number(6) not null
)
tablespace report01
/

CREATE OR REPLACE TRIGGER host_charge_changed_id 
	BEFORE INSERT OR UPDATE OF host_charge_changed_id ON host_charge_changed 
	FOR EACH ROW
BEGIN
	IF (:new.host_charge_changed_id IS NULL) THEN
		SELECT host_charge_changed_seq.nextval INTO :new.host_charge_changed_id FROM dual;
	END IF;
END;
/

create sequence host_conf_changed_seq
	start with 1
	nocycle
/

create table host_conf_changed
(
	host_conf_changed_id	number	primary key
	,report_log_id		number	not null
	,assetno		varchar2(9) 	not null
	,hostname		varchar2(40)	not null
	,pri			number(6)	not null
	,charge_by		char(1)		not null
	,qual			char(1)		not null
	,service_vec		varchar2(4000)	not null
	,location		varchar2(50)	not null
	,primaryUser		varchar2(10)	not null
	,os			varchar2(10)	not null
	,dist_id		number(6)	not null
	,dept			varchar2(8)	not null
	,ChargeAmount		number(6,2)	not null
	,LastChanged		timestamp	not null
	,change_flag		varchar2(3)	not null
	,ipaddress		varchar2(30)	not null
	,protocol		varchar2(3)	not null
)
--tablespace report01
partition by range (report_log_id)
(
        partition c_current	values less than (MAXVALUE)
                tablespace report01
)
enable row movement
/

--        ,partition c_currfy     values less than (MAXVALUE)
--                tablespace costing_lg

CREATE OR REPLACE TRIGGER host_conf_changed_id 
	BEFORE INSERT OR UPDATE OF host_conf_changed_id ON host_conf_changed 
	FOR EACH ROW
BEGIN
	IF (:new.host_conf_changed_id IS NULL) THEN
		SELECT host_conf_changed_seq.nextval INTO :new.host_conf_changed_id FROM dual;
	END IF;
END;
/

create index hostconfchanged_id_idx on host_conf_changed (report_log_id);


--
-- need to add a lookup table for ccreport_types
--
--'R','Regular';
--'A','Adhoc';
--'W','Weekly';
--'L','Labor';
--'N','NA';
--
--constStatusInit         char(1) := 'I';
--constStatusProcess      char(1) := 'P';
--constStatusRecorded     char(1) := 'R';
--



--create table host_charge_changed
--(
--	host_charge_changed_id	number		not null
--	,report_log_id		number		not null
--	,assetno		varchar2(9)	not null
--	,pri			number(6)	not null
--	,charge_dist_from	number		not null
--	,charge_dist_to		number		not null
--)
--tablespace report01
--/

--create table charge_change_log
--tablespace apps
--/
