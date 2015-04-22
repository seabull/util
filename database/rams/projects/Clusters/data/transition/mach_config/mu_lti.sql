-- $Id: mu_lti.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
--

set define on

define mainassetno='138273.00'
define clustername='mu.lti'
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
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','138273.00','Cluster Head', 'yes',null,'cluster &clustername head node','N')
/

-- rack
insert into hostdb.mach_config 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138272.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
    ('138272.00','138272.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
/

-- slave nodes

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138799.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138799.00','138799.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138800.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138800.00','138800.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138801.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138801.00','138801.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138802.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138802.00','138802.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138803.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138803.00','138803.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138804.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('138804.00','138804.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','001462.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('001462.00','001462.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','001463.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('001463.00','001463.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/


insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','001464.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('001464.00','001464.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','001465.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('001465.00','001465.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

