-- $Id: data_insert.sql,v 1.3 2007/02/20 20:10:47 yangl Exp $
--

spool data_insert.log

--
-- attrs
--
-- CODE                                                  NOT NULL VARCHAR2(3)
-- DESCRIPTION                                           NOT NULL VARCHAR2(30)
-- ALLOWED                                               NOT NULL VARCHAR2(3)
insert into hostdb.attrs
    (code, description, allowed)
values
    ('CLH', 'Cluster Master/Head node', 'M')
/

insert into hostdb.attrs
    (code, description, allowed)
values
    ('CLS', 'Cluster Slave node', 'M')
/

insert into hostdb.attrs
    (code, description, allowed)
values
    ('CLD', 'Cluster Dummy node', 'M')
/

insert into hostdb.attrs
    (code, description, allowed)
values
    ('CLR', 'Cluster Rack', 'M')
/

--
-- generics
--
-- NAME                                                  NOT NULL VARCHAR2(11)
-- NO_NET                                                         CHAR(1)
-- NO_HARDWARE                                                    CHAR(1)
-- NOT_OURS                                                       CHAR(1)

insert into hostdb.generics
    (name   ,no_net ,no_hardware    ,not_ours)
values
    ('RACK' ,'Y'    ,'Y'            ,'Y')
/

--
-- categories
--
-- NAME                                                  NOT NULL VARCHAR2(35)
-- DESCRIPTION                                           NOT NULL VARCHAR2(70)
-- FLAGS                                                          VARCHAR2(3)
insert into hostdb.categories
    (Name   ,Description        ,Flags)
values
    ('M-CL-NODE'    ,'Cluster Slave Node Charge for all platforms'         ,null)
/

insert into hostdb.categories
    (Name   ,Description        ,Flags)
values
    ('M-CL-RACK'    ,'Cluster General Rack Charge for all platforms'     ,null)
/

insert into hostdb.categories
    (Name   ,Description        ,Flags)
values
    ('M-CL-HEAD'    ,'Cluster General Rack Charge for all platforms'     ,null)
/


--
-- Services
--
-- ID                                                    NOT NULL NUMBER(3)
-- CATEGORY                                                       VARCHAR2(40)
-- ATTR                                                           VARCHAR2(10)
-- DESCRIPTION                                                    VARCHAR2(1)
-- MONTHLY                                                        VARCHAR2(1)
-- TYPE                                                  NOT NULL VARCHAR2(1)
-- SUBTYPE                                               NOT NULL VARCHAR2(3)
-- OS                                                             VARCHAR2(10)
-- GENERIC                                                        VARCHAR2(11)
-- OTHER                                                          VARCHAR2(10)
-- OS_CLASS                                                       VARCHAR2(10)
-- ATTR2                                                          VARCHAR2(10)
-- SPECIFIC                                                       VARCHAR2(11)
-- WEBCODE                                                        VARCHAR2(3)

-- TODO: attr2 value verification.
insert into hostdb.services
    (id, category, attr, description, monthly, type, subtype, os, generic, other, os_class, attr2, specific, webcode)
values
    --id,   category,   attr,   description,    monthly,    type,   subtype,
    (122,   'M-CL-NODE','CLS',    null,           3,          'M',    'C-S',
    null, null,         null,   null,       null,  null,       'CS')
    --os, generic,      other,  os_class,   attr2,  specific,   webcode)
/
    --null, 'CLUSTER-S',      null,   null,       'C-N',  null,       'C')

insert into hostdb.services
    (id, category, attr, description, monthly, type, subtype, os, generic, other, os_class, attr2, specific, webcode)
values
    --id,   category,   attr,   description,    monthly,    type,   subtype,
    (123,   'M-CL-RACK','CLR',    null,           3,          'M',    'C-R',
    null, 'RACK',      null,   null,       null,  null,       'CR')
    --os, generic,          other,  os_class,   attr2,  specific,   webcode)
/

insert into hostdb.services
    (id, category, attr, description, monthly, type, subtype, os, generic, other, os_class, attr2, specific, webcode)
values
    --id,   category,   attr,   description,    monthly,    type,   subtype,
    (124,   'M-CL-HEAD','CLH',    null,           3,          'M',    'C-H',
    null, null,         null,   null,       null,  null,       'CH')
    --os, generic,      other,  os_class,   attr2,  specific,   webcode)
/

--
-- cost
--
-- SERVICE_ID                                            NOT NULL NUMBER(3)
-- PERIOD_BEGIN                                          NOT NULL DATE
-- PERIOD_END                                                     DATE
-- AMOUNT                                                NOT NULL NUMBER(7,2)

insert into hostdb.cost
    (service_id ,period_begin   ,period_end ,amount)
values
    (122,       to_date('FEB-01-2006','MON-DD-YYYY')       ,null       ,7)
/
    --(122,       to_date('FEB-01-2007','MON-DD-YYYY')       ,null       ,7)

insert into hostdb.cost
    (service_id ,period_begin   ,period_end ,amount)
values
    (123,       to_date('FEB-01-2006','MON-DD-YYYY')       ,null       ,150)
/
    --(123,       to_date('FEB-01-2007','MON-DD-YYYY')       ,null       ,150)

insert into hostdb.cost
    (service_id ,period_begin   ,period_end ,amount)
values
    (124,       to_date('FEB-01-2006','MON-DD-YYYY')       ,null       ,0)
/
    --(124,       to_date('FEB-01-2007','MON-DD-YYYY')       ,null       ,0)

