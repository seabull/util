-- $Id: alldetail.sql,v 1.5 2007/03/22 17:42:00 yangl Exp $
--

set termout off
set heading off
set linesize 4000
set pagesize 50000
set feedback off
set define on
set verify off

define lx_directory=&1
define lx_principal=&2
define lx_months=&3

spool &lx_directory/&lx_principal._m1_withos.csv

select
	'hostname'
	||','||'assetno'
	||','||'os'
	||','||'dist_vec'
	||','||'services'
	||','||'sponsor'
	||','||'project'
	||','||'subproject'
	||','||'post_date'
	||','||'location'
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
	||',"'||services||'"'
	||',"'||prjprinc||'"'
	||',"'||project||'"'
	||',"'||subproject||'"'
	||',"'||post_date||'"'
	||',"'||nvl(location, 'Unknown')||'"'
	||',"'||cnt||'"'
	||',"'||decode(charge_src, 'P','Hardcoded','D','Default','X','Residual',charge_src||'-'||usrprinc)||'"'
	||',"'||description||'"'
  from 
(	
    select
    	hr.hostname
    	,hr.assetno
    	,hr.os
    	,(select b.abbrev||'-'||nvl(cap.rm, 'Unknown') from hostdb.capequip cap, hostdb.bldgs b where cap.bldg=b.code and cap.assetnum=hr.assetno) location
    	,hr.usrprinc
    	--,m.charge_by
        ,hr.charge_src
    	,nvl(cs.description,hr.charge_src) description
----
	    ,c.dist_vec
        ,c.services
    	,decode(hr.prjprinc,null, decode(hr.princ, null, 'Usr-'||nvl(hr.usrprinc, 'NA'), 'Equip-'||hr.princ),'Prj-'||hr.prjprinc) prjprinc
        ,hr.project
        ,hr.subproject
        ,j.post_date
    	,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, c.dist_vec, hr.charge_src, c.services order by j.post_date desc, hr.usrprinc)=1 then
    		monthagg(j.post_date) over (partition by hr.hostname, hr.assetno, hr.os, c.dist_vec, hr.charge_src, c.services 
    						order by j.post_date 
    						rows between unbounded preceding and unbounded following)
    	end cnt
      from 
            hostdb.host_recorded hr
            --,hostdb.machtab m
            ,hostdb.charge_sources cs
            ,pireport.charges_distvec_v c
            ,pireport.jnls j
     where c.type='M'
       and hr.id=c.entity_id
       --and hr.assetno=m.assetno(+)
       and hr.charge_src=cs.kind(+)
       and c.jnl_id=j.jnl_id
       and j.type='M'
       and j.post_date>=trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
       --and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
       --and j.post_date >= to_date('01-'||to_char(add_months(sysdate,-6), 'MON-YYYY'), 'DD-MON-YYYY')
    order by hr.hostname
    	,hr.assetno
)
where cnt is not null
  --and assetno in 
  and hostname in 
        (
            --select x_c.SCS_ID
            select x_c.name
              from pireport.charges x_c
                    , pireport.acct_role x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               --and x_j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
        )
/

spool off


-- Get user charges for FY Year to Date
-- Only the last month of user,dist_vec,service is shown
-- (i.e. duplicate months for the above values show only the last month it was charged)

spool &lx_directory/&lx_principal._u1.csv
set feedback off
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

