-- $Id: example_usage.sql,v 1.2 2008/01/16 15:23:53 yangl Exp $
-------------------------------------------------------------
--	$Author: yangl $
--	$Date: 2008/01/16 15:23:53 $
--	$RCSfile: example_usage.sql,v $
--	$Revision: 1.2 $
-------------------------------------------------------------
--PROCEDURE VCREATE
-- Argument Name                  Type                    In/Out Default?
-- ------------------------------ ----------------------- ------ --------
-- PTBLSCHEMA                     VARCHAR2                IN
-- PTBLNAME                       VARCHAR2                IN
-- PVSCHEMA                       VARCHAR2                IN
-- PVNAME                         VARCHAR2                IN
-- PPARAMTBLFLAG                  VARCHAR2                IN     DEFAULT
-- PPARAMTBLSCHEMA                VARCHAR2                IN     DEFAULT
-- PPARAMTBLNAME                  VARCHAR2                IN     DEFAULT
--
-- exec asofv_pkg.vcreate('aud_hostdb','who','YANGL@CS.CMU.EDU','who');
-- exec asofv_pkg.vcreate('aud_hostdb','who','YANGL@CS.CMU.EDU','who_asofv_1', '1');

--exec asofv_util.set_time(to_date('20-JUN-2006','DD-MON-YYYY'), '1');
--exec asofv_util.set_time(to_date('22-JUN-2006','DD-MON-YYYY'), '2');

exec asofv_util.set_time(trunc(sysdate-2));
exec asofv_util.set_time(trunc(sysdate-1), '1');
exec asofv_util.set_time(trunc(sysdate), '2');

select
	asofv_util.get_time('1')
	,asofv_util.get_time('2')
	,asofv_util.get_time('H')
  from dual
/
