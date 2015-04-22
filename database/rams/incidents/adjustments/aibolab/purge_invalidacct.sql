--
-- purge those adjustments from closed oracle strings
-- for aibolab machines
-- 9992-6-1040371
-- 9992-9-1040492
-- 13995-1-1040545
--

set linesize 1000
set pagesize 50000
spool purge_invalidacct.log

column pct format 999.99
column service_id heading svc format 999
column acct_string format a24
column notes format a40

-- save trx
prompt before purge
prompt
select
        hac.*
  from hostdb.host_adjust_charge hac
        ,hostdb.host_recorded hr
 where  hac.hr_id=hr.id
   and hr.hostname like 'AIBOLAB%'
   and (
        account in ( select id 
                      from hostdb.accounts 
                     where project||'-'||task||'-'||award in
                            (
                            '9992-6-1040371'
                            ,'9992-9-1040492'
                            ,'13995-1-1040545'
                            )
                )
    or notes in (
                            'Transfer from 9992-6-1040371'
                            ,'Transfer from 9992-9-1040492'
                            ,'Transfer from 13995-1-1040545'
                )
    )
order by hr_id
        ,trans_date
        ,service_id
        ,pct
        ,account
        ,notes
        ,amount
/

prompt save purge entries
prompt
insert into hostdb.host_adjust_charge_save
select
        hac.*
  from hostdb.host_adjust_charge hac
        ,hostdb.host_recorded hr
 where  hac.hr_id=hr.id
   and hr.hostname like 'AIBOLAB%'
   and (
        account in ( select id 
                      from hostdb.accounts 
                     where project||'-'||task||'-'||award in
                            (
                            '9992-6-1040371'
                            ,'9992-9-1040492'
                            ,'13995-1-1040545'
                            )
                )
    or notes in (
                            'Transfer from 9992-6-1040371'
                            ,'Transfer from 9992-9-1040492'
                            ,'Transfer from 13995-1-1040545'
                )
    )
order by hr_id
        ,trans_date
        ,service_id
        ,pct
        ,account
        ,notes
        ,amount
/

prompt purge entries
prompt
delete from hostdb.host_adjust_charge
where (
        HR_ID            
        ,PCT              
        ,CHARGE           
        ,AMOUNT           
        ,TRANS_DATE       
        ,SERVICE_ID       
        ,ACCOUNT          
        ,NOTES            
        ,CREATION_DATE    
        ,CREATED_BY       
        ,LAST_UPDATE_DATE 
        ,LAST_UPDATED_BY  
        ,HOLD_FLAG        
    )
    in (
select
        hac.HR_ID            
        ,hac.PCT              
        ,hac.CHARGE           
        ,hac.AMOUNT           
        ,hac.TRANS_DATE       
        ,hac.SERVICE_ID       
        ,hac.ACCOUNT          
        ,hac.NOTES            
        ,hac.CREATION_DATE    
        ,hac.CREATED_BY       
        ,hac.LAST_UPDATE_DATE 
        ,hac.LAST_UPDATED_BY  
        ,hac.HOLD_FLAG        
  from hostdb.host_adjust_charge hac
        ,hostdb.host_recorded hr
 where  hac.hr_id=hr.id
   and hr.hostname like 'AIBOLAB%'
   and (
        account in ( select id 
                      from hostdb.accounts 
                     where project||'-'||task||'-'||award in
                            (
                            '9992-6-1040371'
                            ,'9992-9-1040492'
                            ,'13995-1-1040545'
                            )
                )
    or notes in (
                            'Transfer from 9992-6-1040371'
                            ,'Transfer from 9992-9-1040492'
                            ,'Transfer from 13995-1-1040545'
                )
    )
)
/

prompt check purged entries (should be none)
prompt
select
        hac.*
  from hostdb.host_adjust_charge hac
        ,hostdb.host_recorded hr
 where  hac.hr_id=hr.id
   and hr.hostname like 'AIBOLAB%'
   and (
        account in ( select id 
                      from hostdb.accounts 
                     where project||'-'||task||'-'||award in
                            (
                            '9992-6-1040371'
                            ,'9992-9-1040492'
                            ,'13995-1-1040545'
                            )
                )
    or notes in (
                            'Transfer from 9992-6-1040371'
                            ,'Transfer from 9992-9-1040492'
                            ,'Transfer from 13995-1-1040545'
                )
    )
order by hr_id
        ,trans_date
        ,service_id
        ,pct
        ,account
        ,notes
        ,amount
/
spool off
set linesize 80
