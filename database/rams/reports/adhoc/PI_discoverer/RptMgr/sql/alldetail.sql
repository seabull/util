-- $Id: alldetail.sql,v 1.9 2008/04/16 15:19:07 yangl Exp $
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
define lx_num_months=-&3

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
                    , pireport.acct_role_valid_v x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               --and x_j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
        )
/

spool off

spool &lx_directory/&lx_principal._m1_withos_adjustments.csv

set feedback off
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
	||','||'trans_date'
	||','||'location'
	||','||'charge_by'
	||','||'dist_source'
  from  dual
/
set feedback on

	--||',"'||cnt||'"'
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
	||',"'||trans_date||'"'
	||',"'||nvl(location, 'Unknown')||'"'
	||',"'||decode(charge_src, 'P','Hardcoded','D','Default','X','Residual',charge_src||'-'||usrprinc)||'"'
	||',"'||description||'"'
  from 
(	
    select
        unique
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
        ,c.trans_date
    	--,case when row_number() over (partition by hr.hostname, hr.assetno, hr.os, c.dist_vec, hr.charge_src, c.services order by j.post_date desc, hr.usrprinc)=1 then
    	--	monthagg(j.post_date) over (partition by hr.hostname, hr.assetno, hr.os, c.dist_vec, hr.charge_src, c.services 
    	--					order by j.post_date 
    	--					rows between unbounded preceding and unbounded following)
    	--end cnt
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
       and j.type='A'
       and j.post_date>=trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
       --and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
       --and j.post_date >= to_date('01-'||to_char(add_months(sysdate,-6), 'MON-YYYY'), 'DD-MON-YYYY')
    order by hr.hostname
    	,hr.assetno
)
where 
    --cnt is not null
  --and assetno in 
  --and 
    hostname in 
        (
            --select x_c.SCS_ID
            select x_c.name
              from pireport.charges x_c
                    , pireport.acct_role_valid_v x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               and x_j.type='A'
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
	'firstname'
	||','||'lastname'
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
	'"'||firstname||'"'
	||',"'||lastname||'"'
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
            ,hostdb.names.lastname(wr.name) lastname
            ,hostdb.names.firstname(wr.name) firstname
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
                    , pireport.acct_role_valid_v x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               --and x_j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
        )
/

spool off

spool &lx_directory/&lx_principal._u1_adjustments.csv
set feedback off
	--'name'
select
	'firstname'
	||','||'lastname'
	||','||'princ'
	||','||'dist_vec'
	||','||'services'
	||','||'sponsor'
	||','||'project'
	||','||'subproject'
	||','||'post_date'
	||','||'trans_date'
	||','||'charge_by'
	||','||'dist_source'
  from  dual
/

set feedback on
	--'"'||name||'"'
select
	'"'||firstname||'"'
	||',"'||lastname||'"'
	||',"'||princ||'"'
	||',"'||dist_vec||'"'
	||',"'||services||'"'
	||',"'||sponsor||'"'
	||',"'||project||'"'
	||',"'||subproject||'"'
	||',"'||post_date||'"'
	||',"'||trans_date||'"'
	||',"'||decode(charge_src, 'P','Hardcoded','D','Default','X','Residual','Payroll')||'"'
	||',"'||description||'"'
  from 
    (	
        select
            unique
            wr.name
            ,hostdb.names.lastname(wr.name) lastname
            ,hostdb.names.firstname(wr.name) firstname
            ,wr.princ
            ,c.dist_vec
            ,c.services
            ,wr.charge_src
            ,description
            ,wr.project
            ,wr.subproject
            ,nvl(wr.sponsor, 'Unknown') sponsor
            ,j.post_date
            ,c.trans_date
            --,case when row_number() over (partition by wr.name, wr.princ, dist_vec, c.services, wr.charge_src order by j.post_date desc)=1 then
            --	monthagg(trunc(j.post_date)) over (partition by wr.name, wr.princ, dist_vec, c.services, wr.charge_src 
            --					order by j.post_date 
            --					rows between unbounded preceding and unbounded following)
            --end cnt
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
         and j.type='A'
         and j.post_date >= trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
         --and j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
      order by wr.name
      	,wr.princ
    )
where 
      --cnt is not null
  --and 
    princ in 
        (
            select x_c.SCS_ID
              from pireport.charges x_c
                    , pireport.acct_role_valid_v x_ar
                    , pireport.jnls x_j
             where x_c.acct_id=x_ar.acct_id
               and x_j.jnl_id=x_c.jnl_id
               and x_ar.princ=lower('&lx_principal')
               and x_j.post_date >=  trunc(last_day(add_months(sysdate, &lx_num_months-1))+1)
               and x_j.type='A'
               --and x_j.post_date >= to_date('JUL-01'||to_char(add_months(sysdate,-6), 'YYYY'), 'MON-DD-YYYY')
        )
/

spool off

set termout on
set heading on
set linesize 80
set feedback on
quit

