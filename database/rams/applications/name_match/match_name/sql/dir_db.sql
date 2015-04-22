-- $Header: c:\\Repository/database/rams/applications/name_match/match_name/sql/dir_db.sql,v 1.6 2006/07/25 18:26:07 yangl Exp $
--
-- grant create any directory to "YANGL@CS.CMU.EDU";
--

-- as dba
--grant create any directory to "HOSTDB";

-- as hostdb
create or replace directory costing_xtab_dir as '/usr/costing/data/external/' 
/

create or replace directory ext_log_dir as '/usr/oracle/log/ldr';

grant read, write on directory costing_xtab_dir to names_change;
grant read, write on directory costing_xtab_dir to "COSTING@CS.CMU.EDU";
grant read, write on directory costing_xtab_dir to hostdb;
grant read, write on directory costing_xtab_dir to "YANGL@CS.CMU.EDU";

grant read, write on directory ext_log_dir to names_change;
grant read, write on directory ext_log_dir to "COSTING@CS.CMU.EDU";
grant read, write on directory ext_log_dir to hostdb;
grant read, write on directory ext_log_dir to "YANGL@CS.CMU.EDU";
