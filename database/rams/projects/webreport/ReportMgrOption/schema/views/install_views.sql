-- $Id: install_views.sql,v 1.3 2006/11/01 19:48:11 yangl Exp $
-- usage:
--	@views/install_views.sql
--

-- assuming connect as hostdb
--@become hostdb

-- make sure acl_gm_v exists, if not, use the following to create it.
-- @@acl_gm_v.sql

@@acl_gm_rm_v.sql
@@acl_gm_rmadmin_v.sql
@@acl_gm_notify_v.sql
@@acl_report_manager_v.sql

grant select on acl_gm_rm_v		to web_view;
grant select on acl_gm_rmadmin_v	to web_view;
grant select on acl_gm_notify_v		to web_view;
grant select on acl_report_manager_v	to web_view;

