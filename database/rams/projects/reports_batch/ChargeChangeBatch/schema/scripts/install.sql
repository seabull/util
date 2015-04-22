spool README.log
-- run command '@@./install.sql' in sqlplus
-- Remember to run ../../../Emails/types/emails.sql first.

connect / as sysdba
-- @../tablespaces/tblspc_add.sql
@../users/user_add.sql
@./grant_add.sql

connect ccreport/ccreport
@../../../Emails/types/emails.sql
@../pkgs/Error_Codes.sps.sql

prompt str_aggr
@./str_aggr_nodup.sql
@../tables/table_add.sql
@../views/view_add.sql

@../pkgs/histview_utils.sps.sql
@../pkgs/histview_utils.spb.sql
@../pkgs/report.sps.sql
@../pkgs/report.spb.sql
@../pkgs/notify.sps.sql
@../pkgs/notify.spb.sql
@./scc_grant.sql
--@../users/user_passwd.sql

spool off
