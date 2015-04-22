
set linesize 1000
set colsep ','
column acct_string format a24 trunc
spool unlimbo-200705JE.csv
prompt ,account_id,Internal ID,
prompt ,since_date,Date went into delinquency state,
prompt ,since_je_id,Journal number of the start delinquency date.
prompt ,report_date,Date reported as delinquent,

prompt ,,
prompt ,Oracle Strings Unlimbo-ed by the new unlimbo process in May 2007 month-end,
prompt ,,
select
        unique
        x.id account_id
        ,(select acct_string from hostdb.accounts_str_v where id=x.id) acct_string
        --,account_id
        ,since_date
        ,since_je_id
        ,report_date
        ,valid_date
  from hostdb.delinquent d
        ,(
        select
                id
          from accounts_asofv_1
         where flag='l'
        minus
        select
                id
          from accounts_asofv_2
         where flag='l'
        ) x
 where 
       -- account_id in 
        x.id=d.account_id(+)
   --and since_je_id=319
order by since_je_id
            ,account_id
/
spool off
--select
--        unique 
--        account
--        ,decode(account_flag, 'u','l','l','l','b','l',account_flag) flag
--  from hostdb.host_charged
-- where journal=319
--   and account in
--(
--        select
--                id
--          from accounts_asofv_1
--         where flag='l'
--        minus
--        select
--                id
--          from accounts_asofv_2
--         where flag='l'
--)
--union
--select
--        unique 
--        account
--        ,decode(account_flag, 'u','l','l','l','b','l',account_flag) flag
--  from hostdb.who_charged
-- where journal=319
--   and account in
--(
--        select
--                id
--          from accounts_asofv_1
--         where flag='l'
--        minus
--        select
--                id
--          from accounts_asofv_2
--         where flag='l'
--)
--/
set colsep ' '
