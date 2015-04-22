-- $Id: user_charged.sql,v 1.5 2007/07/02 16:21:33 yangl Exp $
--
--	$Author: yangl $
--	$Date: 2007/07/02 16:21:33 $
--	$RCSfile: user_charged.sql,v $
--	$Revision: 1.5 $
--

set linesize 1000
set pagesize 50000
set heading on
set feedback on
set define on
set colsep ' '

--define rptfile=&1
define rptfile=non-100pct-users.

column gendate new_value gdate

select to_char(sysdate, 'YYYYMMDDHH24') gendate
  from dual
/

spool &rptfile.&gdate

set heading off
set feedback off
select
	'Generated on,'||to_char(sysdate, 'Mon-DD-YYYY HH24:MI')
  from dual
/

set feedback on

column pct format 990.99
set heading on
select
	unique
	princ
	,(select name from nameprinc_v n where n.princ=w.princ and rownum < 2) name
	,pct
	--,sponsor
	--,(select name from nameprinc_v n where n.princ=w.sponsor and rownum < 2) sponsorname
	--,decode(charge_by, null, '3', 'P', '4') UserCase
	--,decode(charge_by, null, 'Labor', 'P', 'Hardcoded', 'Unknown'||charge_by) ChargeSrc
	--,(select description from hostdb.charge_sources where dist_src=kind) ActualChargeSrc
	--,(select descrip from hostdb.who_types wt where wt.id=w.type) UserType
  from hostdb.who w
 where dist is not null
   and pct != 100
order by princ
	, pct
/
spool off

set linesize 80
set colsep ' '
set heading on
set feedback on
quit
