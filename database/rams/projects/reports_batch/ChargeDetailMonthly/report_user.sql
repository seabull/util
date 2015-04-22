-- $Id: report_user.sql,v 1.1 2005/10/11 14:08:49 yangl Exp $
-- Get user charges for FY05
-- Only the last month of user,dist_vec,service is shown
-- (i.e. duplicate months for the above values show only the last month it was charged)

set termout off
set heading off
set linesize 4000
set feedback on
spool u1.lst
select
	'name'
	||'|'||'princ'
	||'|'||'dist_vec'
	||'|'||'services'
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
	name
	||'|'||princ
	||'|'||dist_vec
	||'|'||svc
	||'|'||cnt
	||'|'||decode(charge_by, 'P','Hardcoded','Payroll')
	||'|'||description
  from 
(	
select
	wr.name
	,wr.princ
	,dist_vec
	,j.post_date
	,w.charge_by
	,nvl(cs.description,w.dist_src) description
	,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
		x.services
		||'|'||nvl(wr.sponsor,'Unknown') 
		||'|'||wr.project
		||'|'||wr.subproject
		||'|'||j.post_date
	else
		null
	end svc
	,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
		stragg(j.post_date) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
						order by j.post_date desc 
						rows between unbounded preceding and unbounded following)
	end cnt
  from 
	hostdb.who_recorded wr
	,ramsreport.user_hist w
	,hostdb.charge_sources cs
	,(
	select
		wbs.id
		,wbs.dist_vec
		,stragg(s.category) services
		,wbs.journal 
	  from ramsreport.wc_by_services wbs
		, hostdb.services s
	 where wbs.service_id=s.id
	   and wbs.journal > 236
	   -- and wbs.journal <
	group by 
		wbs.id
		,wbs.dist_vec
		,wbs.journal 
	) x
	,hostdb.journals j
 where wr.id=x.id
   and wr.princ=w.princ
   and w.dist_src=cs.kind(+)
   and j.id=x.journal
   and j.journal_type_flag='M'
   and w.journal=x.journal
order by 
	wr.princ
	,wr.name
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
