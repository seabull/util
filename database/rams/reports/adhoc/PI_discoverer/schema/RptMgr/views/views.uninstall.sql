-- $Id: views.uninstall.sql,v 1.6 2007/03/22 17:43:51 yangl Exp $

drop view hostdb.report_manager_all_v;
drop view hostdb.report_manager_all_info_v;
drop view hostdb.entity_charged_v;
drop view hostdb.entity_charged_svcsummary_v;
--drop materialized view hostdb.entity_charged_svcsum_y2d_mv;
drop view pireport.acct_role_valid_v;
drop view pireport.charges_distvec_v;
