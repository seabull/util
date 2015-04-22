-- $Id: boston_lti.sql,v 1.2 2007/02/20 15:09:27 yangl Exp $
--

set define on

--
-- boston.lti cluster
--

-- boston.lti.cs.cmu.edu   #138263     Dell PE-2850    1PH92B1     128.2.207.9 
--                 192.168.1.1     
-- boston01.lti.cs.cmu.edu     #138773     SunFire X2100   0622fu301a  192.168.1.89
-- boston02.lti.cs.cmu.edu     #138772     SunFire X2100   0622fu3012  192.168.1.90
-- boston03.lti.cs.cmu.edu     #138771     SunFire X2100   0622fu405g  192.168.1.91
-- boston04.lti.cs.cmu.edu     #138770     SunFire X2100   0623fu302q  192.168.1.92
-- boston05.lti.cs.cmu.edu     #138769     SunFire X2100   0622fu406w  192.168.1.93
-- boston06.lti.cs.cmu.edu     #138768     SunFire X2100   0622fu4072  192.168.1.94
-- boston07.lti.cs.cmu.edu     #138767     SunFire X2100   0622fu3018  192.168.1.95
-- boston08.lti.cs.cmu.edu     #138766     SunFire X2100   0622fu406h  192.168.1.96
-- boston09.lti.cs.cmu.edu     #138765     SunFire X2100   0622fu406x  192.168.1.97

-- master node
insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138263.00','CLH', '+', null)
/

-- rack
insert into hostdb.machtab 
    (assetno, cputype   ,cpumodel   ,usrprinc   ,prjprinc,  dist
    ,charge_by ,dist_src ,project ,subproject
    )
select
    '137455.00'
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
 where assetno='138263.00'
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
         where assetno='138263.00'
        )
 where assetno in 
('138773.00' ,'138772.00' ,'138771.00' ,'138770.00' ,'138769.00' ,'138768.00' ,'138767.00' ,'138766.00' ,'138765.00')
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138765.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138766.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138767.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138768.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138769.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138770.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138771.00','CLS','+',null)
/

insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138772.00','CLS','+',null)
/


insert into hostdb.mach_attr
    (assetno, attr, sense, notes)
values
    ('138773.00','CLS','+',null)
/

