-- $Header: c:\\Repository/database/rams/reports/adhoc/DetailY2D/machines_withos.sql,v 1.1 2006/05/17 14:50:28 yangl Exp $
--
set termout off
set heading off
set linesize 4000
set pagesize 50000
set feedback off
spool m1_withos.csv
select
	'hostname'
	||','||'assetno'
	||','||'os'
	||','||'dist_vec'
	||','||'services'
	||','||'location'
	||','||'sponsor'
	||','||'project'
	||','||'subproject'
	||','||'post_date'
	||','||'list_pdates'
	||','||'charge_by'
	||','||'dist_source'
  from  dual
/
set feedback on
select
	'"'||hostname||'"'
	||',"'||assetno||'"'
	||',"'||os||'"'
	||',"'||dist_vec||'"'
	||','||svc
	||',"'||nvl(location, 'Unknown')||'"'
	||',"'||cnt||'"'
	||',"'||decode(charge_by, 'P','Hardcoded',null,'U-'||usrprinc, 'Unknown')||'"'
	||',"'||description||'"'
  from 
(	
select
	hr.hostname
	,hr.assetno
	,hr.os
	,dist_vec
	,(select b.abbrev||'-'||nvl(c.rm, 'Unknown') from hostdb.capequip c, hostdb.bldgs b where c.bldg=b.code and c.assetnum=hr.assetno) location
	--,x.services
	--,j.post_date
	--,hr.project
	--,hr.subproject
	,hr.usrprinc
	,m.charge_by
	,nvl(cs.description,m.dist_src) description
	,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
		'"'||x.services||'"'
		||',"'||decode(hr.prjprinc,null, decode(hr.princ, null, 'Usr-'||nvl(hr.usrprinc, 'NA'), 'Equip-'||hr.princ),'Prj-'||hr.prjprinc)||'"'
		||',"'||hr.project||'"'
		||',"'||hr.subproject||'"'
		||',"'||j.post_date||'"'
	else
		null
	end svc
	,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
		--stragg(j.post_date) over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by 
		--concat_all(concat_expr(j.post_date,',')) over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by 
		monthagg(j.post_date) over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by 
						order by j.post_date 
						rows between unbounded preceding and unbounded following)
	end cnt
  from 
	hostdb.host_recorded hr
	,hostdb.machtab m
	,hostdb.charge_sources cs
	,(
	select
		*
	  from (
		select
			hbs.id
			,hbs.dist_vec
			--,stragg(substr(s.category, 3)) services
			,case when row_number() over (partition by hbs.id, hbs.dist_vec, hbs.journal order by s.webcode)=1 then
				stragg_nodup(s.webcode) over (partition by hbs.id, hbs.dist_vec, hbs.journal 
							order by s.webcode
						rows between unbounded preceding and unbounded following)
			end services
			,hbs.journal 
		  from hc_by_services_y2d_mv hbs
			, hostdb.services s
		 where hbs.service_id=s.id
		   and hbs.journal>237
		--group by 
		--	hbs.id
		--	,hbs.dist_vec
		--	,hbs.journal 
		) xx
	 where xx.services is not null
	) x
	,hostdb.journals j
 where hr.id=x.id
   and hr.assetno=m.assetno(+)
   and m.dist_src=cs.kind(+)
   and x.journal=j.id
   and j.journal_type_flag='M'
order by hr.hostname
	,hr.assetno
)
where svc is not null
/
spool off
set termout on
set heading on
set linesize 80
set feedback on
