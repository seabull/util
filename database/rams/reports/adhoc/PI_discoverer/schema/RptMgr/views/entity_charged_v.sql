-- $Id: entity_charged_v.sql,v 1.2 2006/12/06 21:53:16 yangl Exp $

create view hostdb.entity_charged_v
as
select
	'M' Type
	,hc.hr_id Recorded_ID
	,hr.hostname Name
	,hr.assetno ID
	,hr.usrprinc sponsor
	,hr.charge_src
	,hc.charge
	,hc.pct
	,hc.amount
	,hc.account
	,a.acct_string
	,a.acct_type
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
union
select
	'U' Type
	,wc.wr_id Recorded_ID
	,wr.name Name
	,wr.princ ID
	,wr.sponsor
	,wr.charge_src
	,wc.charge
	,wc.pct
	,wc.amount
	,wc.account
	,a.acct_string
	,a.acct_type
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
/

