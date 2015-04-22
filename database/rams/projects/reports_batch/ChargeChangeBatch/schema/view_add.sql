-- $Header: c:\\Repository/database/rams/projects/reports_batch/ChargeChangeBatch/schema/view_add.sql,v 1.9 2006/04/11 20:51:39 yangl Exp $
--

--
-- Account String
--
--create or replace view accounts_str_v
create view accounts_str_v
as
select
        id
        ,hostdb.account_string(funding, function, activity, org, entity, project, task, award, null, null) acct_string
        ,decode(project, null, 'GL', 'GM') acct_type
        ,flag
        ,project
        ,task
        ,award
        ,funding
        ,function
        ,activity
        ,org
        ,entity
  from hostdb.accounts
/

--
-- Distribution related
--
--create or replace view dist_string_v
create view dist_string_v
as
select
        dist
        ,(select hostdb.account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=account) acct_string
        ,pct
        ,tpct
  from hostdb.dist d
/

--
-- who service charge one user per row
--
create or replace view wsc_hist_v
as
select
	princ
	,account
	,pct
	,service_id
	,charge
	,amount
  from
	(
	select
		princ
		,account
		,pct
		,service_id
		,charge
		,amount
		,wsc.aud_ts
		,case when row_number() over (partition by princ, account, pct, service_id, charge, amount order by aud_ts desc)=1 then
			wsc.aud_action
		end flag
	  from 
		aud_hostdb.who_service_charge wsc
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view wsc_curr_v
as
select
	princ
	,account
	,pct
	,service_id
	,charge
	,amount
  from
	(
	select
		princ
		,account
		,pct
		,service_id
		,charge
		,amount
		,wsc.aud_ts
		,case when row_number() over (partition by princ, account, pct, service_id, charge, amount order by aud_ts desc)=1 then
			wsc.aud_action
		end flag
	  from 
		aud_hostdb.who_service_charge wsc
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

--
-- who
--
create or replace view who_hist_v
as
select
	PRINC      
	,ID        
	,SPONSOR   
	,TYPE      
	,DEPT      
	,EMP_IND   
	,TITLE     
	,PROJECT   
	,CHARGE_BY 
	,DIST      
	,PCT       
	,OPROJECT  
	,SUBPROJECT
	,DIST_SRC  
  from (
	select
		PRINC      
		,ID        
		,SPONSOR   
		,TYPE      
		,DEPT      
		,EMP_IND   
		,TITLE     
		,PROJECT   
		,CHARGE_BY 
		,DIST      
		,PCT       
		,OPROJECT  
		,SUBPROJECT
		,DIST_SRC  
		,aud_ts
		,case when row_number() over (partition by princ order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.who w
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view who_curr_v
as
select
	PRINC      
	,ID        
	,SPONSOR   
	,TYPE      
	,DEPT      
	,EMP_IND   
	,TITLE     
	,PROJECT   
	,CHARGE_BY 
	,DIST      
	,PCT       
	,OPROJECT  
	,SUBPROJECT
	,DIST_SRC  
  from (
	select
		PRINC      
		,ID        
		,SPONSOR   
		,TYPE      
		,DEPT      
		,EMP_IND   
		,TITLE     
		,PROJECT   
		,CHARGE_BY 
		,DIST      
		,PCT       
		,OPROJECT  
		,SUBPROJECT
		,DIST_SRC  
		,aud_ts
		,case when row_number() over (partition by princ order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.who w
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/
--
-- User Materialized Views
--
create or replace view wsc_aggr_hist_v
as
select
	*
  from (
	select
		princ
		,dist_vec
		,case when row_number() over (partition by princ, dist_vec order by service)=1 then
			stragg_nodup(webcode) over (partition by princ, dist_vec order by service
						rows between unbounded preceding and unbounded following)
		end services
		,ChargeAmount
	  from (
		select
			wsc.princ
			,case when row_number() over (partition by wsc.princ, wsc.service_id order by wsc.account)
=1 then
				stragg(wsc.account||'@'||pct) over (partition by wsc.princ, wsc.service_id order by wsc.account, wsc.pct
						rows between unbounded preceding and unbounded following)
			end dist_vec
                        ,s.webcode
			,substr(s.category,3) service
			--,wsc.service_id service
			,sum(amount) over (partition by wsc.princ) ChargeAmount
		  from wsc_hist_v wsc
                        ,hostdb.services s
                 where wsc.service_id=s.id
		order by princ, service
		) x
	where x.dist_vec is not null
	) xx
 where services is not null
/

create or replace view wsc_aggr_curr_v
as
select
	*
  from (
	select
		princ
		,dist_vec
		,case when row_number() over (partition by princ, dist_vec order by service)=1 then
			stragg_nodup(webcode) over (partition by princ, dist_vec order by service
						rows between unbounded preceding and unbounded following)
		end services
		,ChargeAmount
	  from (
		select
			wsc.princ
			,case when row_number() over (partition by wsc.princ, wsc.service_id order by wsc.account)
=1 then
				stragg(wsc.account||'@'||pct) over (partition by wsc.princ, wsc.service_id order by wsc.account, wsc.pct
						rows between unbounded preceding and unbounded following)
			end dist_vec
                        ,s.webcode
			--,wsc.service_id service
			,substr(s.category,3) service
			,sum(amount) over (partition by wsc.princ) ChargeAmount
		  from wsc_curr_v wsc
                        ,hostdb.services s
                 where wsc.service_id=s.id
		order by princ, service
		) x
	where x.dist_vec is not null
	) xx
 where services is not null
/

create materialized view wsc_aggr_hist_mv
pctfree 0
tablespace report01
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	*
  from wsc_aggr_hist_v
/

create materialized view wsc_aggr_curr_mv
pctfree 0
tablespace report01
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	*
  from wsc_aggr_curr_v
/

--
-- user configuration data
--
create or replace view who_config_hist_v
as
select
        w.princ
        ,n.name
	,'Old' flag
        ,nvl(charge_by, 'L') charge_by
        ,nvl(sponsor, 'unknown') sponsor
        ,nvl(pct,0) PercentUser
        ,wsc.services
	,nvl(w.dist,0) dist_id
        --,(select sum(amount) from hostdb.who_service_charge wsc where wsc.princ=w.princ) ChargeAmount
        ,wsc.ChargeAmount
	,(select max(aud_ts) from aud_hostdb.who w1 where w1.princ=w.princ and aud_change_flag='A') LastChanged
  from who_hist_v w
	,wsc_aggr_hist_mv wsc
        ,hostdb.name n
        ,hostdb.principal p
 where w.princ=wsc.princ
   and w.princ=p.princ
   and n.princ=p.name
   and p.princ=p.name
   and n.pri=(select min(pri) from hostdb.name n2 where n2.princ=n.princ)
/

create or replace view who_config_curr_v
as
select
        w.princ
        ,n.name
	,'New' flag
        ,nvl(charge_by, 'L') charge_by
        ,nvl(sponsor, 'unknown') sponsor
        ,nvl(pct, 0) PercentUser
        ,wsc.services
	,nvl(w.dist, 0) dist_id
        --,(select sum(amount) from hostdb.who_service_charge wsc where wsc.princ=w.princ) ChargeAmount
        ,wsc.ChargeAmount
	,(select max(aud_ts) from aud_hostdb.who w1 where w1.princ=w.princ and aud_change_flag='A') LastChanged
  from who_curr_v w
	,wsc_aggr_curr_mv wsc
        ,hostdb.name n
        ,hostdb.principal p
 where w.princ=wsc.princ
   and w.princ=p.princ
   and n.princ=p.name
   and p.princ=p.name
   and n.pri=(select min(pri) from hostdb.name n2 where n2.princ=n.princ)
/

--
-- view that have a snapshot of wsc table
-- create context AUD_REPORT using ctxs;
-- exec ctxs.set_session_id('1234');
-- exec ctxs.set_ctx('AUD_REPORT','ReportTS', to_char(systimestamp, ctxs.constTSFORMAT));
--
create or replace view hsc_hist_v
as
select
	ASSETNO
	,PRI   
	,PCT  
	,CHARGE
	,AMOUNT
	,ACCOUNT
	,SERVICE_ID
	,HR_ID
	,JOURNAL
  from
	(
	select
		ASSETNO
		,PRI   
		,PCT  
		,CHARGE
		,AMOUNT
		,ACCOUNT
		,SERVICE_ID
		,HR_ID
		,JOURNAL
		,hsc.aud_ts
		,case when row_number() over (partition by assetno, pri, account, pct, service_id, charge, amount, hr_id, journal  order by aud_ts desc)=1 then
			hsc.aud_action
		end flag
	  from 
		aud_hostdb.host_service_charge hsc
	 --where aud_ts<=to_timestamp(sys_context('AUD_REPORT','ReportTS'), ctxs.get_tsformat)
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	) x
 where x.flag!='D'
/

create or replace view hsc_curr_v
as
select
	ASSETNO
	,PRI   
	,PCT  
	,CHARGE
	,AMOUNT
	,ACCOUNT
	,SERVICE_ID
	,HR_ID
	,JOURNAL
  from
	(
	select
		ASSETNO
		,PRI   
		,PCT  
		,CHARGE
		,AMOUNT
		,ACCOUNT
		,SERVICE_ID
		,HR_ID
		,JOURNAL
		,hsc.aud_ts
		,case when row_number() over (partition by assetno, pri, account, pct, service_id, charge, amount, hr_id, journal  order by aud_ts desc)=1 then
			hsc.aud_action
		end flag
	  from 
		aud_hostdb.host_service_charge hsc
	 --where aud_ts<=to_timestamp(sys_context('AUD_REPORT','ReportTS'), ctxs.get_tsformat)
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	) x
 where x.flag!='D'
/

create or replace view hsc_aggr_hist_v
as
select
	unique
	*
  from (
	select
		assetno
		,pri
		,dist_vec
		--,hr_id
		--,journal
		,case when row_number() over (partition by assetno, pri, dist_vec, hr_id, journal order by service)=1 then
			stragg_nodup(webcode) over (partition by assetno, pri, dist_vec, hr_id, journal order by service
						rows between unbounded preceding and unbounded following)
		end services
		,ChargeAmount
	  from (
		select
			hsc.assetno
			,hsc.pri
			,hsc.hr_id
			,hsc.journal
			,case when row_number() over (partition by hsc.assetno, hsc.pri, hsc.service_id, hsc.hr_id, hsc.journal order by hsc.account)
=1 then
				stragg(hsc.account||'@'||pct) over (partition by hsc.assetno, hsc.pri, hsc.service_id, hsc.hr_id, hsc.journal order by hsc.account, hsc.pct
						rows between unbounded preceding and unbounded following)
			end dist_vec
                        ,s.webcode
			--,hsc.service_id service
			,substr(s.category,3) service
			,sum(amount) over (partition by hsc.assetno, hsc.pri, hsc.hr_id, hsc.journal) ChargeAmount
		  from hsc_hist_v hsc
                        ,hostdb.services s
                 where hsc.service_id=s.id
		order by assetno, pri, service
		) x
	where x.dist_vec is not null
	) xx
 where services is not null
/

create or replace view hsc_aggr_curr_v
as
select
	unique
	*
  from (
	select
		assetno
		,pri
		,dist_vec
		--,hr_id
		--,journal
		,case when row_number() over (partition by assetno, pri, dist_vec, hr_id, journal order by service)=1 then
			stragg_nodup(webcode) over (partition by assetno, pri, dist_vec, hr_id, journal order by service
						rows between unbounded preceding and unbounded following)
		end services
		,ChargeAmount
	  from (
		select
			hsc.assetno
			,hsc.pri
			,hsc.hr_id
			,hsc.journal
			,case when row_number() over (partition by hsc.assetno, hsc.pri, hsc.service_id, hsc.hr_id, hsc.journal order by hsc.account)
=1 then
				stragg(hsc.account||'@'||pct) over (partition by hsc.assetno, hsc.pri, hsc.service_id, hsc.hr_id, hsc.journal order by hsc.account, hsc.pct
						rows between unbounded preceding and unbounded following)
			end dist_vec
                        ,s.webcode
			--,hsc.service_id service
			,substr(s.category,3) service
			,sum(amount) over (partition by hsc.assetno, hsc.pri, hsc.hr_id, hsc.journal) ChargeAmount
		  from hsc_curr_v hsc
                        ,hostdb.services s
                 where hsc.service_id=s.id
		order by assetno, pri, service
		) x
	where x.dist_vec is not null
	) xx
 where services is not null
/

create materialized view hsc_aggr_hist_mv
pctfree 0
tablespace report01
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	*
  from hsc_aggr_hist_v
/

create materialized view hsc_aggr_curr_mv
pctfree 0
tablespace report01
--parallel
build immediate
refresh on demand
disable query rewrite
as
select
	*
  from hsc_aggr_curr_v
/

create or replace view capequip_hist_v
as
select
	ASSETNUM
	,SERIALNUM
	,BLDG
	,FLR
	,RM
	,SUFFIX
	,QUAL
	,PONUM
	,LINENUM
	,MANUF
	,DESCRIPTION
	,LOCDATE
	,USELEVEL
	,VERIFIED
	,DEPT
	,PRINC
	,WARRANTY_EXPIRE
	,WARRANTY_INFO
	,IROWID
  from (
	select
		ASSETNUM 
		,SERIALNUM
		,BLDG
		,FLR
		,RM
		,SUFFIX
		,QUAL
		,PONUM
		,LINENUM
		,MANUF
		,DESCRIPTION
		,LOCDATE
		,USELEVEL
		,VERIFIED
		,DEPT
		,PRINC
		,WARRANTY_EXPIRE
		,WARRANTY_INFO
		,IROWID
		,aud_ts
		,case when row_number() over (partition by assetnum order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.capequip c
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view capequip_curr_v
as
select
	ASSETNUM
	,SERIALNUM
	,BLDG
	,FLR
	,RM
	,SUFFIX
	,QUAL
	,PONUM
	,LINENUM
	,MANUF
	,DESCRIPTION
	,LOCDATE
	,USELEVEL
	,VERIFIED
	,DEPT
	,PRINC
	,WARRANTY_EXPIRE
	,WARRANTY_INFO
	,IROWID
  from (
	select
		ASSETNUM 
		,SERIALNUM
		,BLDG
		,FLR
		,RM
		,SUFFIX
		,QUAL
		,PONUM
		,LINENUM
		,MANUF
		,DESCRIPTION
		,LOCDATE
		,USELEVEL
		,VERIFIED
		,DEPT
		,PRINC
		,WARRANTY_EXPIRE
		,WARRANTY_INFO
		,IROWID
		,aud_ts
		,case when row_number() over (partition by assetnum order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.capequip c
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view machtab_hist_v
as
select
	ASSETNO
	,CPUTYPE
	,CPUMODEL
	,CPUMODELEXT
	,HOSTID
	,PROJECT
	,HWADDR
	,USRPRINC
	,PRJPRINC
	,USAGE
	,IROWID
	,DIST
	,CHARGE_BY
	,OPROJECT
	,OUSAGE
	,SUBPROJECT
	,DIST_SRC
	,MR_CLASS
	,FILTER_CODE
  from (
	select
		ASSETNO
		,CPUTYPE
		,CPUMODEL
		,CPUMODELEXT
		,HOSTID
		,PROJECT
		,HWADDR
		,USRPRINC
		,PRJPRINC
		,USAGE
		,IROWID
		,DIST
		,CHARGE_BY
		,OPROJECT
		,OUSAGE
		,SUBPROJECT
		,DIST_SRC
		,MR_CLASS
		,FILTER_CODE
		,aud_ts
		,case when row_number() over (partition by assetno order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.machtab m
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view machtab_curr_v
as
select
	ASSETNO
	,CPUTYPE
	,CPUMODEL
	,CPUMODELEXT
	,HOSTID
	,PROJECT
	,HWADDR
	,USRPRINC
	,PRJPRINC
	,USAGE
	,IROWID
	,DIST
	,CHARGE_BY
	,OPROJECT
	,OUSAGE
	,SUBPROJECT
	,DIST_SRC
	,MR_CLASS
	,FILTER_CODE
  from (
	select
		ASSETNO
		,CPUTYPE
		,CPUMODEL
		,CPUMODELEXT
		,HOSTID
		,PROJECT
		,HWADDR
		,USRPRINC
		,PRJPRINC
		,USAGE
		,IROWID
		,DIST
		,CHARGE_BY
		,OPROJECT
		,OUSAGE
		,SUBPROJECT
		,DIST_SRC
		,MR_CLASS
		,FILTER_CODE
		,aud_ts
		,case when row_number() over (partition by assetno order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.machtab m
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view hoststab_hist_v
as
select
	HOSTNAME
	,OS
	,OSVERS
	,IPADDRESS
	,ASSETNO
	,PROTOCOL
	,PRI
	,TTL
	,PCT_USE
	,IROWID
	,OPRI
	,CONN
  from (
	select
		HOSTNAME
		,OS
		,OSVERS
		,IPADDRESS
		,ASSETNO
		,PROTOCOL
		,PRI
		,TTL
		,PCT_USE
		,IROWID
		,OPRI
		,CONN
		,aud_ts
		,case when row_number() over (partition by assetno, pri order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.hoststab h
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='h'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

create or replace view hoststab_curr_v
as
select
	HOSTNAME
	,OS
	,OSVERS
	,IPADDRESS
	,ASSETNO
	,PROTOCOL
	,PRI
	,TTL
	,PCT_USE
	,IROWID
	,OPRI
	,CONN
  from (
	select
		HOSTNAME
		,OS
		,OSVERS
		,IPADDRESS
		,ASSETNO
		,PROTOCOL
		,PRI
		,TTL
		,PCT_USE
		,IROWID
		,OPRI
		,CONN
		,aud_ts
		,case when row_number() over (partition by assetno, pri order by aud_ts desc)=1 then
			aud_action
		end flag
	  from aud_hostdb.hoststab h
	 where aud_ts<=(select ts from histview_param where id=(select max(id) from histview_param where flag='c'))
	   --and aud_change_flag='A'
	) x
 where x.flag!='D'
/

	-- need to fill in PL/SQL
	--,null LastChanged
	--,nvl(m.usrprinc, nvl(c.princ, nvl(m.prjprinc, 'unknown'))) PrimaryUser
create or replace view host_config_hist_v
as
select
        m.assetno
	,h.hostname
	,'Old' flag
	,h.pri
	,nvl(h.ipaddress, 'na') ipaddress
        ,nvl(m.charge_by, 'L') charge_by
	,c.qual
	,hsc.services
	,(select abbrev||' '||c.rm from hostdb.bldgs b where c.bldg=b.code) location
	,decode(m.usrprinc, null, decode(c.princ, null, decode(m.prjprinc, null, 'unknown', 'P-'||m.prjprinc), 'E-'||c.princ), 'U-'||m.usrprinc) PrimaryUser
	,nvl(h.os,'unknown') os
	,nvl(m.dist, 0) dist_id
	,h.protocol
	,(select abbrev from hostdb.depts depts where depts.numb=nvl(c.dept,'05005')) dept
	,hsc.ChargeAmount
	,(select max(aud_ts) from aud_hostdb.capequip c1 
		where c1.assetnum=c.assetnum
		  and aud_ts<=(select ts from histview_param 	
				where id=(select max(id)
				 	    from histview_param 
					   where flag='h')
				)
	) LastChanged_c
	,(select max(aud_ts) from aud_hostdb.machtab m1 
		where m1.assetno=m.assetno 
		  and aud_ts<=(select ts from histview_param 
				where id=(select max(id) 
					    from histview_param 
					   where flag='h')
				)
	) LastChanged_m
	,(select max(aud_ts) from aud_hostdb.hoststab h1 
		where h1.assetno=h.assetno 
		  and aud_ts<=(select ts from histview_param 
				where id=(select max(id) 
					    from histview_param 
					   where flag='h')
				)
	) LastChanged_h
  from 
	capequip_hist_v c
	,hoststab_hist_v h
	,machtab_hist_v m
	,hsc_aggr_hist_mv hsc
 where c.assetnum=hsc.assetno
   and c.assetnum=m.assetno
   and m.assetno=h.assetno
   and h.pri=hsc.pri
/

	--,nvl(m.usrprinc, nvl(c.princ, nvl(m.prjprinc, 'unknown'))) PrimaryUser
create or replace view host_config_curr_v
as
select
        m.assetno
	,h.hostname
	,'New' flag
	,h.pri
	,nvl(h.ipaddress,'na') ipaddress
        ,nvl(m.charge_by, 'L') charge_by
	,c.qual
	,hsc.services
	,(select abbrev||' '||c.rm from hostdb.bldgs b where c.bldg=b.code) location
	,decode(m.usrprinc, null, decode(c.princ, null, decode(m.prjprinc, null, 'unknown', 'P-'||m.prjprinc), 'E-'||c.princ), 'U-'||m.usrprinc) PrimaryUser
	,nvl(h.os,'unknown') os
	,nvl(m.dist,0) dist_id
	,h.protocol
	,(select abbrev from hostdb.depts depts where depts.numb=nvl(c.dept,'05005')) dept
	,hsc.ChargeAmount
	-- need to fill in PL/SQL
	--,null LastChanged
	,(select max(aud_ts) from aud_hostdb.capequip c1 
		where c1.assetnum=c.assetnum
		  and aud_ts<=(select ts from histview_param 	
				where id=(select max(id)
				 	    from histview_param 
					   where flag='c')
				)
	) LastChanged_c
	,(select max(aud_ts) from aud_hostdb.machtab m1 
		where m1.assetno=m.assetno 
		  and aud_ts<=(select ts from histview_param 
				where id=(select max(id) 
					    from histview_param 
					   where flag='c')
				)
	) LastChanged_m
	,(select max(aud_ts) from aud_hostdb.hoststab h1 
		where h1.assetno=h.assetno 
		  and aud_ts<=(select ts from histview_param 
				where id=(select max(id) 
					    from histview_param 
					   where flag='c')
				)
	) LastChanged_h
  from 
	capequip_curr_v c
	,hoststab_curr_v h
	,machtab_curr_v m
	,hsc_aggr_curr_mv hsc
 where c.assetnum=hsc.assetno
   and c.assetnum=m.assetno
   and m.assetno=h.assetno
   and h.pri=hsc.pri
/

--
-- Dev area
--
--select
--	d.acct_string
--	,d.pct
--	,wcc.princ
--	,wcc.name
--	,wcc.sponsor
--	,wcc.PctUser
--	,wcc.charge_by
--	,wcc.service_vec
--	,wcc.ChargeAmount
--	,wcc.LastChanged
--	,
--  from who_conf_changed wcc
--	,dist_string_v d
-- where wcc.dist_id=d.dist
create or replace view who_conf_details_v
as
select
	princ
	,name
	,change_flag
	,charge_by
	,sponsor
	,PctUser
	,service_vec
	,dist_id
	,acct_string
	,d.pct
	,ChargeAmount
	,round(ChargeAmount*d.pct/100, 2) AmountCharged
	,LastChanged
	,report_log_id
  from who_conf_changed w
	,dist_string_v d
 where w.dist_id=d.dist
/

--create or replace view who_conf_report_v
--as
--select
--	unique
--	acct_string
--	,princ
--	,name
--	,change_flag
--	,case when count(unique change_flag) over (partition by report_log_id, princ, acct_string) > 1 then
--	        'Changed'
--	else
--	        case when change_flag='Old' then
--	                'Deleted'
--	        else
--	                'Added'
--	        end
--	end Reason
--	,charge_by      -- 'L' or 'P'
--	,sponsor
--	,PctUser
--	,service_vec
--	--,dist_id
--	,pct
--	,ChargeAmount           TotalCharged
--	,round(ChargeAmount*pct/100, 2)       AmountCharged
--	,LastChanged
--	,report_log_id
--  from who_conf_details_v
-- where report_log_id=3
--   --and acct_string=p_acctstring
--   and (princ ,charge_by, acct_string) not in
--        (select princ, charge_by, acct_string
--           from who_conf_details_v
--          where report_log_id=3
--          group by princ, charge_by, acct_string, sponsor, PctUser, service_vec
--                        ,pct
--          having count(distinct change_flag)>1
--        )
--order by acct_string, Reason, princ, change_flag
--/

create or replace view host_conf_details_v
as
select
        assetno
	,hostname
	,change_flag
	,pri
	,ipaddress
        ,charge_by
	,q.keyword qual
	,service_vec
	,location
	,PrimaryUser
	,os
	,dist_id
	,acct_string
	,d.pct
	,protocol
	,dept
	,ChargeAmount
	,round(ChargeAmount*d.pct/100, 2) AmountCharged
	,LastChanged
	,report_log_id
  from host_conf_changed h
	,dist_string_v d
	,hostdb.qualifiers q
 where h.dist_id=d.dist
   and q.code=h.qual
/


-- Accounts should be reported.
--select
--	distinct
--	acct_string
--  from
--(
--select
--	acct_string
--	,assetno
--	,pri
--	,count(distinct change_flag) over (partition by report_log_id, assetno, hostname, pri, acct_string, ipaddress, charge_by, qual, service_vec,location ,PrimaryUser, os, pct, protocol, dept, ChargeAmount) cnt
--  from host_conf_details_v h
-- where 
--	report_log_id=3
--union
--select
--	acct_string
--	,princ
--	,0
--	,count(distinct change_flag) over (partition by report_log_id, princ, charge_by, acct_string, sponsor, PctUser, service_vec ,pct, ChargeAmount) cnt
--  from who_conf_details_v h
-- where 
--	report_log_id=3
--) x
-- where x.cnt<2
--/

----select
----	acct_string
----  from host_conf_details_v h
---- where 
----	report_log_id=3
----   and (assetno, hostname, pri, acct_string) not in
----	(select assetno, hostname, pri, acct_string
----	   from host_conf_details_v
----	  where report_log_id=3
----	group by report_log_id, assetno, hostname, pri, acct_string, ipaddress, charge_by, qual, service_vec
----	        ,location ,PrimaryUser, os, dist_id, pct, protocol, dept, ChargeAmount
----	having count(distinct change_flag)>1
----	)
----union
----select
----	acct_string
----  from who_conf_details_v w
---- where
----	report_log_id=3
----   and (princ ,charge_by, acct_string) not in
----	(select princ, charge_by, acct_string
----	   from who_conf_details_v
----	  where report_log_id=3
----	  group by princ, charge_by, acct_string, sponsor, PctUser, service_vec
----	                ,pct
----	  having count(distinct change_flag)>1
----	)
----/
----select
----	account
----  from host_conf_changed h
----	,hostdb.dist d
---- where d.dist=h.dist_id
----union
----select
----	account
----  from who_conf_changed w
----	,hostdb.dist d
---- where d.dist=w.dist_id
----/
