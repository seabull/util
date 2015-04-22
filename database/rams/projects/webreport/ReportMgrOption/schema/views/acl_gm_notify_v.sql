-- $Id: acl_gm_notify_v.sql,v 1.1 2006/10/25 19:00:45 yangl Exp $
--
create or replace view acl_gm_notify_v
as
select
	*
  from acl_gm_rm_v rm
 where rm_start_date <= sysdate
   and rm_end_date >= sysdate
union
select
	*
  from acl_gm_rmadmin_v ra
 where rm_start_date <= sysdate
   and rm_end_date >= sysdate
   and admin_start_date <= sysdate
   and admin_end_date >= sysdate
/
