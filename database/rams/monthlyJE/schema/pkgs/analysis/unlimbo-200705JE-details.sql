--$Id: unlimbo-200705JE-details.sql,v 1.1 2007/07/10 15:27:58 yangl Exp $
set linesize 1000
set colsep ','
column acct_string format a24 trunc
column services format a40 trunc

exec asofv_util.set_time( to_timestamp('01-JUN-2007 08.00.00 PM','DD-MON-YYYY HH.MI.SS PM') , '1');
exec asofv_util.set_time( to_timestamp('02-JUN-2007 01.00.00 AM','DD-MON-YYYY HH.MI.SS AM') , '2');

spool unlimbo-200705JE-fy07limbo-details.csv
prompt ,account_id,Internal ID,
prompt ,since_date,Date went into delinquency state,
prompt ,since_je_id,Journal number of the start delinquency date.
prompt ,report_date,Date reported as delinquent,

prompt ,,
prompt ,Oracle Strings Unlimbo-ed by the new unlimbo process in May 2007 month-end,
prompt ,,
select
        unique
        --x.id account_id
        --,(select acct_string from hostdb.accounts_str_v where id=x.id) acct_string
        --,(select sum(amount) from hostdb.entity_charged_v where account_flag='l' and x.id=account and post_date > to_date('Jul-01-2006', 'Mon-DD-YYYY')) fy07_unresolved_limbo_total
        --,(select '"'||full_name||'"' from hostdb.report_manager_all_v where report_role='Report Manager' and account_id=x.id and full_name!='RAMS CYA' and rownum<2) RptMgr
        --,account_id
        --,since_date
        --,since_je_id
        --,report_date
        --,valid_date
        e.acct_string
        ,e.id asset_or_princ
        ,'"'||e.name||'"' name
        ,e.amount
        ,e.charge
        ,e.post_date
        ,(select '"'||full_name||'"' from hostdb.report_manager_all_v where report_role='Report Manager' and account_id=x.id and full_name!='RAMS CYA' and rownum<2) RptMgr
        ,'"'||services||'"' services
  from --hostdb.delinquent d
        entity_charged_svcsummary_v e
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
        x.id=e.account(+)
   and e.account_flag='l'
   and post_date > to_date('Jul-01-2006', 'Mon-DD-YYYY')
   --and x.id=d.account_id(+)
   --and since_je_id=319
order by e.acct_string
            ,e.id
            ,e.post_date
            ,e.charge
/
spool off
set colsep ' '
