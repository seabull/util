--select
--	*
--  from hostdb.pta_status
-- where pta in (
--	'13995-1-1040545'
--	,'14013-1b-1040555'
--	,'14013-1c-1040555'
--	,'9992-6-1040371'
--	,'9992-9-1040492'
--	)
--/

select 
	pta
	, PROJ_NAME
	, PROJ_START_DATE
	, PROJ_COMPLETION_DATE
	, PROJ_CLOSED_DATE
	, PROJ_STATUS_CODE
	, AWARD_START_DATE_ACTIVE
	, AWARD_END_DATE_ACTIVE
	, AWARD_CLOSED_DATE
	, AWARD_STATUS
  from hostdb.pta_status
 where pta in (
	'13995-1-1040545'
	,'14013-1b-1040555'
	,'14013-1c-1040555'
	,'9992-6-1040371'
	,'9992-9-1040492'
	)
/

select
	unique 
	acct_string
	,notes
  from hostdb.entity_adjust_pending_v
 where name like 'AIBOL%'
/
