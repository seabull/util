-- $Header: c:\\Repository/database/rams/projects/feeders/schema/pta_status/pkgs/pta_load.sps.sql,v 1.1 2006/04/26 19:32:31 yangl Exp $

create or replace package hostdb.pta_load as
	-- constants
	constFlagActive		char(1)	:= 'A';
	constFlagHistory	char(1)	:= 'H';

	-- methods
	procedure pta_load;
	procedure pta_load(p_flag IN boolean);
end feeder_load;
/
show error

grant execute on hostdb.pta_load to costing_change;
grant execute on hostdb.pta_load to costing_admin;
