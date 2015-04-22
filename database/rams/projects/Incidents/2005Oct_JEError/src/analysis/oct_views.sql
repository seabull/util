create or replace view oct_who_v
as
select
	princ
	,charge_by
	,dist
	,dist_vec
  from (
	select
		w.princ
		,w.dist
		,w.charge_by
		,case when row_number() over (partition by w.princ, w.dist order by d.account, d.pct)=1 then
			stragg(d.account||'@'||d.pct*w.pct/100) over (partition by w.princ, w.dist order by d.account, d.pct
				rows between unbounded preceding and unbounded following)
		end dist_vec
	  from hostdb.who w
		,hostdb.dist d
	 where w.dist is not null
	   and d.dist=w.dist
	)
 where dist_vec is not null
/

create or replace view oct_wsc_v
as
select
	princ
	,dist_vec
  from (
	select
		princ
		,case when row_number() over (partition by princ order by account, pct)=1 then
			stragg(x.account||'@'||x.pct) over (partition by princ order by account, pct
				rows between unbounded preceding and unbounded following)
		end dist_vec
	  from
		(
		select
			unique
			wsc.princ
			,account
			,pct
		  from hostdb.who_service_charge wsc
		) x
	)
 where dist_vec is not null
/

-- labor distribution view
create or replace view oct_labor_dist_v
as
select
	l.princ
	,case when row_number() over (partition by l.princ order by l.account, pct_norm)=1 then
		stragg(account||'@'||pct_norm) over (partition by l.princ order by l.account, pct_norm
			rows between unbounded preceding and unbounded following)
	end dist_vec	
  from (
	select
		princ
		,account
		,sum(pct_norm) pct_norm
	  from hostdb.labor_recorded 
	 where period_last > to_date('10-30-2005','MM-DD-YYYY')
	   and princ is not null
	group by princ, account
	) l
/

create or replace view oct_host_v
as
select
	assetno
	,dist_vec
  from (
	select
		w.assetno
		,w.dist
		,case when row_number() over (partition by w.assetno, w.dist order by d.account, d.pct)=1 then
			stragg(d.account||'@'||d.pct) over (partition by w.assetno, w.dist order by d.account, d.pct
				rows between unbounded preceding and unbounded following)
		end dist_vec
	  from hostdb.machtab w
		,hostdb.dist d
	 where w.dist is not null
	   and d.dist=w.dist
	)
 where dist_vec is not null
/

create or replace view oct_hsc_v
as
select
	assetno
	,dist_vec
  from (
	select
		assetno
		,case when row_number() over (partition by assetno order by account, pct)=1 then
			stragg(x.account||'@'||x.pct) over (partition by assetno order by account, pct
				rows between unbounded preceding and unbounded following)
		end dist_vec
	  from
		(
		select
			unique
			wsc.assetno
			,account
			,pct
		  from hostdb.host_service_charge wsc
		) x
	)
 where dist_vec is not null
/

create or replace view oct_ws_v
as
select
	*
  from (
	select
		princ
		,case when row_number() over (partition by princ order by service_id, pct)=1 then
			stragg(service_id) over (partition by princ order by service_id, pct
				rows between unbounded preceding and unbounded following)
		end svc_vec	
	  from hostdb.who_service ws
	)
 where svc_vec is not null
/

create or replace view oct_wc_svc_v
as
select
	*
  from (
	select
		princ
		,case when row_number() over (partition by princ order by service_id)=1 then
			stragg(service_id) over (partition by princ order by service_id
				rows between unbounded preceding and unbounded following)
		end svc_vec	
	  from (
		select
			unique
			(select princ from hostdb.who_recorded where id=wr_id) princ
			,wc.service_id
			--,wc.pct
		  from hostdb.who_charged wc
		 where journal=245
		)
	)
 where svc_vec is not null
/

create or replace view oct_who_service_v
as
select
	*
  from (
	select
		unique
		(select princ from hostdb.who_recorded where id=wr_id) princ
		,wc.wr_id
		,wc.service_id
	  from hostdb.who_charged wc
	 where wc.journal=245
	)
/
-- grant select on oct_who_service_v to hostdb;

create or replace view jnl245_wc_dist_v
as
select 
	*
  from (
	select
		princ
		,case when row_number() over (partition by princ order by account)=1 then
			stragg(account||'@'||pct) over (partition by princ order by account
				rows between unbounded preceding and unbounded following)
		end dist_vec	
	  from (
		select
			unique
			(select princ from hostdb.who_recorded where id=wr_id) princ
			,wc.account
			,wc.pct
			,sum(wc.pct) over (partition by wr_id, service_id) tpct
		  from hostdb.who_charged wc
		 where journal=245
		)
	)
 where dist_vec is not null
/
			--stragg(account||'@'||pct*100/tpct) over (partition by princ order by account
