-- $Id: machines.views.sql,v 1.4 2006/09/13 14:36:45 yangl Exp $
--

--
-- Make sure ccreport has the following priv granted (not thru roles)
--
-- grant select on aud_hostdb.hoststab to ccreport;
-- grant select on aud_hostdb.machtab to ccreport;
-- grant select on aud_hostdb.capequip to ccreport;
grant select on aud_hostdb.host_attr to ccreport with grant option;
grant select on aud_hostdb.mach_attr to ccreport with grant option;

exec asofv_pkg.vcreate('aud_hostdb','hoststab','ccreport','hoststab_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','hoststab','ccreport','hoststab_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','machtab','ccreport','machtab_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','machtab','ccreport','machtab_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','capequip','ccreport','capequip_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','capequip','ccreport','capequip_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','host_attr','ccreport','host_attr_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','host_attr','ccreport','host_attr_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','mach_attr','ccreport','mach_attr_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','mach_attr','ccreport','mach_attr_asofv_2', '2');

--
-- assets that has configuration changed.
--
--create or replace view ccreport.asset_touched_v as
--select
--	h.assetno
--  from aud_hostdb.hoststab h
-- where aud_ts >= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='1')
--		)
--   and aud_ts <= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='2')
--		)
--union
--select
--	m.assetno
--  from aud_hostdb.machtab m
-- where aud_ts >= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='1')
--		)
--   and aud_ts <= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='2')
--		)
--union
--select
--	c.assetno
--  from aud_hostdb.capequip c
-- where aud_ts >= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='1')
--		)
--   and aud_ts <= (	select ts 
--			  from utility.asofv_param
--			 where id=(select max(id) from utility.asofv_param where flag='2')
--		)
--/

create or replace view ccreport.asset_touched_v
as
select
	assetno
  from ccreport.hoststab_touched_v
union
select
	assetno
  from ccreport.machtab_touched_v
union
select
	assetnum
  from ccreport.capequip_touched_v
union
select
	assetno
  from ccreport.host_servicelevel_diff_v
/

create or replace view ccreport.hostsmachcapsvc2_touched_2
as
SELECT
	unique
	h.assetno pseudo
	,h.hostname
	,nvl(h.pri, 0) pri
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv2 svc where h.assetno=svc.assetno and svc.pri=h.pri) services
	,h.os
	,h.protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
  FROM ccreport.hoststab_asofv_2 h
	,ccreport.machtab_asofv_2 m
	,ccreport.capequip_asofv_2 c
	--,ccreport.host_servicelevel_asofv2 svc
 WHERE h.assetno=m.assetno
   AND m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
union
SELECT
	unique
	'#'||m.assetno pseudo
	,null hostname
	,999998
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv2 svc where m.assetno=svc.assetno and svc.pri=999998) services
	,null os
	,'NA' protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
  FROM 
	ccreport.machtab_asofv_2 m
	,ccreport.capequip_asofv_2 c
	--,ccreport.host_servicelevel_asofv2 svc
 WHERE m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
   and m.assetno not in (select assetno from ccreport.hoststab_asofv_2)
/
create or replace view ccreport.hostsmachcapsvc2_touched_1
as
SELECT
	unique
	h.assetno pseudo
	,h.hostname
	,nvl(h.pri, 0) pri
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv1 svc where h.assetno=svc.assetno and svc.pri=h.pri) services
	,h.os
	,h.protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
  FROM ccreport.hoststab_asofv_1 h
	,ccreport.machtab_asofv_1 m
	,ccreport.capequip_asofv_1 c
	--,ccreport.host_servicelevel_asofv1 svc
 WHERE h.assetno=m.assetno
   AND m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
union
SELECT
	unique
	'#'||m.assetno pseudo
	,'#'||m.assetno pseudo
	,999998
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv1 svc where m.assetno=svc.assetno and svc.pri=999998) services
	,'NA' os
	,'NA' protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
  FROM 
	ccreport.machtab_asofv_1 m
	,ccreport.capequip_asofv_1 c
	--,ccreport.host_servicelevel_asofv2 svc
 WHERE m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
   and m.assetno not in (select assetno from ccreport.hoststab_asofv_1)
/


create or replace view ccreport.hostsmachcapsvc2_changed_v
as
select
	*
  from
(
	(
	select
		h.*
		,'NEW' comment_flag
	  from ccreport.hostsmachcapsvc2_touched_2 h
	minus
	select
		h.*
		,'NEW' comment_flag
	  from ccreport.hostsmachcapsvc2_touched_1 h
	)
	union
	(
	select
		h.*
		,'OLD' comment_flag
	  from ccreport.hostsmachcapsvc2_touched_1 h
	minus
	select
		h.*
		,'OLD' comment_flag
	  from ccreport.hostsmachcapsvc2_touched_2 h
	)
)
/

create or replace view ccreport.hostsmachcap2_changed_v
as
SELECT
	unique
	h.assetno pseudo
	,h.hostname
	,nvl(h.pri, 0) pri
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv2 svc where m.assetno=svc.assetno and svc.pri=h.pri) services
	,h.os
	,h.protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
	,greatest(h.aud_change_id,m.aud_change_id,c.aud_change_id) last_change_id
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=h.aud_change_id) host_os_user_name
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=m.aud_change_id) mach_os_user_name
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=c.aud_change_id) equip_os_user_name
	,h.aud_change_id hoststab_change_id
	,m.aud_change_id machtab_change_id
	,c.aud_change_id capequip_change_id
	,'NEW' comment_flag
  FROM ccreport.hoststab_asofv_2 h
	,ccreport.machtab_asofv_2 m
	,ccreport.capequip_asofv_2 c
	--,ccreport.host_servicelevel_asofv2 svc
 WHERE h.assetno(+)=m.assetno
   AND m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
union
SELECT
	unique
	h.assetno pseudo
	,h.hostname
	,nvl(h.pri, 0) pri
	--,svc.services
	,(select svc.services from ccreport.host_servicelevel_asofv2 svc where m.assetno=svc.assetno and svc.pri=h.pri) services
	,h.os
	,h.protocol
	,m.cputype
	,m.cpumodel
	,m.prjprinc
	,m.usrprinc
	,m.project
	,m.subproject
	,m.assetno
	,m.charge_by
	,m.dist
	,m.dist_src
	,c.dept
	,c.bldg
	,c.rm
	,c.suffix
	,c.warranty_expire
	,c.princ
	,c.qual
	,greatest(h.aud_change_id,m.aud_change_id,c.aud_change_id) last_change_id
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=h.aud_change_id) host_os_user_name
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=m.aud_change_id) mach_os_user_name
	,(select OS_USER_NAME from aud.change_session_log_details_v where change_id=c.aud_change_id) equip_os_user_name
	,h.aud_change_id hoststab_change_id
	,m.aud_change_id machtab_change_id
	,c.aud_change_id capequip_change_id
	,'OLD' comment_flag
  FROM ccreport.hoststab_asofv_1 h
	,ccreport.machtab_asofv_1 m
	,ccreport.capequip_asofv_1 c
	--,ccreport.host_servicelevel_asofv1 svc
 WHERE h.assetno(+)=m.assetno
   AND m.assetno=c.assetnum
   --and svc.assetno(+)=m.assetno
   and m.assetno in (select assetno from ccreport.asset_touched_v)
/

