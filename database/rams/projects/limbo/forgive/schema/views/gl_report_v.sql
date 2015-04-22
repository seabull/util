create or replace view hostdb.glreport_entity_charged_v
as
select
	'M' Type
	,hc.hr_id Recorded_ID
	,hr.hostname Name
	,hr.assetno ID
	,hr.usrprinc sponsor
	,hr.prjprinc prjcontact
	,hr.princ equipcontact
	,hr.charge_src
    ,hr.location
    ,hr.os
	,hc.charge
	,hc.pct
	,hc.amount
	,hc.account
	,a.acct_string
	,a.acct_type
    ,a.funding
    ,a.function
    ,a.activity
    ,a.org
    ,a.entity
    ,a.project
    ,a.task
    ,a.award
	,hc.journal
	,hc.trans_date
	,s.category
	,hc.service_id
	,s.webcode
	,hc.account_flag
	,j.post_date
	,j.journal_type_flag
	,hc.notes
  from hostdb.host_charged hc
	,hostdb.host_recorded hr
	,accounts_str_v a
	,hostdb.journals j
	,hostdb.services s
 where hc.hr_id=hr.id
   and hc.account=a.id
   and s.id=hc.service_id
   and j.id=hc.journal
   and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6-12*5), 'YYYY'), 'MON-DD-YYYY')
union
select
	'U' Type
	,wc.wr_id Recorded_ID
	,wr.name Name
	,wr.princ ID
	,wr.sponsor
	,null prjcontact
	,null equipcontact
	,wr.charge_src
    ,null location
    ,null os
	,wc.charge
	,wc.pct
	,wc.amount
	,wc.account
	,a.acct_string
	,a.acct_type
    ,a.funding
    ,a.function
    ,a.activity
    ,a.org
    ,a.entity
    ,a.project
    ,a.task
    ,a.award
	,wc.journal
	,wc.trans_date
	,s.category
	,wc.service_id
	,s.webcode
	,wc.account_flag
	,j.post_date
	,j.journal_type_flag
	,wc.notes
  from hostdb.who_charged wc
	,hostdb.who_recorded wr
	,accounts_str_v a
	,hostdb.journals j
	,hostdb.services s
 where wc.wr_id=wr.id
   and wc.account=a.id
   and s.id=wc.service_id
   and j.id=wc.journal
   and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6-12*5), 'YYYY'), 'MON-DD-YYYY')
/

create or replace view hostdb.glreport_svcsummary_v
as
select
        journal_type_flag Type
        ,recorded_id
        ,account_flag limbo_flag
        ,journal jid
        ,ID
        ,trans_date
        ,post_date
        ,charge
        ,pct
        ,amount
        ,services
        ,OS
        ,name
        ,nvl(sponsor, nvl(prjcontact, equipcontact)) mach_user
        ,location mach_loc
        ,funding fund
        ,function func
        ,activity act
        ,org
        ,entity ent
        ,project proj
        ,task
        ,award
        ,notes
        ,acct_string
        ,account account_id
  from (
	select
		Type
		,Recorded_ID
		,Name
		,ID
		,sponsor
        ,prjcontact
        ,equipcontact
        ,location
		,charge_src
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
			sum(c.charge) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
							order by c.webcode
						rows between unbounded preceding and unbounded following)
		end Charge
		,pct
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
			sum(c.amount) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
							order by c.webcode
						rows between unbounded preceding and unbounded following)
		end amount
		,account
		,acct_string
		,acct_type
		,journal
		,trans_date
		--,category
		--,service_id
		--,webcode
		,account_flag
		,post_date
		,journal_type_flag
		,notes
        ,os
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
	                                stragg_nodup(c.webcode) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
	                                                        order by c.webcode
	                                                rows between unbounded preceding and unbounded following)
		end services
		,case when row_number() over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag order by c.webcode)=1 then
	                                stragg(c.category) over (partition by c.type, c.recorded_id, c.journal, c.account, c.trans_date, c.pct, c.account_flag
	                                                        order by c.webcode
	                                                rows between unbounded preceding and unbounded following)
		end service_categories
        ,funding
        ,function
        ,activity
        ,org
        ,entity
        ,project
        ,task
        ,award
	  from hostdb.glreport_entity_charged_v c
	) x
 where x.services is not null
/

create materialized view hostdb.glreport_mv
tablespace costing_lg
build immediate
refresh on demand
disable query rewrite
as
select
    *
  from hostdb.glreport_svcsummary_v
/

create index hostdb.glreportmvpta_idx on hostdb.glreport_mv (proj, task, award)
tablespace indx nologging
/


--select
--        Type
--        ,recorded_id
--        ,account_flag limbo_flag
--        ,journal jid
--        ,ID
--        ,trans_date
--        ,post_date
--        ,charge
--        ,pct
--        ,amount
--        ,services
--        ,OS
--        ,name
--        ,mach_user
--        ,mach_loc
--        ,fund
--        ,func
--        ,act
--        ,org
--        ,ent
--        ,proj
--        ,task
--        ,award
--        ,notes
--        ,acct_string
--        ,account_id
--  from hostdb.entity_charged_svcsummary_v

--entity_charged_svcsummary
-- TYPE                                                           CHAR(1)
-- RECORDED_ID                                                    NUMBER(6)
-- NAME                                                           VARCHAR2(50)
-- ID                                                             VARCHAR2(9)
-- SPONSOR                                                        VARCHAR2(8)
-- CHARGE_SRC                                                     VARCHAR2(3)
-- CHARGE                                                         NUMBER
-- PCT                                                            NUMBER(5,2)
-- AMOUNT                                                         NUMBER
-- ACCOUNT                                                        NUMBER(6)
-- ACCT_STRING                                                    VARCHAR2(26)
-- ACCT_TYPE                                                      CHAR(2)
-- JOURNAL                                                        NUMBER(5)
-- TRANS_DATE                                                     DATE
-- ACCOUNT_FLAG                                                   CHAR(1)
-- POST_DATE                                                      DATE
-- JOURNAL_TYPE_FLAG                                              VARCHAR2(1)
-- NOTES                                                          VARCHAR2(50)
-- SERVICES                                                       VARCHAR2(4000)
-- SERVICE_CATEGORIES                                             VARCHAR2(4000)

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

