-- $Header: c:\\Repository/database/rams/reports/adhoc/liz_fy05/machines.sql,v 1.3 2005/10/26 13:20:21 yangl Exp $
--
set termout off
set heading off
set linesize 4000
set pagesize 50000
set feedback on
spool m1.lst
select
	'hostname'
	||'|'||'assetno'
	||'|'||'dist_vec'
	||'|'||'services'
	||'|'||'location'
	||'|'||'sponsor'
	||'|'||'project'
	||'|'||'subproject'
	||'|'||'post_date'
	||'|'||'list_pdates'
	||'|'||'charge_by'
	||'|'||'dist_source'
  from  dual
/
select
	hostname
	||'|'||assetno
	||'|'||dist_vec
	||'|'||svc
	||'|'||nvl(location, 'Unknown')
	||'|'||cnt
	||'|'||decode(charge_by, 'P','Hardcoded',null,'U-'||usrprinc, 'Unknown')
	||'|'||description
  from 
(	
select
	hr.hostname
	,hr.assetno
	,dist_vec
	,(select b.abbrev||'-'||nvl(c.rm, 'Unknown') from hostdb.capequip c, hostdb.bldgs b where c.bldg=b.code and c.assetnum=hr.assetno) location
	--,x.services
	--,j.post_date
	--,hr.project
	--,hr.subproject
	,hr.usrprinc
	,m.charge_by
	,nvl(cs.description,m.dist_src) description
	,case when row_number() over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
		x.services
		||'|'||decode(hr.prjprinc,null, decode(hr.princ, null, 'Usr-'||nvl(hr.usrprinc, 'NA'), 'Equip-'||hr.princ),'Prj-'||hr.prjprinc)
		||'|'||hr.project
		||'|'||hr.subproject
		||'|'||j.post_date
	else
		null
	end svc
	,case when row_number() over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
		concat_all(concat_expr(j.post_date,',')) over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by 
						order by j.post_date desc 
						rows between unbounded preceding and unbounded following)
	end cnt
  from 
	hostdb.host_recorded hr
	,hostdb.machtab m
	,hostdb.charge_sources cs
	,(
		select
			hbs.id
			,hbs.dist_vec
			,stragg(s.category) services
			,hbs.journal 
		  from hc_by_services_fy0506_mv hbs
			, hostdb.services s
		 where hbs.service_id=s.id
		   and hbs.journal>237
		group by 
			hbs.id
			,hbs.dist_vec
			,hbs.journal 
	) x
	,hostdb.journals j
 where hr.id=x.id
   and hr.assetno=m.assetno(+)
   and m.dist_src=cs.kind(+)
   and x.journal=j.id
   and j.journal_type_flag='M'
)
where svc is not null
/
spool off
set termout on
set heading on
set linesize 80
set feedback on
