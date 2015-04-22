-- $Id: mu_lti.sql,v 1.2 2007/02/20 15:09:27 yangl Exp $
--

set define on

--
-- mu.lti cluster
--

-- Master
--mu.lti.cs.cmu.edu   138273.00     Dell PE-2850    1d7h3b1     128.2.207.11
-- Rack
--138272.00
-- Slaves (10/10)
--mu01.lti.cs.cmu.edu     138799.00     SunFire X2100   0622fu4067  192.168.1.101
--mu02.lti.cs.cmu.edu     138800.00     SunFire X2100   0622fu406p  192.168.1.102
--mu03.lti.cs.cmu.edu     138801.00     SunFire X2100   0622fu406u  192.168.1.103
--mu04.lti.cs.cmu.edu     138802.00     SunFire X2100   0622fu406q  192.168.1.104
--mu05.lti.cs.cmu.edu     138803.00     SunFire X2100   0622fu4041  192.168.1.105
--mu06.lti.cs.cmu.edu     138804.00     SunFire X2100   0622fu3010  192.168.1.106
--mu07.lti.cs.cmu.edu     001462.00     SunFire X2200   0649qat0fb  192.168.1.107
--mu08.lti.cs.cmu.edu     001463.00     SunFire X2200   0649qat0f0  192.168.1.108
--mu09.lti.cs.cmu.edu     001464.00     SunFire X2200   0649qat100  192.168.1.109
--mu10.lti.cs.cmu.edu     001465.00     SunFire X2200   0649qat0f8  192.168.1.110

-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138273.00','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '138272.00'
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
 where assetno='138273.00'
/

-- slave nodes

-- TODO: delete before production release
update hostdb.capequip
   set assetnum='001464.00'
 where assetnum='001464'
/

-- TODO: delete before production release
update hostdb.capequip
   set assetnum='001462.00'
 where assetnum='001462'
/

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
         where assetno='138273.00'
        )
 where assetno in 
('138799.00' ,'138800.00' ,'138801.00' ,'138802.00' ,'138803.00' ,'138804.00' ,'001462.00' ,'001463.00' ,'001464.00', '001465.00')
/

--insert into hostdb.machtab 
--    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
--    ,charge_by ,dist_src ,project ,subproject
--    )
--select
--    '138804.00'
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
-- where assetno='138273.00'
--/

insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '001462.00'
    ,cputype
    ,cpumodel
    ,usrprinc   
    ,prjprinc
    ,dist
    ,charge_by
    ,dist_src
    ,project
    ,subproject
  from hostdb.machtab
 where assetno='138273.00'
/

insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '001463.00'
    ,cputype
    ,cpumodel
    ,usrprinc   
    ,prjprinc
    ,dist
    ,charge_by
    ,dist_src
    ,project
    ,subproject
  from hostdb.machtab
 where assetno='138273.00'
/

insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '001464.00'
    ,cputype
    ,cpumodel
    ,usrprinc   
    ,prjprinc
    ,dist
    ,charge_by
    ,dist_src
    ,project
    ,subproject
  from hostdb.machtab
 where assetno='138273.00'
/

insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '001465.00'
    ,cputype
    ,cpumodel
    ,usrprinc   
    ,prjprinc
    ,dist
    ,charge_by
    ,dist_src
    ,project
    ,subproject
  from hostdb.machtab
 where assetno='138273.00'
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138799.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138800.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138801.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138802.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138803.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138804.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('001462.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('001463.00','CLS','+',null)
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('001464.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('001465.00','CLS','+',null)
/

