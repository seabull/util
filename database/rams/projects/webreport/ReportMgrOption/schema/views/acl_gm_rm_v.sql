-- $Id: acl_gm_rm_v.sql,v 1.4 2006/10/25 19:20:26 yangl Exp $
--
create or replace view acl_gm_rm_v
as
select
	unique
	manager_id
	,admin_id
	,account_string
	,account_id
	,full_name
	,scs_username
	,andrew_username
	,max(project_role)	project_role
	,max(proj_name)		proj_name
	-- should we use nulls for RM's RM?
	,full_name		mgr_full_name
	,scs_username		mgr_scs_username
	,andrew_username	mgr_andrew_username
	--
	,max(rm_start_date)	rm_start_date
	,max(rm_end_date)	rm_end_date
	,admin_start_date
	,admin_end_date
	,max(km_start_date) km_start_date
	,max(km_end_date) km_end_date
  from (
select
	rm.manager_id
	,null admin_id
	,rm.account_string
	,rm.account_id
	,rm.full_name
	,rm.scs_username
	,rm.andrew_username
	,pta.project_role
	,pta.proj_name
	,rm.start_date_active rm_start_date
	,rm.end_date_active rm_end_date
	,null admin_start_date
	,null admin_end_date
	,pta.start_date_active km_start_date
	,pta.end_date_active km_end_date
  from hostdb.report_manager_v rm
	,hostdb.acl_gm_v pta
	--,hostdb.report_person rp
	,hostdb.report_access ra
	--,hostdb.report_suspend rs
 where 
--	rp.id=rm.manager_id
   	rm.account_string=pta.pta(+)
   and rm.andrew_username=pta.andrew_uid(+)
   and ra.person_id(+)=rm.manager_id
)
group by
	manager_id
	,admin_id
	,account_string
	,account_id
	,full_name
	,scs_username
	,andrew_username
	,admin_start_date
	,admin_end_date
/

-- This view does not consider report_access override
--create or replace view acl_gm_rm_v
--as
--select
--	rm.manager_id
--	,null admin_id
--	,rm.account_string
--	,rm.account_id
--	,rp.full_name
--	,rp.scs_username
--	,rp.andrew_username
--	,pta.project_role
--	,pta.proj_name
--	,rm.start_date_active rm_start_date
--	,rm.end_date_active rm_end_date
--	,null admin_start_date
--	,null admin_end_date
--	,pta.start_date_active km_start_date
--	,pta.end_date_active km_end_date
--  from hostdb.report_manager rm
--	,hostdb.acl_gm_v pta
--	,hostdb.report_person rp
--	--,hostdb.report_suspend rs
-- where rp.id=rm.manager_id
----   and rs.report_manager_id=rm.manager_id
--   and rm.account_string=pta.pta
--   and pta.andrew_uid=rp.andrew_username
--/
