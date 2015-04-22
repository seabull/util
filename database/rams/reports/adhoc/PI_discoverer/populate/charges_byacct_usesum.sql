--
--  grant select on hostdb.acl_gl_orgs to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.host_charged_summary to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.who_charged_summary to "YANGL@CS.CMU.EDU";

-- candidate for materialized view
--
insert into charges
( ENTITY_ID, NAME, TYPE, ACCT_ID, CHARGE, PCT, AMOUNT, TRANS_DATE, JNL_ID, ACCOUNT_FLAG)
(
select
	hr_id
	, hr.hostname
	, 'M'
	, hcs.account_id
	, sum(hcs.charge)
	, hcs.pct
	, sum(hcs.amount)
	, hcs.trans_date
	, hcs.journal_id
	, nvl(hcs.account_flag,'v')
  from hostdb.host_charged_summary hcs
	,hostdb.host_recorded hr
 where hcs.hr_id = hr.id
   and hcs.journal_id>237
group by hr_id
	, hr.hostname
	, 'M'
	, hcs.account_id
	, hcs.pct
	, hcs.trans_date
	, hcs.journal_id
	, hcs.account_flag
union
select
	wr_id
	, wr.name
	, 'U'
	, wcs.account_id
	, sum(wcs.charge)
	, wcs.pct
	, sum(wcs.amount)
	, wcs.trans_date
	, wcs.journal_id
	, nvl(wcs.account_flag,'v')
  from hostdb.who_charged_summary wcs
	,hostdb.who_recorded wr
 where wcs.wr_id = wr.id
   and wcs.journal_id>237
group by wr_id
	, wr.name
	, 'M'
	, wcs.account_id
	, wcs.pct
	, wcs.trans_date
	, wcs.journal_id
	, wcs.account_flag
)
/


