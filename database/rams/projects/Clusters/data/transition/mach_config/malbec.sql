-- $Id: malbec.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
--

set define on

define mainassetno='139354.01'
define clustername='malbec'
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
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','139354.01','Cluster Head', 'yes',null,'cluster &clustername head node','N')
/

-- rack
insert into hostdb.machtab 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
    ('139354.00','139354.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
/

-- slave nodes

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.03','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.03','139354.03','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.04','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.04','139354.04','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.05','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.05','139354.05','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.06','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.06','139354.06','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.07','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.07','139354.07','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.08','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.08','139354.08','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.09','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.09','139354.09','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.10','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.10','139354.10','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.11','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.11','139354.11','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.12','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.12','139354.12','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.13','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.13','139354.13','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139354.14','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    ('139354.14','139354.14','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

