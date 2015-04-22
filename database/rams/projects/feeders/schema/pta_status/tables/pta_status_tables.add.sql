--$Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/tables/pta_status_tables.add.sql,v 1.1 2006/04/26 19:29:13 yangl Exp $

--
-- run as sysdba
--
--create sequence hostdb.ptarecorded_id_seq
--	start with 1
--	increment by 1
--	nocycle
--/

        --id				number
create table hostdb.pta_recorded
(
	pta				VARCHAR2(68)	not null
					constraint ptarecorded_pk primary key
        ,flag				char(1)		default 'A' not null 
        ,last_active			date		not null
        ,creation_date			date		not null
	--
	,project_id			NUMBER
	,proj_name			VARCHAR2(30)
	,project_number			VARCHAR2(30)
	,proj_start_date		DATE
	,proj_completion_date		DATE
	,proj_closed_date		DATE
	,proj_status_code		VARCHAR2(30)
	,task_number			VARCHAR2(25)
	,task_completion_date		DATE
	,task_charge_flag		VARCHAR2(1)
	,award_number			VARCHAR2(15)
	,award_name			VARCHAR2(30)
	,award_start_date_active	DATE
	,award_end_date_active		DATE
	,award_closed_date		DATE
	,award_status			VARCHAR2(30)
)
tablespace costing
/

--create index ptarecorded_pta_idx on hostdb.pta_recorded (pta)
--	compute statistics
--/

create bitmap index hostdb.ptarecorded_flag_idx on hostdb.pta_recorded (flag)
/

create index hostdb.ptarecorded_adate_idx on hostdb.pta_recorded (last_active)
	compute statistics
/

create table hostdb.history_flags
(
	flag		char(1)
			primary key
	,description	varchar2(20)
)
organization index
tablespace costing
logging
nocompress
/

insert into hostdb.history_flags (flag, description)
	values ('A', 'Active');

insert into hostdb.history_flags (flag, description)
	values ('H', 'History');

create or replace view hostdb.pta_status_v
as
select 
	pta
	,last_active extract_date
	,project_id
	,proj_name
	,project_number
	,proj_start_date
	,proj_completion_date
	,proj_closed_date
	,proj_status_code
	,task_number
	,task_completion_date
	,task_charge_flag
	,award_number
	,award_name
	,award_start_date_active
	,award_end_date_active
	,award_closed_date
	,award_status
  from hostdb.pta_recorded
 where flag='A'
/