--
-- Qualifiers
--
-- CODE                                                  NOT NULL CHAR(1)
-- KEYWORD                                               NOT NULL CHAR(13)
-- DESCRIPTION                                           NOT NULL CHAR(60)
-- NO_CHARGE                                                      CHAR(1)
-- NO_ATTR                                                        CHAR(1)
-- NO_NET                                                         CHAR(1)
-- NO_SOFTWARE                                                    VARCHAR2(1)

--
-- mach_equiv
--
-- CPUTYPE                                               NOT NULL VARCHAR2(10)
-- CPUMODEL                                              NOT NULL VARCHAR2(20)
-- GENERIC                                               NOT NULL VARCHAR2(11)
-- SPECIFIC                                                       VARCHAR2(11)

-- | *cputype* | *cpumodel* | *generic* | *specific* |
-- | CL-Dummy | Logical | CLUSTER-L | null |
-- | CL-M-Dell | PowerEdge | CLUSTER-M | null |

-- Dummy/Logical Nodes
--insert into hostdb.mach_equiv
--    (CPUType,   CPUModel,   Generic,    Specific)
--values
--    ('CL-DUMMY', 'LOGICAL', 'CLUSTER-L',null)
--/

-- Cluster Rack
--insert into hostdb.mach_equiv
--    (CPUType,   CPUModel,   Generic,    Specific)
--values
--    ('CL-R-RACK', 'LOGICAL', 'CLUSTER-R',null)
--/
insert into hostdb.mach_equiv
    (CPUType,   CPUModel,   Generic,    Specific)
values
    ('RACK', 'LOGICAL', 'RACK',null)
/


--
-- Category_map
--
-- TYPE                                                  NOT NULL VARCHAR2(1)
-- SUBTYPE                                               NOT NULL VARCHAR2(3)
-- OS                                                             VARCHAR2(10)
-- GENERIC                                                        VARCHAR2(11)
-- OTHER                                                          VARCHAR2(10)
-- CAT                                                            VARCHAR2(1)
-- NOS                                                            VARCHAR2(10)
-- NGENERIC                                                       VARCHAR2(11)

-- 
-- hostsmachcap view requires ngeneric/nos to be null for non-costed hosts
--
insert into hostdb.category_map
    (Type   ,Subtype    ,OS     ,Generic    ,Other  ,Cat    ,Nos    ,NGeneric)
values
    ('M'    ,'C-R'      ,null   ,'RACK',null   ,null   ,null   ,null)
/
    
--insert into hostdb.category_map
--    (Type   ,Subtype    ,OS     ,Generic    ,Other  ,Cat    ,Nos    ,NGeneric)
--values
--    ('M'    ,'C-S'      ,null   ,'CLUSTER-S',null   ,null   ,null   ,null)
--/
--
--insert into hostdb.category_map
--    (Type   ,Subtype    ,OS     ,Generic    ,Other  ,Cat    ,Nos    ,NGeneric)
--values
--    ('M'    ,'C-L'      ,null   ,'CLUSTER-L',null   ,null   ,null   ,null)
--/
--
--insert into hostdb.category_map
--    (Type   ,Subtype    ,OS     ,Generic    ,Other  ,Cat    ,Nos    ,NGeneric)
--values
--    ('M'    ,'C-R'      ,null   ,'CLUSTER-R',null   ,null   ,null   ,null)
--/


--
-- Protocols
--
-- Name                                                  Null?    Type
-- ----------------------------------------------------- -------- -----------
-- NAME                                                  NOT NULL VARCHAR2(3)
-- DESCRIPTION                                           NOT NULL VARCHAR2(20)
-- COSTED                                                NOT NULL CHAR(1)
-- ALIASED                                                        CHAR(1)
-- HOSTNAME_CONTEXT                                               VARCHAR2(10)
-- IPADDRESS_CONTEXT                                              VARCHAR2(10)

-- NAM DESCRIPTION          C A HOSTNAME_C IPADDRESS_
-- --- -------------------- - - ---------- ----------
-- OLD Old IP Address       Y Y host       ipv4
-- AFS AFS Database Server  N   domain     host
-- SRV Service Location     N   domain
-- TXT Textual Data         N   domain
-- IP  Internet Protocol    Y Y host       ipv4
-- AT  AppleTalk Protocol   Y
-- MX  Mail forwarding      N Y host       host
-- NS  Name server          N   domain     host
-- NA  Not applicable       Y
-- CNM Canonical name link  N   domain     domain
-- AA  Address alias        N   host       host
-- DYN Dynamic DHCP Address N   host

-- To be added
-- CL  Cluster Logical      Y   host       ?
-- CM  Cluster Master Node  Y
-- CS  Cluster Slave Node   Y

-- Do Not use protocol.
--insert into hostdb.protocols
--    (Name, Description, Costed, Aliased, Hostname_Context, Ipaddress_Context)
--    values
--    ('CL','Cluster Logical', 'Y', null, null, null)
--/
--
--insert into hostdb.protocols
--    (Name, Description, Costed, Aliased, Hostname_Context, Ipaddress_Context)
--    values
--    ('CM','Cluster Master Node', 'Y', null, null, null)
--/
--
--insert into hostdb.protocols
--    (Name, Description, Costed, Aliased, Hostname_Context, Ipaddress_Context)
--    values
--    ('CS','Cluster Slave Node', 'Y', null, null, null)
--/
--


--
-- machine/capequip/hosts
--

spool off
