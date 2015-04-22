-- $Id: undo_data_insert.sql,v 1.2 2007/02/09 19:39:41 yangl Exp $
--

delete from hostdb.cost
 where service_id=122 or service_id=123
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
delete from hostdb.services
where id=122
   or id=123
/


--
-- mach_equiv
--
-- Dummy/Logical Nodes
delete from hostdb.mach_equiv
where cputype like 'CL-%'
/
--where CPUType in ( 'CL-Dummy', 'CL-M-Dell', 'CL-S-Dell','CL-S-SUN')

--
-- Category_map
--
delete from hostdb.category_map
where Subtype in ('C-S','C-L', 'C-M', 'C-R')
   or ngeneric like 'CLUSTER%'
/

delete from hostdb.generics
where name like 'CLUSTER-%'
/

delete from hostdb.categories
where  name like 'M-CL-%'
/

delete from hostdb.cputypes
 where name like 'CL-%'
/

--
-- Protocols
--
