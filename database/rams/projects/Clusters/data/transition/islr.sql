-- $Id: islr.sql,v 1.2 2007/02/20 15:09:27 yangl Exp $
--

set define on

--
-- Master
--134647.00 DELL       PowerEdge            1850
--
-- Rack
--134646.00
-- Slaves (9/9)
--134648.00   DELL    PowerEdge
--134649.00   DELL    PowerEdge
--134356.00   DELL    PowerEdge
--134937.00   DELL    PowerEdge
--134938.00   DELL    PowerEdge
--134941.00   DELL    PowerEdge
--134942.00   DELL    PowerEdge
--134943.00   DELL    PowerEdge
--134944.00   DELL    PowerEdge



-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134647.00','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '134646.00'
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
 where assetno='134647.00'
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
         where assetno='134647.00'
        )
 where assetno in 
('134937.00' ,'134938.00' ,'134941.00' ,'134942.00' ,'134943.00' ,'134944.00' ,'134648.00' ,'134649.00' ,'139356.00')
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134937.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134938.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134941.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134942.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134943.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134944.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134648.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('134649.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('139356.00','CLS','+',null)
/

-- select assetno from hostdb.machtab where assetno in
-- (
--'134937.00'
--,'134938.00'
--,'134941.00'
--,'134942.00'
--,'134943.00'
--,'134944.00'
--,'134648.00'
--,'134649.00'
--,'139356.00'
-- )
--/
