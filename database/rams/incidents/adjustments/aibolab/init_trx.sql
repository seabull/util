--select 
--	pta
--	, PROJ_NAME
--	, PROJ_START_DATE
--	, PROJ_COMPLETION_DATE
--	, PROJ_CLOSED_DATE
--	, PROJ_STATUS_CODE
--	, AWARD_START_DATE_ACTIVE
--	, AWARD_END_DATE_ACTIVE
--	, AWARD_CLOSED_DATE
--	, AWARD_STATUS
--  from hostdb.pta_status
-- where pta in (
--	'13995-1-1040545'
--	,'14013-1b-1040555'
--	,'14013-1c-1040555'
--	,'9992-6-1040371'
--	,'9992-9-1040492'
--	)
--/

set linesize 1000
set pagesize 50000
--set colsep ','
spool init_trx.log

column name format a24
column recorded_id heading hr_id
column pct format 999.99
column service_id heading svc format 999
column acct_string format a24
column notes format a40
column journal_type_flag format a2
break on trans_date skip 1

select
        name
        ,trans_date
        ,decode(journal_type_flag, 'M','M','A','MA','X') journal_type_flag
        ,amount
        ,charge
        ,acct_string
        ,notes
        ,account_flag
        ,service_id
        ,post_date
        ,pct
        ,id
        ,recorded_id
  from entity_charged_v
 where journal > 236
   and (recorded_id, trans_date) in (
                        select hr_id, trans_date
                          from hostdb.host_adjust_charge hac
                                ,hostdb.host_recorded hr
                         where hac.hr_id=hr.id
                           and hostname like 'AIBOL%'
                        )
union
select
        name
        ,trans_date
        ,'P'
        ,amount
        ,charge
        ,acct_string
        ,notes
        ,null
        ,service_id
        ,sysdate
        ,pct
        ,id
        ,recorded_id
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
order by 
            name
            ,trans_date
            ,3
            ,pct
            ,service_id
            ,acct_string
/
            --,decode(journal_type_flag, 'M','M','A','MA','X') 

spool off
set colsep ' '
set linesize 80
