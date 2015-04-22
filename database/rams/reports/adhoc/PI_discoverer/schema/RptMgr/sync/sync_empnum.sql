select
    rp.FULL_NAME
    ,a.employee_number
    ,a.user_name ANDREW_UID
    ,a.LAST_NAME
    ,a.FIRST_NAME
    ,a.MIDDLE_NAME
    ,'N' FLAG
    ,to_date('JAN-01-2008','MON-DD-YYYY') LAST_ACTIVE
    ,to_date('JAN-01-2008','MON-DD-YYYY') CREATION_DATE
  from hostdb.acl_users a
        ,hostdb.report_person rp
 where rp.andrew_username is not null
   and rp.scs_username is null
   and lower(rp.andrew_username) = lower(a.user_name)
   and lower(rp.andrew_username) not in (select lower(andrew_uid) from hostdb.emp_tbl)
/

insert into hostdb.emp_tbl
    (id, full_name, emp_num, andrew_uid
        , last_name, first_name, middle_name
        , flag, last_active, creation_date)
select
        hostdb.empid_seq.nextval
        ,rtrim( upper(rtrim(last_name)) || ', ' || upper(rtrim(first_name)) || ' ' || upper(ltrim(middle_names)) ) full_name
        ,u.employee_number emp_num
        ,lower(u.user_name) andrew_uid
        ,upper(u.last_name) last_name
        ,upper(u.first_name) first_name
        ,upper(u.middle_names) middle_name
        ,'N' flag
        ,to_date('JAN-01-2008', 'MON-DD-YYYY') last_active
        ,to_date('JAN-01-2008', 'MON-DD-YYYY') creation_date
  from hostdb.acl_users u
 where employee_number not in
            (select emp_num from hostdb.emp_tbl)
   and u.user_name in (select andrew_username 
                         from hostdb.report_manager_v 
                        where andrew_username is not null 
                          and scs_username is null)
/

