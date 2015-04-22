-- $Header: c:\\Repository/database/rams/reports/adhoc/DetailY2D/users.sql,v 1.4 2006/05/17 14:54:55 yangl Exp $
-- Get user charges for FY Year to Date
-- Only the last month of user,dist_vec,service is shown
-- (i.e. duplicate months for the above values show only the last month it was charged)
set termout off
set heading off
set linesize 4000
set pagesize 50000
set feedback on
spool u1.csv
select
	'name'
	||','||'princ'
	||','||'dist_vec'
	||','||'services'
	||','||'sponsor'
	||','||'project'
	||','||'subproject'
	||','||'post_date'
	||','||'list_pdates'
	||','||'charge_by'
	||','||'dist_source'
  from  dual
/
select
	'"'||name||'"'
	||',"'||princ||'"'
	||',"'||dist_vec||'"'
	||','||svc
	||',"'||cnt||'"'
	||',"'||decode(charge_by, 'P','Hardcoded','Payroll')||'"'
	||',"'||description||'"'
  from 
(	
select
	--wr.name
	(select name from hostdb.who_recorded wr1 where wr1.princ=wr.princ and rownum<2) name
	,wr.princ
	,dist_vec
	--,x.services
	,j.post_date
	--,nvl(wr.sponsor,'Unknown') sponsor
	--,wr.project
	--,wr.subproject
	,w.charge_by
	,nvl(cs.description,w.dist_src) description
	--,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
	,case when row_number() over (partition by wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
		'"'||x.services||'"'
		||',"'||nvl(wr.sponsor,'Unknown') ||'"'
		||',"'||wr.project||'"'
		||',"'||wr.subproject||'"'
		||',"'||j.post_date||'"'
	else
		null
	end svc
	--,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
	,case when row_number() over (partition by wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
		--monthagg(trunc(j.post_date)) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
		monthagg(trunc(j.post_date)) over (partition by wr.princ, dist_vec, w.charge_by 
						order by j.post_date 
						rows between unbounded preceding and unbounded following)
	end cnt
		--monthagg(j.post_date) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
		--stragg(j.post_date) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
  from 
	hostdb.who_recorded wr
	,hostdb.who w
	,hostdb.charge_sources cs
	,(
	select
		*
	  from (
	select
		wbs.id
		,wbs.dist_vec
		,case when row_number() over (partition by wbs.id, wbs.dist_vec, wbs.journal order by s.webcode)=1 then
			stragg_nodup(s.webcode) over (partition by wbs.id, wbs.dist_vec, wbs.journal 
							order by s.webcode
						rows between unbounded preceding and unbounded following)
		end services
		,wbs.journal 
	  from wc_by_services_y2d_mv wbs
		, hostdb.services s
	 where wbs.service_id=s.id
	   --and wbs.journal > 237
	--group by 
	--	wbs.id
	--	,wbs.dist_vec
	--	,wbs.journal 
		) xx
	 where xx.services is not null
	) x
	,hostdb.journals j
 where wr.id=x.id
   and wr.princ=w.princ
   and w.dist_src=cs.kind(+)
   and j.id=x.journal
   and j.journal_type_flag='M'
order by 
	wr.name
	,wr.princ
	,j.post_date
	,dist_vec
	,w.charge_by
)
where svc is not null
/
spool off
set termout on
set heading on
set linesize 80
set feedback on
