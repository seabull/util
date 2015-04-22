spool README.log

connect / as sysdba
drop user ccreport cascade;
-- @./tblspc_add.sql
@./user_add.sql
@./grant_add.sql

connect ccreport/ccreport
@./Error_Codes.sps.sql

prompt str_aggr
@./str_aggr_nodup.sql
@./table_add.sql
@./view_add.sql

@./histview_utils.sps.sql
@./histview_utils.spb.sql
@./report.sps.sql
@./report.spb.sql
@./notify.sps.sql
@./notify.spb.sql
--@./user_passwd.sql

spool off
