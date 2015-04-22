-- $Id: malbec.sql,v 1.3 2007/02/20 15:09:27 yangl Exp $
--

set define on

--
-- malbec cluster
--


-- Master
--139354.01   DELL    PowerEdge 1950
-- Rack
--139354.00
-- Slaves (12/12)
--malbec01    139354.03   SUN     SunFire X2200
--malbec02    139354.04   SUN     SunFire X2200
--malbec03    139354.05   SUN     SunFire X2200
--malbec04    139354.06   SUN     SunFire X2200
--malbec05    139354.07   SUN     SunFire X2200
--malbec06    139354.08   SUN     SunFire X2200
--
--malbec07    139354.09   SUN     SunFire X2200
--malbec08    139354.10   SUN     SunFire X2200
--malbec09    139354.11   SUN     SunFire X2200
--malbec10    139354.12   SUN     SunFire X2200
--malbec11    139354.13   SUN     SunFire X2200
--malbec12    139354.14   SUN     SunFire X2200

-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139354.01','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '139354.00'
    ,'RACK'   
    ,'LOGICAL'    
    ,usrprinc   
    ,prjprinc
    ,dist
    ,charge_by
    ,dist_src
    ,project
    ,subproject
  from hostdb.machtab
 where assetno='139354.01'
/

-- slave nodes
update hostdb.machtab 
   set (project, subproject, dist, charge_by, dist_src, usrprinc, prjprinc)=
        (
        select
                project
                ,subproject
                ,dist
                ,charge_by
                ,dist_src
                ,usrprinc
                ,prjprinc
          from hostdb.machtab
         where assetno='139354.01'
        )
 where assetno in 
('139354.03' ,'139354.04' ,'139354.05' ,'139354.06' ,'139354.07' ,'139354.08' ,'139354.09' ,'139354.10' ,'139354.11','139354.12','139354.13','139354.14')
/


--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.07'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.08'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.09'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.10'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.11'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.12'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.13'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/
--
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '139354.14'
--    ,cputype
--    ,cpumodel
--    ,usrprinc   
--    ,prjprinc
--    ,dist
--    ,charge_by
--    ,dist_src
--    ,project
--    ,subproject
--  from hostdb.machtab
-- where assetno='139354.01'
--/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139354.03','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139354.04','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139354.05','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139354.06','CLS','+',null)
/

--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.07','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.08','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.09','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.10','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.11','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.12','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.13','CLS','+',null)
--/
--
--insert into hostdb.mach_attr
--    (assetno, attr, sense, notes)
--values
--    ('139354.14','CLS','+',null)
--/

