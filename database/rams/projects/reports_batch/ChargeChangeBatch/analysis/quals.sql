select
        q.code
        ,q.keyword
        ,nvl(q.no_attr,'N')
        ,nvl(q.no_charge, 'N')
        ,nvl(q.no_net, 'N')
        ,nvl(q.no_software, 'N')
        ,(select count(m.assetno)
            from hostdb.capequip c
                ,hostdb.machtab m
          where c.assetnum=m.assetno
            and c.qual=q.code
        ) count
  from hostdb.qualifiers q
/

select 
	c.qual
	,m.assetno
	,(select abbrev||'-'||nvl(c.rm,'Unknown') from hostdb.bldgs b where b.code=c.bldg) location
	,nvl(m.usrprinc, 'unknown')
	,nvl(m.prjprinc, 'unknown')
	,nvl(c.princ, 'unknown')
  from hostdb.capequip c
	,hostdb.machtab m
 where c.assetnum=m.assetno
   and c.qual in ('f','q','i','b')
/