set feedback on
select
	'"'||name||'"'
	||',"'||princ||'"'
	||',"'||dist_vec||'"'
	||',"'||services||'"'
	||',"'||sponsor||'"'
	||',"'||project||'"'
	||',"'||subproject||'"'
	||',"'||post_date||'"'
	||',"'||cnt||'"'
	||',"'||decode(charge_src, 'P','Hardcoded','D','Default','X','Residual','Payroll')||'"'
	||',"'||description||'"'
  from 
    (	
        select
            wr.name
            ,wr.princ
            ,c.dist_vec
            ,c.services
            ,wr.charge_src
            ,description
            ,wr.project
            ,wr.subproject
            ,nvl(wr.sponsor, 'Unknown') sponsor
            ,j.post_date
            ,case when row_number() over (partition by wr.name, wr.princ, dist_vec, c.services, wr.charge_src order by j.post_date desc)=1 then
            	monthagg(trunc(j.post_date)) over (partition by wr.name, wr.princ, dist_vec, c.services, wr.charge_src 
            					order by j.post_date 
            					rows between unbounded preceding and unbounded following)
            end cnt
        from 
            hostdb.who_recorded wr
            --,hostdb.who w
            ,hostdb.charge_sources cs
            ,pireport.charges_distvec_v c
            ,pireport.jnls j
       where c.type='U'
         and wr.id=c.entity_id
         --and wr.princ=w.princ(+)
         and wr.charge_src=cs.kind(+)
         and c.jnl_id=j.jnl_id
         and j.type='M'
         and j.post_date >= trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
         --and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
      order by wr.name
      	,wr.princ
    )
where cnt is not null
  and princ in 
        (
            select x_c.SCS_ID
              from pireport.charges x_c
                    , pireport.acct_role x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               --and x_j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
        )
/

spool off

set termout on
set heading on
set linesize 80
set feedback on
quit

--desc charge_distvec_v
--type
--,entity_id
--,name
--,trans_date
--,jnl_id
--,services
--,dist_vec
--,charge
--,amount


-- 	wr.name
-- 	,wr.princ
-- 	,dist_vec
-- 	--,x.services
-- 	,j.post_date
-- 	--,nvl(wr.sponsor,'Unknown') sponsor
-- 	--,wr.project
-- 	--,wr.subproject
-- 	,w.charge_by
-- 	,nvl(cs.description,w.dist_src) description
-- 	,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
-- 		'"'||x.services||'"'
-- 		||',"'||nvl(wr.sponsor,'Unknown') ||'"'
-- 		||',"'||wr.project||'"'
-- 		||',"'||wr.subproject||'"'
-- 		||',"'||j.post_date||'"'
-- 	else
-- 		null
-- 	end svc
-- 	,case when row_number() over (partition by wr.name, wr.princ, dist_vec, w.charge_by order by j.post_date desc)=1 then
-- 		monthagg(trunc(j.post_date)) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
-- 						order by j.post_date 
-- 						rows between unbounded preceding and unbounded following)
-- 	end cnt
-- 		--monthagg(j.post_date) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
-- 		--stragg(j.post_date) over (partition by wr.name, wr.princ, dist_vec, w.charge_by 
--   from 
-- 	hostdb.who_recorded wr
-- 	,hostdb.who w
-- 	,hostdb.charge_sources cs
-- 	,(
-- 	select
-- 		*
-- 	  from (
-- 	select
-- 		wbs.id
-- 		,wbs.dist_vec
-- 		,case when row_number() over (partition by wbs.id, wbs.dist_vec, wbs.journal order by s.webcode)=1 then
-- 			stragg_nodup(s.webcode) over (partition by wbs.id, wbs.dist_vec, wbs.journal 
-- 							order by s.webcode
-- 						rows between unbounded preceding and unbounded following)
-- 		end services
-- 		,wbs.journal 
-- 	  from wc_by_services_y2d_mv wbs
-- 		, hostdb.services s
-- 	 where wbs.service_id=s.id
-- 	   --and wbs.journal > 237
-- 	--group by 
-- 	--	wbs.id
-- 	--	,wbs.dist_vec
-- 	--	,wbs.journal 
-- 		) xx
-- 	 where xx.services is not null
-- 	) x
-- 	,hostdb.journals j
--  where wr.id=x.id
--    and wr.princ=w.princ
--    and w.dist_src=cs.kind(+)
--    and j.id=x.journal
--    and j.journal_type_flag='M'
-- order by 
-- 	wr.name
-- 	,wr.princ
-- 	,j.post_date
-- 	,dist_vec
-- 	,w.charge_by
-- )
-- where svc is not null
-- /

