--
-- This script grants object privs so that a database user can run the report.
--
grant execute on ccreport.acctexp_rpt to "COSTING@CS.CMU.EDU";
grant execute on ccreport.acctexp_conf to "COSTING@CS.CMU.EDU";

grant select on ccreport.acctexp_logs to "COSTING@CS.CMU.EDU";
grant select on ccreport.acctexp_config to "COSTING@CS.CMU.EDU";
