set pagesize 50000
set linesize 80
set heading on
set feedback on
set termout off
spool sponsor.lst

select 
	count(princ)
  from hostdb.who
 where dist is not null
/
 
select
	sponsor
	,cnt
	,100*cnt/(select count(princ) from hostdb.who where dist is not null) pct
  from
(
select
	nvl(sponsor, 'unknown') sponsor
	,count(princ) cnt
  from hostdb.who 
 where dist is not null
group by nvl(sponsor, 'unknown')
)
where cnt > 15
order by cnt desc
/

select
	count(assetno)
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) x
/
select
	usrprinc
	,cnt
	,100*cnt/total Percentage
  from (
select
	usrprinc
	,count(assetno) cnt
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
group by usrprinc
) xx
,(select
	count(assetno) total
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
) xy
where cnt > 20
order by cnt desc
/
select
	princ
	,cnt
	,100*cnt/total Percentage
  from (
select
	princ
	,count(assetno) cnt
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
group by princ
) xx
,(select
	count(assetno) total
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
) xy
where cnt > 20
order by cnt desc
/
select
	prjprinc
	,cnt
	,100*cnt/total Percentage
  from (
select
	prjprinc
	,count(assetno) cnt
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
group by prjprinc
) xx
,(select
	count(assetno) total
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) 
) xy
where cnt > 20
order by cnt desc
/


select
	*
  from (
select
	usrprinc
	,prjprinc
	,princ
	,count(assetno) cnt
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) x
group by usrprinc,prjprinc,princ
) x
where x.cnt > 15
order by cnt desc
/

select
	usrprinc
	,prjprinc
	,princ
	,h.hostname
	,x.assetno
	,h.ipaddress
	,h.protocol
  from (
	select
		m.assetno
		,nvl(m.usrprinc, 'unknown') usrprinc
		,nvl(m.prjprinc, 'unknown') prjprinc
		,nvl(c.princ, 'unknown') princ
	  from hostdb.capequip c
		,hostdb.machtab m
	 where c.assetnum=m.assetno
	   and m.dist is not null
	) x
	,hostdb.hoststab h
 where usrprinc='unknown'
   and prjprinc='unknown'
   and princ='unknown'
   and x.assetno=h.assetno(+)
order by x.assetno
/
spool off
set termout on
