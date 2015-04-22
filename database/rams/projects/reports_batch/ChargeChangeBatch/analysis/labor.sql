
spool labor.lst
prompt Following Labor
select
	count(*)
  from hostdb.who
 where dist is not null
  and charge_by is null
/

prompt Following Project
select
	count(*) 
  from hostdb.who
 where dist is not null
  and charge_by is not null
/

select 
	count(assetno)
  from
	(
        select
                m.assetno
		,c.qual
		,m.charge_by
		,m.dist_src
		,m.usrprinc
          from hostdb.capequip c
                ,hostdb.machtab m
         where c.assetnum=m.assetno
           and m.dist is not null
	) x
 where x.charge_by is null
/
select 
	count(assetno)
  from
	(
        select
                m.assetno
		,c.qual
		,m.charge_by
		,m.dist_src
		,m.usrprinc
          from hostdb.capequip c
                ,hostdb.machtab m
         where c.assetnum=m.assetno
           and m.dist is not null
	) x
 where x.charge_by is null
   and x.usrprinc is null
/
select 
	count(assetno)
  from
	(
        select
                m.assetno
		,c.qual
		,m.charge_by
		,m.dist_src
		,m.usrprinc
          from hostdb.capequip c
                ,hostdb.machtab m
         where c.assetnum=m.assetno
           and m.dist is not null
	) x
 where x.charge_by='P'
/
spool off
