-- $Id: hc_service_aggr.sql,v 1.1 2005/07/06 04:26:59 yangl Exp $
--
-- use table aggregate table hc_by_services, which has distribution (acct@pct, acct@pct)
-- aggregated, and aggregate services all together by hr_id
--
-- related script: hc_by_services.sql
--
set termout off
set heading off
set linesize 320
set feedback on
spool hc_service_aggr.lst
select
	'id'
	||'|'||'hostname'
	||'|'||'assetno'
	||'|'||'dist_vec'
	||'|'||'account_flag'
	||'|'||'services'
	||'|'||'journal'
	||'|'||'prjprinc'
	||'|'||'project'
	||'|'||'subproject'
	||'|'||'charge_by'
	||'|'||'dist_src'
  from  dual
/
select
	id
	||'|'||hostname
	||'|'||assetno
	||'|'||dist_vec
	||'|'||account_flag
	||'|'||services
	||'|'||journal
	||'|'||prjprinc
	||'|'||project
	||'|'||subproject
	||'|'||charge_by
	||'|'||dist_src
  from 
(	
select
	x.id
	,hr.hostname
	,hr.assetno
	,dist_vec
	,x.account_flag
	,x.services
	,x.journal
	,hr.prjprinc
	,hr.project
	,hr.subproject
	,m.charge_by
	,m.dist_src
  from 
	hostdb.host_recorded hr
	,hostdb.machtab m
,(
select
	hbs.id
	,hbs.dist_vec
	,hbs.account_flag
	,stragg(s.category) services
	,hbs.journal 
  from hc_by_services hbs
	, hostdb.services s
 where hbs.service_id=s.id
group by 
	hbs.id
	,hbs.dist_vec
	,hbs.account_flag
	,hbs.journal 
) x
 where hr.id=x.id
   and hr.assetno=m.assetno(+)
)
/
spool off
set termout on
set heading on
set linesize 80
set feedback on
