-- $Id: faccluster.sql,v 1.3 2007/02/27 15:54:40 yangl Exp $
--

set define on

--
-- fac cluster
--
-- Master
--134971.00

-- Rack
--134680.00

-- Slaves (6/6)
--134688.00
--134689.00
--135776.00
--135777.00
--134974.00
--001466.00

-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134971.00','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '134680.00'
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
 where assetno='134971.00'
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
         where assetno='134971.00'
        )
 where assetno in 
('134688.00' ,'134689.00' ,'135776.00' ,'135777.00' ,'134974.00' ,'001466.00')
/

-- TODO: delete before production release.
--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '001466.00'
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
-- where assetno='134971.00'
--/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134688.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134689.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('135776.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('135777.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134974.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('001466.00','CLS','+',null)
/

-- select assetno from hostdb.machtab where assetno in
-- (
--'134971.00'
--,'134680.00'
--,'134688.00'
--,'134689.00'
--,'135776.00'
--,'135777.00'
--,'134974.00'
--,'001466.00'
-- )
--/
