create or replace view acl_gm_v
as
select
        pta.*
        ,p.project_role
        ,u.employee_number
        ,u.user_name andrew_uid
        ,u.full_name
        ,u.first_name
        ,u.middle_names
        ,u.last_name
        ,p.start_date_active
        ,p.end_date_active
  from hostdb.pta_status pta
        ,hostdb.acl_users u
        ,hostdb.acl_projects p
 where u.employee_id=p.employee_id
   and p.project_id=pta.project_id
   and p.project_role is not null
/

