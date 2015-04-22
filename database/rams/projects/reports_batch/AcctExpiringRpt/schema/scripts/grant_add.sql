--$Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/scripts/grant_add.sql,v 1.2 2006/07/13 18:37:36 yangl Exp $

grant select on hostdb.pta_status	to ccreport;
grant select on hostdb.who		to ccreport;
--grant select on hostdb.name		to ccreport;
grant select on hostdb.who_service_charge	to ccreport;

grant select on hostdb.host_service_charge		to ccreport;
grant select on hostdb.capequip		to ccreport;
grant select on hostdb.machtab		to ccreport;
grant select on hostdb.hoststab		to ccreport;

--grant select on aud_hostdb.pta_recorded	to ccreport;

--grant execute on ccreport.acctexp_rpt to	"COSTING@CS.CMU.EDU";
--grant execute on ccreport.emailinfo to		"COSTING@CS.CMU.EDU";

grant execute on hostdb.Account_Report_Email 	to ccreport;

--create role ccreport_view;
create role ccreport_admin;
--grant execute	on ccreport.acctexp_rpt		to ccreport_admin;
--grant execute	on ccreport.emailinfo		to ccreport_admin;
--grant select	on ccreport.ccreport_logs	to ccreport_admin;

--grant ccreport_admin to "COSTING@CS.CMU.EDU";
