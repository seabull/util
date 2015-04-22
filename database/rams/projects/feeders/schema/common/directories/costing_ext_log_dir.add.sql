-- $Header: c:\\Repository/database/rams/projects/feeders/schema/common/directories/costing_ext_log_dir.add.sql,v 1.1 2006/04/26 20:08:58 yangl Exp $
--
-- grant create any directory to "YANGL@CS.CMU.EDU";
-- grant read on directory external_tables_dir to "YANGL@CS.CMU.EDU";
--

create or replace directory costing_ext_log_dir as '/usr/oracle/log/ramsldr'
/
