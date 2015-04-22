-- $Id: faccluster.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
--

set define on

define mainassetno='134971.00'
define clustername='faccluster'

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
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','134971.00','Cluster Head', 'yes',null,'cluster &clustername head node','N')
/

-- rack
insert into hostdb.mach_config 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('134680.00','134680.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
    --('&mainassetno','134680.00','Cluster Rack', 'yes',null,'cluster &clustername rack','N')
/

-- slave nodes

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('134688.00','134688.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','134688.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('134689.00','134689.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','134689.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('135776.00','135776.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','135776.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('135777.00','135777.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','135777.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('134974.00','134974.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','134974.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('001466.00','001466.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
    --('&mainassetno','001466.00','Cluster Slave','yes',null,'cluster &clustername slave node','N')
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
