set pagesize 50000

create global temporary table mach_dept_au
ON COMMIT PRESERVE ROWS 
as
(
	select
		d.abbrev
		,m.assetno
		,h.hostname
		,s.category
	from hostdb.capequip c
		,hostdb.machtab m
		,hostdb.hoststab h
		,hostdb.depts d
		,hostdb.host_service hs
		,hostdb.services s
	where c.assetnum=m.assetno
		and m.assetno=h.assetno(+)
		and h.pri=0
		and d.numb(+)=nvl(c.dept, '05005')
		and hs.assetno(+)=m.assetno
		and hs.service_id=s.id
) 
/

break on abbrev skip page nodup on assetno on hostname 

spool queryResult
select 
	abbrev
	,assetno
	,hostname
	,category
from mach_dept_au a
where 
exists
(
	select 
	'X'
from hostdb.host_charged hc
	, hostdb.host_recorded hr
where 
	hc.journal>206
	and hr.assetno=a.assetno
	and hr.id=hc.hr_id
)
order by abbrev, hostname, category
/
spool off

truncate table mach_dept_au;
drop table mach_dept_au
/
