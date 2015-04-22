-- $Id: views.install.sql,v 1.8 2007/03/22 17:43:51 yangl Exp $

@@report_manager_all_v.sql
@@report_manager_all_info_v.sql
@@entity_charged_v.sql
@@entity_charged_svcsummary_v.sql
@@acct_role_valid_v.sql
@@charges_distvec_v.sql

grant select on hostdb.report_manager_all_v         to pireport;
grant select on hostdb.report_manager_all_info_v    to pireport;
grant select on hostdb.entity_charged_v             to pireport;
grant select on hostdb.entity_charged_svcsummary_v  to pireport;
--grant select on hostdb.entity_charged_svcsum_y2d_mv to pireport;
