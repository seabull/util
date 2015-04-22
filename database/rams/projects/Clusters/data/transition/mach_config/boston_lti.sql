-- $Id: boston_lti.sql,v 1.3 2007/06/06 15:23:20 yangl Exp $
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
--
-- ASSETNO                                                        VARCHAR2(9)
-- DEVASSETNO                                                     VARCHAR2(9)
-- DEVTYPE                                                        VARCHAR2(20)
-- EXTERNAL                                                       VARCHAR2(3)
-- DESCRIPTION                                                    VARCHAR2(70)
-- COMMNTS                                                        VARCHAR2(70)
-- EXT                                                            CHAR(1)

define mainassetno='138263.00'
define clustername='boston.lti'

-- master node
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('&mainassetno','&mainassetno', 'Cluster Head', 'yes','','cluster &clustername head node','N')
/

-- rack
insert into hostdb.mach_config 
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('137455.00','137455.00', 'Cluster Rack', 'yes','','cluster &clustername rack','N')
    --('&mainassetno','137455.00', 'Cluster Rack', 'yes','','cluster &clustername rack','N')
/

-- slave nodes
insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('138765.00','138765.00','Cluster Slave','yes','cluster &clustername slave','N')
    --('&mainassetno','138765.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('138766.00','138766.00','Cluster Slave','yes','cluster &clustername slave','N')
    --('&mainassetno','138766.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138767.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138767.00','138767.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138768.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138768.00','138768.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    ('138769.00','138769.00','Cluster Slave','yes','cluster &clustername slave','N')
    --('&mainassetno','138769.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138770.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138770.00','138770.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138771.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138771.00','138771.00','Cluster Slave','yes','cluster &clustername slave','N')
/

insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138772.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138772.00','138772.00','Cluster Slave','yes','cluster &clustername slave','N')
/


insert into hostdb.mach_config
    (assetno, devassetno, devtype, external, description, commnts, ext)
values
    --('&mainassetno','138773.00','Cluster Slave','yes','cluster &clustername slave','N')
    ('138773.00','138773.00','Cluster Slave','yes','cluster &clustername slave','N')
/

