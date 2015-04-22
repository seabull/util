-- $Id: report_manager_all_v.sql,v 1.4 2007/03/26 18:36:04 yangl Exp $

create view hostdb.report_manager_all_v
as
 -- This view is similar to hostdb.report_manager_v plus report_admin
 -- without considering suspense
 -- similar to acl_gm_notify_v
select
        rm.manager_id person_id
        ,rm.account_string
        ,rm.account_id
        ,rm.start_date_active
        ,rm.end_date_active
        --,rm.suspend_until
        ,rp.scs_username
        ,rp.andrew_username
        ,rp.full_name
        ,'Report Manager'   report_role
  from hostdb.report_manager rm
        ,hostdb.report_person rp
 where rm.manager_id=rp.id
union
select
        ra.admin_id
        ,rm.account_string
        ,rm.account_id
        ,ra.start_date_active
        ,ra.end_date_active
        ,rp.scs_username
        ,rp.andrew_username
        ,rp.full_name
        ,'Report Admin' report_role
  from hostdb.report_manager rm
        ,hostdb.report_person rp
        ,hostdb.report_admin ra
 where rm.manager_id=ra.manager_id
   and ra.admin_id=rp.id
/
