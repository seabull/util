-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/tables/table_drop.sql,v 1.3 2006/07/13 18:02:20 yangl Exp $

drop index acctexpfact_logid_idx
/
drop index acctexpfact_logidreason_idx 
/

drop sequence ccreport.acctexp_logs_seq
/

drop sequence ccreport.acctexp_config_idseq
/

drop table ccreport.acctexp_logs
/

drop sequence ccreport.acctexpfact_seq
/

drop table ccreport.acctexp_fact
/

drop table ccreport.acctexp_reasoncodes
/

drop table ccreport.acctexp_config
/

