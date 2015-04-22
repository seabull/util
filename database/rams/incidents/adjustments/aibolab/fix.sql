set linesize 1000
set pagesize 50000
spool fix.log

prompt pre-fix
prompt
--select 
--        hac.*
--  from hostdb.host_adjust_charge hac
--        ,hostdb.host_recorded hr
-- where hac.hr_id=hr.id
--   and  hostname like 'AIBOLAB%.REL.RI.CMU.EDU'
--/

--select
--        hc.*
--  from hostdb.host_adjust_charge hac
--        ,hostdb.host_charged hc
--        ,hostdb.host_recorded hr
-- where hac.hr_id=hc.hr_id
--   and hac.hr_id=hr.id
--   and hostname like 'AIBOLAB%.REL.RI.CMU.EDU'
--   and hac.service_id=hc.service_id
--   and hac.trans_date=hc.trans_date
--   and abs(hac.amount)=hc.amount
--   and hac.account=hc.account
--   and hac.pct=hc.pct
--   and abs(hac.charge)=hc.charge
--/

-- 
-- get the pending adjustments that have already adjusted (duplicated)
--
select
        hac.*
        ,(select journal_type_flag from hostdb.journals where id=hc.journal) jnl_type
  from hostdb.host_adjust_charge hac
        ,hostdb.host_charged hc
 where hac.hr_id=hc.hr_id
   and hac.trans_date=hc.trans_date
   and hac.amount=hc.amount
   and hac.charge=hc.charge
   and hac.pct=hc.pct
   and hac.notes=hc.notes
   and hac.account=hc.account
/

select
        wac.*
        ,(select journal_type_flag from hostdb.journals where id=wc.journal) jnl_type
  from hostdb.who_adjust_charge wac
        ,hostdb.who_charged wc
 where wac.wr_id=wc.wr_id
   and wac.trans_date=wc.trans_date
   and wac.amount=wc.amount
   and wac.charge=wc.charge
   and wac.pct=wc.pct
   and wac.notes=wc.notes
   and wac.account=wc.account
/

prompt
prompt save duplicated ones
prompt

insert into host_adjust_charge_save
select
        hac.*
  from hostdb.host_adjust_charge hac
        ,hostdb.host_charged hc
 where hac.hr_id=hc.hr_id
   and hac.trans_date=hc.trans_date
   and hac.amount=hc.amount
   and hac.charge=hc.charge
   and hac.pct=hc.pct
   and hac.notes=hc.notes
   and hac.account=hc.account
/


insert into who_adjust_charge_save
select
        wac.*
  from hostdb.who_adjust_charge wac
        ,hostdb.who_charged wc
 where wac.wr_id=wc.wr_id
   and wac.trans_date=wc.trans_date
   and wac.amount=wc.amount
   and wac.charge=wc.charge
   and wac.pct=wc.pct
   and wac.notes=wc.notes
   and wac.account=wc.account
/

prompt
prompt purge duplicated ones
prompt

        --,HPCT             
        --,LIMBO_FLAG       
delete from host_adjust_charge
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
        --,hac.HPCT             
        ,hac.CHARGE           
        ,hac.AMOUNT           
        ,hac.TRANS_DATE       
        ,hac.SERVICE_ID       
        ,hac.ACCOUNT          
        --,hac.JOURNAL         
        ,hac.NOTES            
        ,hac.CREATION_DATE    
        ,hac.CREATED_BY       
        ,hac.LAST_UPDATE_DATE 
        ,hac.LAST_UPDATED_BY  
        ,hac.HOLD_FLAG        
        --,hac.LIMBO_FLAG       
      from hostdb.host_adjust_charge hac
            ,hostdb.host_charged hc
     where hac.hr_id=hc.hr_id
       and hac.trans_date=hc.trans_date
       and hac.amount=hc.amount
       and hac.charge=hc.charge
       and hac.pct=hc.pct
       and hac.notes=hc.notes
       and hac.account=hc.account
)
/


delete from who_adjust_charge
where (
        WR_ID            
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
        ,LIMBO_FLAG      
    ) 
in (
select
        wac.WR_ID            
        ,wac.PCT             
        ,wac.CHARGE          
        ,wac.AMOUNT          
        ,wac.TRANS_DATE      
        ,wac.SERVICE_ID      
        ,wac.ACCOUNT         
        --,wac.JOURNAL         
        ,wac.NOTES           
        ,wac.CREATION_DATE   
        ,wac.CREATED_BY      
        ,wac.LAST_UPDATE_DATE
        ,wac.LAST_UPDATED_BY 
        ,wac.HOLD_FLAG       
        ,wac.LIMBO_FLAG      
  from hostdb.who_adjust_charge wac
        ,hostdb.who_charged wc
 where wac.wr_id=wc.wr_id
   and wac.trans_date=wc.trans_date
   and wac.amount=wc.amount
   and wac.charge=wc.charge
   and wac.pct=wc.pct
   and wac.notes=wc.notes
   and wac.account=wc.account
)
/

spool off
set linesize 80

-- Name                                      Null?    Type
-- ----------------------------------------- -------- ----------------------------
-- HR_ID                                     NOT NULL NUMBER(6)
-- PCT                                       NOT NULL NUMBER(5,2)
-- HPCT                                      NOT NULL NUMBER(5,2)
-- CHARGE                                    NOT NULL NUMBER(6,2)
-- AMOUNT                                    NOT NULL NUMBER(6,2)
-- TRANS_DATE                                NOT NULL DATE
-- SERVICE_ID                                NOT NULL NUMBER(3)
-- ACCOUNT                                   NOT NULL NUMBER(6)
-- JOURNAL                                            NUMBER(3)
-- NOTES                                              VARCHAR2(50)
-- CREATION_DATE                                      DATE
-- CREATED_BY                                         VARCHAR2(50)
-- LAST_UPDATE_DATE                                   DATE
-- LAST_UPDATED_BY                                    VARCHAR2(50)
-- HOLD_FLAG                                          VARCHAR2(1)
-- LIMBO_FLAG                                         VARCHAR2(1)
--
--yangl@cs.cmu.edu@FAC.SUNSPOT.SRV.CS.CMU.EDU> desc hostdb.who_adjust_charge
-- Name                                      Null?    Type
-- ----------------------------------------- -------- ----------------------------
-- WR_ID                                     NOT NULL NUMBER(6)
-- PCT                                       NOT NULL NUMBER(5,2)
-- CHARGE                                    NOT NULL NUMBER(6,2)
-- AMOUNT                                    NOT NULL NUMBER(6,2)
-- TRANS_DATE                                NOT NULL DATE
-- SERVICE_ID                                NOT NULL NUMBER(3)
-- ACCOUNT                                   NOT NULL NUMBER(6)
-- JOURNAL                                            NUMBER(5)
-- NOTES                                              VARCHAR2(50)
-- CREATION_DATE                                      DATE
-- CREATED_BY                                         VARCHAR2(50)
-- LAST_UPDATE_DATE                                   DATE
-- LAST_UPDATED_BY                                    VARCHAR2(50)
-- HOLD_FLAG                                          VARCHAR2(1)
-- LIMBO_FLAG                                         VARCHAR2(1)


