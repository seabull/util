set termout off
set linesize 300
set heading off
--set feedback off
spool result/mach-200505.csv
	-- ||','||s.service_code
select 
	'assetno'
	||','||'hostname'
	||','||'journal'
	||','||'journal_type_flag'
	||','||'post_date'
	||','||'acct'
	||','||'acct_flag'
	||','||'unit_charge'
	||','||'pct'
	||','||'charge_amount'
	||','||'abbrev'
	||','||'service_id'
	||','||'detail_category'
	||','||'category'
	||','||'os_class'
	||','||'post_mon'
	||','||'post_year'
	||','||'trans_date'
	||','||'trans_mon'
	||','||'trans_year'
	||','||'dept_name'
	||','||'service_type'
  from dual
/
select
	hr.assetno
	||','||hr.hostname
	||','||hc.journal
	||','||j.journal_type_flag
	||','||to_char(j.post_date, 'YYYY-MON-DD')
	||','||account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)
	||','||decode(hc.account_flag, NULL, 'valid', 'i', 'Internal','I','Internal','l','Limbo','L','Limbo','Unknown')
	||','||hc.charge
	||','||hc.pct
	||','||hc.amount
	||','||d.abbrev
	||','||hc.service_id
	||','||s.category
	||','||s.type||'-'||decode(s.attr2, null, decode(s.attr, null, s.subtype||s.other, s.attr), s.attr2) 
	||','||s.os_class
	||','||to_char(j.post_date, 'MON')
	||','||to_char(j.post_date, 'YYYY')
	||','||to_char(hc.trans_date, 'YYYY-MON-DD')
	||','||to_char(hc.trans_date, 'MON')
	||','||to_char(hc.trans_date, 'YYYY')
	||','||d.name
	||','||s.type
  from hostdb.host_charged hc
	, hostdb.capequip c
	, hostdb.host_recorded hr
	, hostdb.services s
	, hostdb.journals j
	, hostdb.accounts a
	, hostdb.depts d
 where 
	hc.hr_id=hr.id
	and hc.service_id=s.id
	and hc.journal=j.id
	and hc.account=a.id
	and hr.assetno=c.assetnum
	and nvl(c.dept,'05005')=d.numb
	and j.id=233
/
	--and j.id>222
	--and j.id<228
	-- and j.post_date > last_day(add_months(sysdate, -1))-1
	-- and j.post_date > to_date(concat('01-JUL-',to_char(add_months(sysdate, -6),'YYYY')),'DD-MON-YYYY')
spool off

--/*
--set termout on
--set feedback on
spool result/user-200505.csv
select 
	'princ'
	||','||'name'
	||','||'journal'
	||','||'journal_type_flag'
	||','||'post_date'
	||','||'acct'
	||','||'acct_flag'
	||','||'unit_charge'
	||','||'pct'
	||','||'charge_amount'
	||','||'abbrev'
	||','||'service_id'
	||','||'detail_category'
	||','||'category'
	||','||'os_class'
	||','||'post_mon'
	||','||'post_year'
	||','||'trans_date'
	||','||'trans_mon'
	||','||'trans_year'
	||','||'dept_name'
	||','||'service_type'
	||','||'sponsor_princ'
  from dual
/
select 
	n.princ
	||','||n.name
	||','||wc.journal
	||','||j.journal_type_flag
	||','||to_char(j.post_date, 'YYYY-MON-DD')
	||','||account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null)
	||','||decode(wc.account_flag, NULL, 'valid', 'i', 'Internal','I','Internal','l','Limbo','L','Limbo','Unknown')
	||','||wc.charge
	||','||wc.pct
	||','||wc.amount
	||','||d.abbrev
	||','||wc.service_id
	||','||s.category
	||','||s.type||'-'||decode(s.attr2, null, decode(s.attr, null, s.subtype||s.other, s.attr), s.attr2) 
	||','||nvl(s.os_class,'unknown')
	||','||to_char(j.post_date, 'MON')
	||','||to_char(j.post_date, 'YYYY')
	||','||to_char(wc.trans_date, 'YYYY-MON-DD')
	||','||to_char(wc.trans_date, 'MON')
	||','||to_char(wc.trans_date, 'YYYY')
	||','||d.name
	||','||s.type
	||','||nvl(w.sponsor, 'Unknown')
  from 
	hostdb.who_charged wc
	, hostdb.who_recorded wr
	, hostdb.name n
	, hostdb.who w
	, hostdb.services s
	, hostdb.journals j
	, hostdb.accounts a
	, hostdb.depts d
 where
	wc.wr_id=wr.id
   and wr.princ=n.princ
   and n.pri=0
   and n.princ=w.princ
   and s.id=wc.service_id
   and d.numb=decode(rtrim(w.dept),null,'05005','eng','05402','math','05006','me','05108','phil','05404','psych','05405','sei-a','05801',w.dept)
   and wc.journal=j.id
   and wc.account=a.id
   and j.id=233
/
   --and j.id>222
   --and j.id<228
   --and w.dept not like '0%'
   --and w.dept is not null
spool off
--*/

/*
select decode(attr2, null, decode(attr, null, subtype||other, attr), attr2) from services where type='M';

*/
set termout on
set heading on
set feedback on
