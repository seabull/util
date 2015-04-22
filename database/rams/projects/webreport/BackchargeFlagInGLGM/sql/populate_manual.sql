set linesize 1000

spool x
--select
--        c.type c_type
--        ,c.account_flag c_account_flag
--        ,c.journal  c_journal
--        --,c.services   c_services
--        ,c.name c_name
--        ,c.id   c_id
--        ,c.notes    c_notes
--        ,g.TYPE       
--        ,g.LIMBO_FLAG 
--        ,g.JID        
--        ,g.ASSETNO    
--        ,g.PRINC      
--        ,g.TRANS_DATE 
--        ,g.POST_DATE  
--        ,g.CHARGE     
--        ,g.PCT        
--        ,g.AMOUNT     
--        ,g.OS         
--        ,g.NAME       
--        ,g.MACH_USER  
--        ,g.MACH_LOC   
--        ,g.FUND       
--        ,g.FUNC       
--        ,g.ACT        
--        ,g.ORG        
--        ,g.ENT        
--        ,g.PROJ       
--        ,g.TASK       
--        ,g.AWARD      
--        ,g.NOTES      
--        ,g.SERVICES   
--  from hostdb.entity_charged_v c
--        ,hostdb.gl_report g
-- where c.account_flag='b'
--   and g.limbo_flag='l'
--   and c.journal=g.jid
--   and c.notes is not null
--   and g.type=c.type
--   and g.name=c.name
--   and decode(proj, null, fund||'-'||func||'-'||act||'-'||org||'-'||ent
--                , proj||'-'||task||'-'||award
--                )=c.acct_string
--   and trunc(g.trans_date)=trunc(c.trans_date)
----   and g.services=c.services
--/

update (
select
        c.type c_type
        ,c.account_flag c_account_flag
        ,c.journal  c_journal
        --,c.services   c_services
        ,c.name c_name
        ,c.id   c_id
        ,c.notes    c_notes
        ,g.rowid
        ,g.TYPE       
        ,g.LIMBO_FLAG 
        ,g.JID        
        ,g.ASSETNO    
        ,g.PRINC      
        ,g.TRANS_DATE 
        ,g.POST_DATE  
        ,g.CHARGE     
        ,g.PCT        
        ,g.AMOUNT     
        ,g.OS         
        ,g.NAME       
        ,g.MACH_USER  
        ,g.MACH_LOC   
        ,g.FUND       
        ,g.FUNC       
        ,g.ACT        
        ,g.ORG        
        ,g.ENT        
        ,g.PROJ       
        ,g.TASK       
        ,g.AWARD      
        ,g.NOTES      
        ,g.SERVICES   
  from hostdb.entity_charged_v c
        ,hostdb.gl_report g
 where c.account_flag='b'
   and g.limbo_flag='l'
   and c.journal=g.jid
   and c.notes is not null
   and g.type=c.type
   and g.name=c.name
   and decode(proj, null, fund||'-'||func||'-'||act||'-'||org||'-'||ent
                , proj||'-'||task||'-'||award
                )=c.acct_string
   and trunc(g.trans_date)=trunc(c.trans_date)
--   and g.services=c.services
)
  set notes=c_notes
        ,limbo_flag=c_account_flag
/

--update hostdb.gl_report g
--   set limbo_flag='b'
-- where limbo_flag='l'
--   and exists (select *
--                 from hostdb.entity_charged_v c
--                where c.account_flag='b'
--                  and c.journal=g.jid
--                  and c.notes is not null
--                  and g.type=c.type
--                  and g.name=c.name
--                  and decode(proj, null, fund||'-'||func||'-'||act||'-'||org||'-'||ent
--                               , proj||'-'||task||'-'||award
--                               )=c.acct_string
--                  and trunc(g.trans_date)=trunc(c.trans_date)
--            )
--/
spool off

set linesize 80

----------
-- TYPE                                                           VARCHAR2(1)
-- LIMBO_FLAG                                                     CHAR(1)
-- JID                                                            NUMBER(5)
-- ASSETNO                                                        VARCHAR2(9)
-- PRINC                                                          VARCHAR2(8)
-- TRANS_DATE                                                     DATE
-- POST_DATE                                                      DATE
-- CHARGE                                                         NUMBER
-- PCT                                                            NUMBER(5,2)
-- AMOUNT                                                         NUMBER
-- OS                                                             VARCHAR2(10)
-- NAME                                                           VARCHAR2(50)
-- MACH_USER                                                      VARCHAR2(50)
-- MACH_LOC                                                       VARCHAR2(30)
-- FUND                                                           VARCHAR2(6)
-- FUNC                                                           VARCHAR2(3)
-- ACT                                                            VARCHAR2(3)
-- ORG                                                            VARCHAR2(6)
-- ENT                                                            VARCHAR2(2)
-- PROJ                                                           VARCHAR2(8)
-- TASK                                                           VARCHAR2(8)
-- AWARD                                                          VARCHAR2(8)
-- NOTES                                                          VARCHAR2(50)
-- SERVICES                                                       VARCHAR2(30)

-- entity_charged_v
-- TYPE                                                           CHAR(1)
-- RECORDED_ID                                                    NUMBER(6)
-- NAME                                                           VARCHAR2(50)
-- ID                                                             VARCHAR2(9)
-- SPONSOR                                                        VARCHAR2(8)
-- CHARGE_SRC                                                     VARCHAR2(3)
-- CHARGE                                                         NUMBER(6,2)
-- PCT                                                            NUMBER(5,2)
-- AMOUNT                                                         NUMBER(6,2)
-- ACCOUNT                                                        NUMBER(6)
-- ACCT_STRING                                                    VARCHAR2(26)
-- ACCT_TYPE                                                      CHAR(2)
-- JOURNAL                                                        NUMBER(5)
-- TRANS_DATE                                                     DATE
-- CATEGORY                                                       VARCHAR2(40)
-- SERVICE_ID                                                     NUMBER(3)
-- WEBCODE                                                        VARCHAR2(3)
-- ACCOUNT_FLAG                                                   CHAR(1)
-- POST_DATE                                                      DATE
-- JOURNAL_TYPE_FLAG                                              VARCHAR2(1)
-- NOTES                                                          VARCHAR2(50)
--
