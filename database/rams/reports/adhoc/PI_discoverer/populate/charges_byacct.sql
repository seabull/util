--
--  grant select on hostdb.acl_gl_orgs to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.host_charged_summary to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.who_charged_summary to "YANGL@CS.CMU.EDU";

-- candidate for materialized view
--
insert into charges
--( ENTITY_ID, NAME, TYPE, ACCT_ID, CHARGE, PCT, AMOUNT, TRANS_DATE, JNL_ID, ACCOUNT_FLAG)
( NID, ENTITY_ID, NAME, TYPE, ACCT_ID, CHARGE, PCT, AMOUNT, TRANS_DATE, JNL_ID, ACCOUNT_FLAG)
(
select
	charges_idseq.nextval,
	x.*
  from
(
	select
		unique
		hr_id
		, hr.hostname
		, 'M'
		, hcs.account
		, sum(hcs.charge)
		, hcs.pct
		, sum(hcs.amount)
		, hcs.trans_date
		, hcs.journal
		, nvl(hcs.account_flag,'v')
	  --from hostdb.host_charged_summary hcs
	  from hostdb.host_charged hcs
		,hostdb.host_recorded hr
	 where hcs.hr_id = hr.id
	   and hcs.journal>237
	group by hr_id
		, hr.hostname
		, 'M'
		, hcs.account
		, hcs.pct
		, hcs.trans_date
		, hcs.journal
		, hcs.account_flag
	union
	select
		unique
		wr_id
		, wr.name
		, 'U'
		, wcs.account
		, sum(wcs.charge)
		, wcs.pct
		, sum(wcs.amount)
		, wcs.trans_date
		, wcs.journal
		, nvl(wcs.account_flag,'v')
	  from hostdb.who_charged wcs
		,hostdb.who_recorded wr
	 where wcs.wr_id = wr.id
	   and wcs.journal>237
	group by wr_id
		, wr.name
		, 'U'
		, wcs.account
		, wcs.pct
		, wcs.trans_date
		, wcs.journal
		, wcs.account_flag
) x
)
/


