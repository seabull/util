--
-- grant create any directory to "YANGL@CS.CMU.EDU";
-- grant read on directory external_tables_dir to "YANGL@CS.CMU.EDU";
--

--create or replace directory costing_xtab_dir as '/usr/costing/external/' 
--/

--create or replace directory ext_log_dir as '/usr/oracle/log/ldr';

-- 	id			number
-- 	,full_name		varchar2(50)
-- 	,emp_num		number(7)
-- 	,andrew_uid		varchar2(100)
-- 	,last_name		varchar2(50)
-- 	,first_name		varchar2(50)
-- 	,middle_name		varchar2(50)

create table employee_xt
(
	emp_num			number(7)
	,ssn			number(9)
	,full_name		varchar2(50)
	,andrew_uid		varchar2(100)
)
organization external
(
	type oracle_loader 
	default directory costing_xtab_dir
	access parameters
	(
		records delimited by newline
		badfile ext_log_dir:'emp_xt%a_%p.bad'
		logfile ext_log_dir:'emp_xt%a_%p.log'
		discardfile ext_log_dir:'emp_xt%a_%p.err'
		fields terminated by '|'
		missing field values are null
		(
			emp_num
			,ssn
			,full_name
			,andrew_uid
		)
	)
	location ('scs_id_ssn.txt')
)
parallel 2
reject limit unlimited
/
