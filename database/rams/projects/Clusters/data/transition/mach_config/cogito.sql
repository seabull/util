-- $Id: cogito.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
--

set define on

--
-- cognito cluster
--

define mainassetno='137849.00'
define clustername='cognito'

-- master node
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','137849.00','Cluster Head', 'yes',null,'cluster &clustername head','N')
/

-- rack
insert into hostdb.mach_config 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','136621.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
    ('136621.00','136621.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
/

-- slave nodes

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137828.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137828.00','137828.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137829.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137829.00','137829.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137830.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137830.00','137830.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137831.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137831.00','137831.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137832.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137832.00','137832.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137833.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137833.00','137833.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137834.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137834.00','137834.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137835.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137835.00','137835.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137836.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137836.00','137836.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137837.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137837.00','137837.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137838.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137838.00','137838.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137839.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137839.00','137839.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137840.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137840.00','137840.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137841.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137841.00','137841.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137842.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137842.00','137842.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137843.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137843.00','137843.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137844.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137844.00','137844.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137845.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137845.00','137845.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137846.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137846.00','137846.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137847.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137847.00','137847.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','137848.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
    ('137848.00','137848.00','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

