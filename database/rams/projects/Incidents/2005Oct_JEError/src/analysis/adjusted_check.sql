
select
	unique
	w.princ
	,w.charge_by
	,w.dist
	,w.dist_src
  from hostdb.who w
	, hostdb.who_adjust_charge wac
	, hostdb.who_recorded wr
 where w.princ=wr.princ
   and wr.id=wac.wr_id
   and wac.trans_date>sysdate-15
/

select 
	assetno
	,(select hostname from hostdb.hoststab where assetno=m.assetno and pri=0) hostname
	,charge_by
	,usrprinc
  from hostdb.machtab m
 where assetno in (
	select assetno 
	  from hostdb.host_recorded hr 
	 where hr.id in (
			select hr_id from hostdb.host_adjust_charge where trans_date>sysdate-15
		)
	)
/

