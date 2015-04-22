--
--  grant select on hostdb.acl_gl_orgs to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.host_charged_summary to "YANGL@CS.CMU.EDU";
--  grant select on hostdb.who_charged_summary to "YANGL@CS.CMU.EDU";
--
-- NOTE: host_charged_summary/who_charged_summary does not have adjustment batch entries!!!!

create materialized view log on hostdb.host_charged_summary 
with sequence, rowid
(hr_id, journal_id, trans_date, account_id, account_flag, pct, notes, charge, amount, services)
including new values
/

create materialized view log on hostdb.who_charged_summary 
with sequence, rowid
(wr_id, journal_id, trans_date, account_id, account_flag, pct, notes, charge, amount, services)
including new values
/

create materialized view log on hostdb.host_recorded 
with sequence, rowid
(id, assetno, hostname, qual, charge_src, prjprinc, usrprinc, princ, project, subproject, os, cpu, location)
including new values
/

create materialized view log on hostdb.who_recorded 
with sequence, rowid
(id, princ, name, sponsor, charge_src, project, subproject)
including new values
/


create materialized view hc_sum_nosvc_mv
pctfree 0
tablespace costing_lg
parallel
build immediate
refresh fast on demand
enable query rewrite
as
select
	hr_id id
	, hr.hostname
	, hcs.account_id
	, sum(hcs.charge) charge
	, hcs.pct
	, sum(hcs.amount) amount
	, hcs.trans_date
	, hcs.journal_id
	, hcs.account_flag
	, count(*) cnt
  from hostdb.host_charged_summary hcs
	,hostdb.host_recorded hr
 where hcs.hr_id = hr.id
group by
	hr_id 
	, hr.hostname
	, hcs.account_id
	, hcs.pct
	, hcs.trans_date
	, hcs.journal_id
	, hcs.account_flag
/

create materialized view wc_sum_nosvc_mv
pctfree 0
tablespace costing_lg
parallel
build immediate
refresh fast on demand
enable query rewrite
as
select
	wr_id id
	, wr.name
	, wcs.account_id
	, sum(wcs.charge)
	, wcs.pct
	, sum(wcs.amount)
	, wcs.trans_date
	, wcs.journal_id
	, wcs.account_flag
	, count(*) cnt
  from hostdb.who_charged_summary wcs
	,hostdb.who_recorded wr
 where wcs.wr_id = wr.id
group by 
	wr_id 
	, wr.name
	, wcs.account_id
	, wcs.pct
	, wcs.trans_date
	, wcs.journal_id
	, wcs.account_flag
/

create view charge_sum_nosvc_v as
select
	id
	,hostname
	,account_id
	,charge
	,pct
	,amount
	,trans_date
	,journal_id
	,account_flag
	,cnt
	,'M'
  from hc_sum_nosvc_mv
union
select
	id
	,name
	,account_id
	,charge
	,pct
	,amount
	,trans_date
	,journal_id
	,account_flag
	,cnt
	,'H'
  from wc_sum_nosvc_mv
/
	
-- This view does not use MVs
create view charge_sum_nosvc as
select
	hr_id id
	, hr.hostname name
	, hcs.account_id
	, sum(hcs.charge) charge
	, hcs.pct
	, sum(hcs.amount) amount
	, hcs.trans_date
	, hcs.journal_id
	, hcs.account_flag
	, 'M' type
  from hostdb.host_charged_summary hcs
	,hostdb.host_recorded hr
 where hcs.hr_id = hr.id
group by
	hr_id 
	, hr.hostname
	, hcs.account_id
	, hcs.pct
	, hcs.trans_date
	, hcs.journal_id
	, hcs.account_flag
/
union
select
	wr_id 
	, wr.name
	, wcs.account_id
	, sum(wcs.charge)
	, wcs.pct
	, sum(wcs.amount)
	, wcs.trans_date
	, wcs.journal_id
	, wcs.account_flag
	, 'U' 
  from hostdb.who_charged_summary wcs
	,hostdb.who_recorded wr
 where wcs.wr_id = wr.id
group by 
	wr_id 
	, wr.name
	, wcs.account_id
	, wcs.pct
	, wcs.trans_date
	, wcs.journal_id
	, wcs.account_flag
/
