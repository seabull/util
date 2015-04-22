-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/feeder_load.sps.sql,v 1.1 2006/03/13 14:43:45 yangl Exp $

create or replace package hostdb.feeder_load as
	-- constants
	constFlagActive		char(1)	:= 'A';
	constFlagHistory	char(1)	:= 'H';

	-- methods
	procedure pta_load;
	procedure pta_load(p_flag IN boolean);
end feeder_load;
/
show error

grant execute on hostdb.feeder_load to costing_change;
grant execute on hostdb.feeder_load to costing_admin;
