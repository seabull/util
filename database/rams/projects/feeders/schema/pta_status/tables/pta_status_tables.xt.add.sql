-- $Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/tables/pta_status_tables.xt.add.sql,v 1.3 2006/04/26 20:18:09 yangl Exp $
--
-- grant create any directory to "YANGL@CS.CMU.EDU";
-- grant read on directory external_tables_dir to "YANGL@CS.CMU.EDU";
--

--create or replace directory costing_xtab_dir as '/usr/costing/external/' 
--/
--
--create or replace directory costing_ext_log_dir as '/usr/oracle/log/ramsldr';

-- 	id			number
-- 	,full_name		varchar2(50)
-- 	,emp_num		number(7)
-- 	,andrew_uid		varchar2(100)
-- 	,last_name		varchar2(50)
-- 	,first_name		varchar2(50)
-- 	,middle_name		varchar2(50)

create table hostdb.pta_status_xt
(
	extract_date			DATE
	,pta				VARCHAR2(68)
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
organization external
(
	type oracle_loader 
	default directory costing_xtab_dir
	access parameters
	(
		records delimited by newline
		badfile ext_log_dir:'ptastatus_xt%a_%p.bad'
		logfile ext_log_dir:'ptastatus_xt%a_%p.log'
		discardfile ext_log_dir:'ptastatus_xt%a_%p.err'
		fields terminated by ','
		missing field values are null
		(
			extract_date
			,pta
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
		)
	)
	location ('scs_outload_pta_status.csv')
)
parallel 2
reject limit unlimited
/
