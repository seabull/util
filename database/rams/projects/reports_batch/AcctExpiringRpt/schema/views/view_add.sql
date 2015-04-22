-- $Header: c:\\Repository/database/rams/projects/reports_batch/AcctExpiringRpt/schema/views/view_add.sql,v 1.4 2006/08/24 19:42:57 yangl Exp $

--create or replace view ccreport.pta_recorded_hist_v
--as
--select	
--	pta
--	,flag
--	,last_active 
--	,creation_date
--	,project_id
--	,proj_name
--	,project_number
--	,proj_start_date
--	,proj_completion_date
--	,proj_closed_date
--	,proj_status_code
--	,task_number
--	,task_completion_date
--	,task_charge_flag
--	,award_number
--	,award_name
--	,award_start_date_active
--	,award_end_date_active
--	,award_closed_date
--	,award_status
--  from (
--	select
--	  	pta
--		,flag
--		,last_active 
--		,creation_date
--		,project_id
--		,proj_name
--		,project_number
--		,proj_start_date
--		,proj_completion_date
--		,proj_closed_date
--		,proj_status_code
--		,task_number
--		,task_completion_date
--		,task_charge_flag
--		,award_number
--		,award_name
--		,award_start_date_active
--		,award_end_date_active
--		,award_closed_date
--		,award_status
--		,case when row_number() over (partition by pta order by aud_ts desc)=1 then
--			aud_action
--		end aflag
--	 from aud_hostdb.pta_recorded c
--	where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
--	) x
-- where x.aflag!='D'
--/

create or replace view ccreport.hostsmachcap2
as
SELECT
	unique
	h.assetno pseudo
	,h.hostname
	,nvl(h.pri, 0) pri
	,h.os
	,h.protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
  FROM hostdb.hoststab h
	,hostdb.machtab m
	,hostdb.capequip c
 WHERE h.assetno(+)=m.assetno
   AND m.assetno=c.assetnum
/
   --AND m.cpumodel=me.cpumodel and m.cputype=me.cputype
   --AND h.protocol =pr.name and pr.costed ='Y'

--
-- accounts with entities charged to 
--
create or replace view ccreport.acct_charged_v
as
select 
	wsc.account
	,n.name name
	,wsc.princ ID
	,0 pri
	,decode(w.charge_by, 'P', 'Hardcoded', NULL, 'Payroll', 'Unknown') Charge_Src
	,nvl(w.sponsor, 'unknown') sponsor
	,wsc.amount
	,wsc.charge
	,'U' etype
  from hostdb.who_service_charge wsc
	,hostdb.name n
	,hostdb.who w
 where wsc.princ=n.princ
   and n.pri=0
   and w.princ=n.princ
   and w.dist is not null
union
select
	hsc.account
	,h.hostname
	,hsc.assetno
	,h.pri
	,decode(h.charge_by, 'P', 'Hardcoded', 'FollowUser')
	,decode(h.usrprinc, null,
		decode(h.princ, null,
			decode(h.prjprinc, null, 'unknown', 'P-'||h.prjprinc)
				, 'E-'||h.princ)
		, 'U-'||h.usrprinc) 
	,hsc.amount
	,hsc.charge
	,'M' etype
  from hostdb.host_service_charge hsc
	,hostsmachcap2 h
 where h.assetno(+)=hsc.assetno
   and h.pri(+)=hsc.pri
/

--	,hostdb.hoststab h
--	,hostdb.machtab m
--	,hostdb.capequip c
-- where hsc.assetno=h.assetno(+)
--   and hsc.assetno=m.assetno(+)
--   and c.assetnum=m.assetno

--select 
--  from hostdb.hoststab h
--	,hostdb.machtab m
--	,hostdb.capequip c
