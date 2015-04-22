
set linesize 600
set pagesize 50000
spool mach_wo_user.lst
select
	m.assetno
	,nvl(m.prjprinc,'unknown')
	,nvl(m.usrprinc,'unknown')
	,nvl(c.princ, 'unknown')
	,(select keyword from hostdb.qualifiers q where q.code=c.qual) status
	,(select abbrev||'-'||c.rm from hostdb.bldgs b where b.code=c.bldg) location
  from hostdb.machtab m
	,hostdb.capequip c
 where c.assetnum=m.assetno
   and m.dist is not null
   and m.charge_by is null
   and m.usrprinc is null
order by prjprinc, princ, assetno
/
select
	m.assetno
	,nvl(m.prjprinc,'unknown')
	,nvl(m.usrprinc,'unknown')
	,nvl(c.princ, 'unknown')
	,(select keyword from hostdb.qualifiers q where q.code=c.qual) status
	,(select abbrev||'-'||c.rm from hostdb.bldgs b where b.code=c.bldg) location
	,dist_vec
  from hostdb.machtab m
	,hostdb.capequip c
	, (
		select
			y.dist
			,stragg(y.acct) dist_vec
		  from (
			select account_string(a.funding, a.function, a.activity, a.org, a.entity, a.project, a.task, a.award, null, null) 
				||'@'||d.pct acct
				, d.dist
			from hostdb.accounts a
				,hostdb.dist d
			where a.id=d.account
			) y
		 group by y.dist 
	) x
 where c.assetnum=m.assetno
   and m.dist is not null
   and m.charge_by is null
   and m.usrprinc is null
   and m.dist=x.dist
order by prjprinc, princ, assetno
/
spool off
