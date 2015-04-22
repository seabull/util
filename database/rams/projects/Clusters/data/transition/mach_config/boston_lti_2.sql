-- $Id: boston_lti_2.sql,v 1.1 2007/06/12 15:12:24 yangl Exp $
--

set define on

--
-- boston.lti cluster addition
--

--     #139417.00     
--     #139417.01     
--     #139417.02     
--     #139417.03     
--     #139417.04     
--     #139417.05     
--     #139417.06     
--     #139417.07     
--     #139417.08     
--     #139417.09     
--
-- ASSETNO                                                        VARCHAR2(9)
-- DEVASSETNO                                                     VARCHAR2(9)
-- DEVTYPE                                                        VARCHAR2(20)
-- EXTERNAL                                                       VARCHAR2(3)
-- DESCRIPTION                                                    VARCHAR2(70)
-- COMMNTS                                                        VARCHAR2(70)
-- EXT                                                            CHAR(1)

define mainassetno='139417.00'
define clustername='boston.lti'

-- master node
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','&mainassetno', 'Cluster Head', 'yes',null,'cluster &clustername 2nd head node','N')
/

-- rack
-- already in DB.

-- slave nodes
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.01','139417.01','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.01','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.02','139417.02','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.02','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.03','139417.03','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.03','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.04','139417.04','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.04','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.05','139417.05','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.05','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.06','139417.06','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.06','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.07','139417.07','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.07','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.08','139417.08','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.08','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('139417.09','139417.09','Cluster Slave','yes',null,'cluster &clustername slave','N')
    --('&mainassetno','139417.09','Cluster Slave','yes',null,'cluster &clustername slave','N')
/

