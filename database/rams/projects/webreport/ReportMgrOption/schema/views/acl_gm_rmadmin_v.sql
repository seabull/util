-- $Id: acl_gm_rmadmin_v.sql,v 1.2 2006/10/25 19:14:07 yangl Exp $
--
create or replace view acl_gm_rmadmin_v
as
select
	ra.manager_id
	,ra.admin_id
	,rm.account_string
	,rm.account_id
	,rp.full_name
	,rp.scs_username
	,rp.andrew_username
	,rm.project_role
	,rm.proj_name
	,rm.full_name		mgr_full_name
	,rm.scs_username	mgr_scs_username
	,rm.andrew_username	mgr_andrew_username
	,rm.rm_start_date	rm_start_date
	,rm.rm_end_date		rm_end_date
	,ra.start_date_active	admin_start_date
	,ra.end_date_active	admin_end_date
	,rm.km_start_date	km_start_date
	,rm.km_end_date		km_end_date
  from 
	acl_gm_rm_v rm
	,hostdb.report_admin ra
	,hostdb.report_person rp
 where rm.manager_id=ra.manager_id
   and rp.id=ra.admin_id
/


--create or replace view acl_gm_rmadmin_v
--as
--select
--	ra.manager_id
--	,ra.admin_id
--	,rm.account_string
--	,rm.account_id
--	,rp.full_name
--	,rp.scs_username
--	,rp.andrew_username
--	,pta.project_role
--	,pta.proj_name
--	,rm.start_date_active rm_start_date
--	,rm.end_date_active rm_end_date
--	,ra.start_date_active admin_start_date
--	,ra.end_date_active admin_end_date
--	,pta.start_date_active km_start_date
--	,pta.end_date_active km_end_date
--  from hostdb.report_manager rm
--	,hostdb.acl_gm_v pta
--	,hostdb.report_admin ra
--	,hostdb.report_person rp
--	--,hostdb.report_suspend rs
-- where rm.manager_id=ra.manager_id
--   and rp.id=ra.admin_id
----   and rs.report_manager_id=rm.manager_id
--   and rm.account_string=pta.pta
--   and pta.andrew_uid=rp.andrew_username
--/
