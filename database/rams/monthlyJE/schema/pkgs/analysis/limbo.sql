
set linesize 1000
column acct_string format a24 trunc
column amt format 99999.99
set colsep ','
spool limbo.log
select
        unique 
        acct_string
        ,post_date
        ,account_flag
        ,amt
        ,(select '"'||FULL_NAME||'"' from hostdb.report_manager_all_v where ACCOUNT_ID=account and report_role='Report Manager' and full_name!='RAMS CYA' and rownum<2) RptMgr
  from 
(
    select
            unique
            ACCT_STRING
            ,account
            ,POST_DATE
            ,account_flag
            ,sum(amount) amt
      from entity_charged_v e
     where journal=313
       and account_flag in ('l','b')
    group by acct_string
            ,account
            ,post_date
            ,account_flag
) x
/
spool off
set linesize 80
set colsep ' '
