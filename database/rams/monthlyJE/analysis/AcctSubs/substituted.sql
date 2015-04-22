
spool substituted.log
--select
--        max(src_account)
--        ,max(dst_account)
--  from hostdb.account_subs
--/
--
set linesize 1000

column src_account format a28 trunc
column dst_account format a28 trunc
column name format a28 trunc

set colsep ','
select
        *
  from
(
select
        unique
        lr.period_last
        ,lr.PRINC      
        ,'"'||lr.NAME||'"' Name
        ,lr.EXPORG     
        --,lr.EXPTYPE    
        ,lr.OBJCODE    
        ,lr.PCT_ORIG   
        ,lr.PCT_NORM   
        ,lr.PERIOD     
        ,lr.HOME_ORG   
        ,lr.APPOINTMENT
        ,lr.CHARGE_SRC 
        ,lr.ACCOUNT    
        ,(select acct_string from hostdb.accounts_str_v where id=src_account) src_account
        ,(select acct_string from hostdb.accounts_str_v where id=dst_account) dst_account
  from hostdb.account_subs a
        ,hostdb.labor_recorded lr
 where 
        (a.princ=lr.princ or a.princ is null)
   --and lr.period_last > sysdate -30
   and a.src_account is not null
   and a.dst_account is not null
   and lr.account=a.src_account
union
select
        unique
        lr.period_last
        ,lr.PRINC      
        ,'"'||lr.LNAME||','||lr.FNAME||'"' Name
        ,lr.EXP_ORG EXPORG     
        --,lr.EXPTYPE    
        ,lr.TRCODE OBJCODE    
        ,lr.HOURS PCT_ORIG   
        ,lr.pct PCT_NORM   
        ,lr.paydate PERIOD     
        ,lr.HOME_ORG   
        ,lr.APPOINTMENT
        ,lr.CHARGE_SRC 
        ,lr.ACCOUNT    
        ,(select acct_string from hostdb.accounts_str_v where id=src_account) src_account
        ,(select acct_string from hostdb.accounts_str_v where id=dst_account) dst_account
  from hostdb.account_subs a
        ,hostdb.tmcd_recorded lr
 where 
        (a.princ=lr.princ or a.princ is null)
   --and lr.period_last > sysdate -30
   and a.src_account is not null
   and a.dst_account is not null
   and lr.account=a.src_account
)
order by period_last
        ,account
/
spool off

set linesize 80
set colsep ' '

-- PERIOD_LAST                                           NOT NULL DATE
-- PRINC                                                          VARCHAR2(8)
-- NAME                                                  NOT NULL VARCHAR2(50)
-- EXPORG                                                         VARCHAR2(60)
-- EXPTYPE                                                        VARCHAR2(60)
-- OBJCODE                                                        VARCHAR2(5)
-- ACCOUNT                                               NOT NULL NUMBER(6)
-- PCT_ORIG                                              NOT NULL NUMBER(5,2)
-- PCT_NORM                                              NOT NULL NUMBER(5,2)
-- PERIOD                                                NOT NULL DATE
-- HOME_ORG                                              NOT NULL VARCHAR2(60)
-- APPOINTMENT                                           NOT NULL NUMBER(7)
-- CHARGE_SRC                                            NOT NULL VARCHAR2(3)
--
--yangl@cs.cmu.edu@FAC.SUNSPOT> desc hostdb.tmcd_recorded
-- Name                                                  Null?    Type
-- ----------------------------------------------------- -------- ------------------------------------
-- PERIOD_LAST                                           NOT NULL DATE
-- PRINC                                                          VARCHAR2(8)
-- PCT                                                            NUMBER(5,2)
-- CHARGE_SRC                                            NOT NULL VARCHAR2(3)
-- TRCODE                                                NOT NULL VARCHAR2(2)
-- SSN                                                            NUMBER(9)
-- LNAME                                                 NOT NULL VARCHAR2(21)
-- FNAME                                                          VARCHAR2(16)
-- HOURS                                                 NOT NULL NUMBER(6,2)
-- HOURS_OT                                              NOT NULL NUMBER(6,2)
-- HED                                                   NOT NULL VARCHAR2(2)
-- PAYDATE                                               NOT NULL DATE
-- HOME_ORG                                              NOT NULL VARCHAR2(6)
-- KIND                                                  NOT NULL VARCHAR2(4)
-- BATCH                                                 NOT NULL DATE
-- ACCOUNT                                               NOT NULL NUMBER(6)
-- EXP_ORG                                                        VARCHAR2(6)
-- APPOINTMENT                                                    NUMBER(7)

