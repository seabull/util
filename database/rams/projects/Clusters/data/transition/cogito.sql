-- $Id: cogito.sql,v 1.2 2007/02/20 15:09:27 yangl Exp $
--

set define on

--
-- cognito cluster
--

-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137849.00','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '136621.00'
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
 where assetno='137849.00'
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
         where assetno='137849.00'
        )
 where assetno in 
('137828.00' ,'137829.00' ,'137830.00' ,'137831.00' ,'137832.00' ,'137833.00' ,'137834.00' ,'137835.00' ,'137836.00','137837.00','137838.00','137839.00','137840.00','137841.00','137842.00','137843.00','137844.00','137845.00','137846.00','137847.00','137848.00')
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137828.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137829.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137830.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137831.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137832.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137833.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137834.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137835.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137836.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137837.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137838.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137839.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137840.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137841.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137842.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137843.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137844.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137845.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137846.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137847.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('137848.00','CLS','+',null)
/

