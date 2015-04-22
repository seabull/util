-- $Id: acl_report_manager_v.sql,v 1.1 2006/10/25 19:00:45 yangl Exp $
--
create or replace view acl_report_manager_v
as
select
	*
  from acl_gm_notify_v
/
