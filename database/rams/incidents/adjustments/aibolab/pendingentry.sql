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
spool result.log

prompt all adjustment pending entries for aibol
prompt
select
    *
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
/

select
        sum(amount)
        ,sum(charge)
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
/
select
        sum(amount)
        ,sum(charge)
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
   and amount > 0
/
prompt
prompt adjustment entries w.r.t. aibol for valid PTAs only
prompt

select
    *
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
   and (
            acct_string in ('14013-1b-1040555','14013-1c-1040555')
        or notes like 'Transfer from 14013-1%'
        )
/

select
    sum(amount)
    ,sum(charge)
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
   and (
            acct_string in ('14013-1b-1040555','14013-1c-1040555')
        or notes like 'Transfer from 14013-1%'
        )
/
select
    sum(amount)
    ,sum(charge)
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
   and (
            acct_string in ('14013-1b-1040555','14013-1c-1040555')
        or notes like 'Transfer from 14013-1%'
        )
   and amount > 0
/
select
    sum(amount)
    ,sum(charge)
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
   and acct_string in (
	'13995-1-1040545'
	,'9992-6-1040371'
	,'9992-9-1040492'
    )
/
spool off
set linesize 80
