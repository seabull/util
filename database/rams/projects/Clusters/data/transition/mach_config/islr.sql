-- $Id: islr.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
--

set define on

define mainassetno='134647.00'
define clustername='islr'

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
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','134647.00','Cluster Head', 'yes','cluster &clustername head node','N')
/

-- rack
insert into hostdb.mach_config 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134646.00','Cluster Rack', 'yes','cluster &clustername rack','N')
    ('134646.00','134646.00','Cluster Rack', 'yes','cluster &clustername rack','N')
/

-- slave nodes
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134937.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134937.00','134937.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134938.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134938.00','134938.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134941.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134941.00','134941.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134942.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134942.00','134942.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134943.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134943.00','134943.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134944.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134944.00','134944.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134648.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134648.00','134648.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','134649.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('134649.00','134649.00','Cluster Slave','yes','cluster &clustername slave node','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','139356.00','Cluster Slave','yes','cluster &clustername slave node','N')
    ('139356.00','139356.00','Cluster Slave','yes','cluster &clustername slave node','N')
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
