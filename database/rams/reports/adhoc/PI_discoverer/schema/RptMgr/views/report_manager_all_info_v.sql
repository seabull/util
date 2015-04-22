-- $Id: report_manager_all_info_v.sql,v 1.5 2008/09/27 17:14:04 yangl Exp $

create or replace view hostdb.report_manager_all_info_v
as
select
        unique
        person_id
        ,account_string
        ,account_id
        ,start_date_active
        ,end_date_active
        ,scs_username
        ,andrew_username
        ,full_name
        ,report_role
        ,nvl(emp_num, emp_num2) emp_num
  from
(
    select
            rm.*
            ,n.emp_num
            ,(select emp_num from hostdb.emp_tbl e where upper(rm.andrew_username) = upper(e.andrew_uid)) emp_num2
      from hostdb.report_manager_all_v rm
           -- ,(select princ, name, emp_num
           --     from hostdb.name n
           --         ,hostdb.principal p
           --    where n.princ = p.name
           -- ) x
     left join hostdb.name n
            on lower(rm.scs_username) = lower(n.princ)
           and n.pri=0
)
/
