set linesize 1000
spool diffs.lst
column dist_vec format a80
column Labor format a80
column Charged format a80
column Configured format a80
column princ format a8
--
-- check account substitution first.
--
select
	l.princ
	,a.princ
	,name
	,account
	,pct_norm
	,dst_account
  from hostdb.labor_recorded l
	,hostdb.account_subs a
 where l.period_last > to_date('10-30-2005','MM-DD-YYYY')
   and l.account=src_account
   and (l.princ=a.princ or a.princ is null)
/
--
-- service diffs
--
select
	wc.princ
	,wc.svc_vec Charged
	,ws.svc_vec Configured
  from oct_ws_v ws
	,oct_wc_svc_v wc
 where ws.princ=wc.princ
   and wc.svc_vec!=ws.svc_vec
/

--
-- difference between labor and who_service_charge
--
select
	l.princ
	,l.dist_vec Labor
	,w.dist_vec Charged
  from oct_labor_dist_v l
	,oct_wsc_v w
 where l.princ=w.princ
   and l.dist_vec!=w.dist_vec
   and l.princ not in (select princ from hostdb.who where charge_by='P')
   and l.princ not in (select l.princ 
			from oct_labor_dist_v l2
			        ,oct_who_v w2
			 where l2.princ=w2.princ
			   and l2.dist_vec!=w2.dist_vec
			   and l2.princ not in (select princ from hostdb.who where charge_by='P')
			)
/

select 
	l.princ
	,l.dist_vec Labor
	,w.dist_vec Configured
	,wsc.dist_vec Charged
  from oct_labor_dist_v l
	,oct_wsc_v wsc
	,oct_who_v w
 where l.princ=w.princ
   and l.princ=wsc.princ
   and l.princ not in (select princ from hostdb.who where charge_by='P')
   and l.dist_vec!=wsc.dist_vec
   and l.dist_vec=w.dist_vec
/

--
-- difference between labor and who_charged
--
select 
	l.princ
	,l.dist_vec Labor
	--,w.dist_vec Configured
	,wc.dist_vec Charged
  from oct_labor_dist_v l
	,jnl245_wc_dist_v wc
	--,oct_who_v w
 where l.princ=wc.princ
   --and l.princ=w.princ
   and l.princ not in (select princ from hostdb.who where charge_by='P')
   and l.dist_vec!=wc.dist_vec
   and l.princ!='biglou'
   --and l.dist_vec=w.dist_vec
/


--
-- difference between labor and who
-- exception case: princ='biglou' who has account_subs entry
--
select
	l.princ
	,w.charge_by
	,l.dist_vec Labor
	,w.dist_vec Configured
  from oct_labor_dist_v l
	,oct_who_v w
 where l.princ=w.princ
   and l.dist_vec!=w.dist_vec
   and l.princ not in (select princ from hostdb.who where charge_by='P')
/

--
-- difference between who (dist) and who_service_charge
--
column Correct format a80
column Wrong format a80
select 
	c.princ
	,c.dist_vec Correct
	,w.dist_vec Wrong
  from oct_who_v c
	,oct_wsc_v w
 where c.princ=w.princ
   and c.dist_vec!=w.dist_vec
/

select 
	c.assetno
	,c.dist_vec Correct
	,w.dist_vec Wrong
  from oct_host_v c
	,oct_hsc_v w
 where c.assetno=w.assetno
   and c.dist_vec!=w.dist_vec
/

select 
	princ
	,charge_by
	,d.dist
	,dist_src
	,d.account
	,d.pct
	,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=d.account) acct
	,project
	,subproject
	,type
  from hostdb.who w
	,hostdb.dist d
 where princ in
(
	select 
		unique
		c.princ
		--,c.dist_vec Correct
		--,w.dist_vec Wrong
	  from oct_who_v c
		,oct_wsc_v w
	 where c.princ=w.princ
	   and c.dist_vec!=w.dist_vec
minus
	select 
		princ
	  from aud_hostdb.who 
	 where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
	   and aud_ts < to_timestamp('02-NOV-05 02.58.35.508603 AM')
)
   and w.dist=d.dist
/
select 
	unique
	princ
	,account
	,pct
	,(select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) from hostdb.accounts a where a.id=wsc.account) acct
  from hostdb.who_service_charge wsc
 where princ in
	(
	select 
		unique
		c.princ
		--,c.dist_vec Correct
		--,w.dist_vec Wrong
	  from oct_who_v c
		,oct_wsc_v w
	 where c.princ=w.princ
	   and c.dist_vec!=w.dist_vec
minus
	select 
		princ
	  from aud_hostdb.who 
	 where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
	   and aud_ts < to_timestamp('02-NOV-05 02.58.35.508603 AM')
	)
/
spool off
set linesize 80
