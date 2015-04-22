-- $Id: servicelevel_v.sql,v 1.5 2006/09/11 21:00:21 yangl Exp $

-- hr_id is filled in by JE and will cause fake change reported if partition by it.
		--,case when row_number() over (partition by assetno, pri, hr_id, journal order by service_id)=1 then

grant select on hostdb.services to ccreport with grant option;

create or replace view ccreport.host_servicelevel_asofv1 as
select
	*
  from (
	select
		hs.assetno
		,hs.pri
		,case when row_number() over (partition by assetno, pri order by service_id)=1 then
			stragg_nodup(webcode) over (partition by assetno, pri order by service_id
							rows between unbounded preceding and unbounded following)
		end services
	  from ccreport.host_service_asofv_1 hs
		,hostdb.services s
	 where 
		hs.service_id=s.id
	) x
 where x.services is not null
/

create or replace view ccreport.host_servicelevel_asofv2 as
select
	*
  from (
	select
		hs.assetno
		,hs.pri
		,case when row_number() over (partition by assetno, pri order by service_id)=1 then
			stragg_nodup(webcode) over (partition by assetno, pri order by service_id
							rows between unbounded preceding and unbounded following)
		end services
	  from ccreport.host_service_asofv_2 hs
		,hostdb.services s
	 where 
		hs.service_id=s.id
	) x
 where x.services is not null
/

create or replace view ccreport.who_servicelevel_asofv1 as
select
	*
  from (
	select
		ws.princ
		,case when row_number() over (partition by princ order by service_id)=1 then
			stragg_nodup(webcode) over (partition by princ order by service_id
							rows between unbounded preceding and unbounded following)
		end services
	  from ccreport.who_service_asofv_1 ws
		,hostdb.services s
	 where 
		ws.service_id=s.id
	   and s.monthly is not null
	) x
 where x.services is not null
/

create or replace view ccreport.who_servicelevel_asofv2 as
select
	*
  from (
	select
		ws.princ
		,case when row_number() over (partition by princ order by service_id)=1 then
			stragg_nodup(webcode) over (partition by princ order by service_id
							rows between unbounded preceding and unbounded following)
		end services
	  from ccreport.who_service_asofv_2 ws
		,hostdb.services s
	 where 
		ws.service_id=s.id
	   and s.monthly is not null
	) x
 where x.services is not null
/

create or replace view ccreport.who_servicelevel_diff_v as
select
	*
  from (
	select
		w1.*
		,'OLD' comments
	  from who_servicelevel_asofv1 w1
	minus
	select
		w2.*
		,'OLD' comments
	  from who_servicelevel_asofv2 w2
	union
	-- In time 2 but not in time 1
	select
		w2.*
		,'NEW' comments
	  from who_servicelevel_asofv2 w2
	minus
	select
		w1.*
		,'NEW' comments
	  from who_servicelevel_asofv1 w1
	) x
/

create or replace view ccreport.host_servicelevel_diff_v as
select
	*
  from (
	select
		h1.*
		,'OLD' comments
	  from host_servicelevel_asofv1 h1
	minus
	select
		h2.*
		,'OLD' comments
	  from host_servicelevel_asofv2 h2
	union
	-- In time 2 but not in time 1
	select
		h2.*
		,'NEW' comments
	  from host_servicelevel_asofv2 h2
	minus
	select
		h1.*
		,'NEW' comments
	  from host_servicelevel_asofv1 h1
	) x
/
