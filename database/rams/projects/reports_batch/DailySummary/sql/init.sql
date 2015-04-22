-- $Id: init.sql,v 1.1 2006/09/08 21:24:43 yangl Exp $
-------------------------------------------------------------
--	$Author: yangl $
--	$Date: 2006/09/08 21:24:43 $
--	$RCSfile: init.sql,v $
--	$Revision: 1.1 $
-------------------------------------------------------------
--exec asofv_util.set_time(to_date('20-JUN-2006','DD-MON-YYYY'), '1');
--exec asofv_util.set_time(to_date('22-JUN-2006','DD-MON-YYYY'), '2');

exec asofv_util.set_time(trunc(sysdate-1), '1');
exec asofv_util.set_time(trunc(sysdate), '2');

select
	asofv_util.get_time('1')
	,asofv_util.get_time('2')
	,asofv_util.get_time('h')
  from dual
/