-- ----
-- 
--     	,(select b.abbrev||'-'||nvl(c.rm, 'Unknown') from hostdb.capequip c, hostdb.bldgs b where c.bldg=b.code and c.assetnum=hr.assetno) location
--     	--,x.services
--     	--,j.post_date
--     	--,hr.project
--     	--,hr.subproject
--     	,hr.usrprinc
--     	,m.charge_by
--     	,nvl(cs.description,m.dist_src) description
--     	,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
--     		'"'||x.services||'"'
--     		||',"'||decode(hr.prjprinc,null, decode(hr.princ, null, 'Usr-'||nvl(hr.usrprinc, 'NA'), 'Equip-'||hr.princ),'Prj-'||hr.prjprinc)||'"'
--     		||',"'||hr.project||'"'
--     		||',"'||hr.subproject||'"'
--     		||',"'||j.post_date||'"'
--     	else
--     		null
--     	end svc
--     	,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by order by j.post_date desc, hr.usrprinc)=1 then
--     		--stragg(j.post_date) over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by 
--     		--concat_all(concat_expr(j.post_date,',')) over (partition by hr.hostname, hr.assetno, dist_vec, m.charge_by 
--     		monthagg(j.post_date) over (partition by hr.hostname, hr.assetno, hr.os, dist_vec, m.charge_by 
--     						order by j.post_date 
--     						rows between unbounded preceding and unbounded following)
--     	end cnt
--       from 
--     	hostdb.host_recorded hr
--     	,hostdb.machtab m
--     	,hostdb.charge_sources cs
--     	,(
--     	select
--     		*
--     	  from (
--     		select
--     			hbs.id
--     			,hbs.dist_vec
--     			--,stragg(substr(s.category, 3)) services
--     			,case when row_number() over (partition by hbs.id, hbs.dist_vec, hbs.journal order by s.webcode)=1 then
--     				stragg_nodup(s.webcode) over (partition by hbs.id, hbs.dist_vec, hbs.journal 
--     							order by s.webcode
--     						rows between unbounded preceding and unbounded following)
--     			end services
--     			,hbs.journal 
--     		  from hc_by_services_y2d_mv hbs
--     			, hostdb.services s
--     		 where hbs.service_id=s.id
--     		   and hbs.journal>237
--     		--group by 
--     		--	hbs.id
--     		--	,hbs.dist_vec
--     		--	,hbs.journal 
--     		) xx
--     	 where xx.services is not null
--     	) x
--     	,hostdb.journals j
--      where hr.id=x.id
--        and hr.assetno=m.assetno(+)
--        and m.dist_src=cs.kind(+)
--        and x.journal=j.id
--        and j.journal_type_flag='M'
--     order by hr.hostname
--     	,hr.assetno
-- )
-- where svc is not null
-- /
-- spool off
-- set termout on
-- set heading on
-- set linesize 80
-- set feedback on
-- 
-- 
-- 
-- -- mv
-- select
-- 	*
--   from (
-- select 
-- 	id
-- 	,service_id
-- 	--,account_flag
-- 	,journal
-- 	,case when row_number() over (partition by journal, id, service_id order by acct)=1 then
-- 		stragg(x.acct||'@'||pct) over (partition by journal, id, service_id order by acct 
-- 					rows between unbounded preceding and unbounded following) 
-- 	end dist_vec
--   from (
-- 	select
-- 		hc.hr_id id
-- 		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, decode(hc.account_flag,'b','s','l','l','i','i',null),null) acct
-- 		,hc.pct
-- 		,hc.service_id
-- 		--,hc.account_flag
-- 		,hc.journal
-- 	  from hostdb.host_charged hc
-- 		,hostdb.accounts a
-- 	 where
-- 		hc.journal >= (select min(id) from hostdb.journals where post_date>=to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY'))
-- 	   and hc.journal != 246
-- 	   --and hc.journal < 237
-- 	   and hc.account=a.id
-- 	order by 
-- 		journal
-- 		, id
-- 		, service_id
-- 		,account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project,a.task,a.award, null,null) 
-- 		, pct
-- 		, hc.account_flag
-- 	) x
-- ) xx
-- where xx.dist_vec is not null
-- /
-- 
