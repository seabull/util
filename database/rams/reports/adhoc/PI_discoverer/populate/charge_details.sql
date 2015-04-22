
explain plan for
select
	hr.assetno entity_id
	,hr.hostname entity_name
	,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) acct
	,decode(a.project, null, 'M', 'L')
	,a.project
	,a.org
	,hc.account_flag
	,hc.charge
	,hc.pct
	,hc.amount
	,hc.service_id
	,hc.journal
	,hc.trans_date
	,m.charge_by
	,m.dist_src
	,m.usrprinc
	,m.prjprinc
	,c.princ
	,c.qual
	,c.dept
	,hc.notes
  from hostdb.host_charged hc
	,hostdb.host_recorded hr
	,hostdb.accounts a
	,hostdb.capequip c
	,hostdb.machtab m
 where
	hr.id=hc.hr_id
   and hr.assetno=m.assetno
   and hr.assetno=c.assetnum
   and a.id=hc.account
   --and hc.journal=238
/
