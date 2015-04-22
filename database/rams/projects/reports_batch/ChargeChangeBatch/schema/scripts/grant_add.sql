grant connect to		ccreport;
grant create procedure to	ccreport;
grant create table to		ccreport;
grant create trigger to		ccreport;
grant create materialized view to ccreport;
grant create type to		ccreport;

grant costing_view to		ccreport;

grant execute on hostdb.account_string to		ccreport;
-- added for proj_name lookup
grant select on hostdb.pta_status to		ccreport;

grant select on hostdb.accounts to			ccreport;
grant select on hostdb.dist to 				ccreport;
grant select on hostdb.services to			ccreport;
grant select on hostdb.name to				ccreport;
grant select on hostdb.principal to			ccreport;
grant select on hostdb.bldgs to				ccreport;
grant select on hostdb.depts to				ccreport;
grant select on hostdb.qualifiers to			ccreport;

grant select on aud_hostdb.who to			ccreport;
grant select on aud_hostdb.who_service_charge to	ccreport;

grant select on aud_hostdb.host_service_charge to	ccreport;
grant select on aud_hostdb.hoststab to 			ccreport;
grant select on aud_hostdb.machtab to 			ccreport;
grant select on aud_hostdb.capequip to 			ccreport;

grant execute on hostdb.Account_Report_Email to		ccreport;

--grant execute on ccreport.acct_report to		"COSTING@CS.CMU.EDU";
--grant execute on ccreport.EntityChanged to		"COSTING@CS.CMU.EDU";
--grant select on ccreport.ccreport_logs to		"COSTING@CS.CMU.EDU";

--
-- aud tables
--
--grant select on aud_hostdb.who to			"COSTING@CS.CMU.EDU";
--grant select on aud_hostdb.who_service_charge to	"COSTING@CS.CMU.EDU";
--
--grant select on aud_hostdb.host_service_charge to	"COSTING@CS.CMU.EDU";
--grant select on aud_hostdb.hoststab to 			"COSTING@CS.CMU.EDU";
--grant select on aud_hostdb.machtab to 			"COSTING@CS.CMU.EDU";
--grant select on aud_hostdb.capequip to 			"COSTING@CS.CMU.EDU";
--
--create role ccreport_view;
