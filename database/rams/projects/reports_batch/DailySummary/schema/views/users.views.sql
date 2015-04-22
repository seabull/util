-- $Id: users.views.sql,v 1.6 2006/09/18 14:47:13 yangl Exp $
--

--
-- Make sure ccreport has the following priv granted (not thru roles)
--
-- grant select on aud_hostdb.who to ccreport;
grant select on hostdb.name to ccreport;
grant select on hostdb.principal to ccreport;
--grant select on aud_hostdb.name to ccreport;
--grant select on aud_hostdb.principal to ccreport;
grant select on aud_hostdb.who_attr to ccreport with grant option;

--
-- prepare asof views
--
exec asofv_pkg.vcreate('aud_hostdb','who','ccreport','who_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','who','ccreport','who_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','name','ccreport','name_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','name','ccreport','name_asofv_2', '2');

exec asofv_pkg.vcreate('aud_hostdb','principal','ccreport','principal_asofv_1', '1');
exec asofv_pkg.vcreate('aud_hostdb','principal','ccreport','principal_asofv_2', '2');

--
-- prepare asof views
--
-- Use gen_sql.pl and template file to generate those views
--create or replace view ccreport.who_touched_v
--as
--select
--	x.*
--  from
--(
--	select
--		b.*
--		,case when row_number over (partition by aud_urowid order by aud_ts desc)=1 then
--			aud_action
--		end rowflag
--	  from aud_hostdb.who b
--	 where aud_ts >= (	select ts 
--				  from utility.asofv_param
--				 where id=(select max(id) from utility.asofv_param where flag='1')
--			)
--	   and aud_ts <= (	select ts 
--				  from utility.asofv_param
--				 where id=(select max(id) from utility.asofv_param where flag='2')
--			)
--) x
-- where x.rowflag is not null
--/

create or replace view ccreport.who_touched_princ_v
as
select
	princ
  from ccreport.who_touched_v
union
select
	princ
  from ccreport.who_servicelevel_diff_v
/

create or replace view ccreport.who_changed_v
as
select
	w.princ
	--,w.rowflag
	,w.sponsor
	,w.dept
	,w.project
	,w.subproject
	,w.dist
	,w.pct
	,w.charge_by
	--,svc.services
	,(select svc.services from ccreport.who_servicelevel_asofv2 svc where svc.princ=w.princ and w.dist is not null) services
	,w.aud_change_id
	,(select OS_USER_NAME||'-'||session_userid from aud.change_session_log_details_v where change_id=w.aud_change_id) os_user_name
	,w.aud_ts
	,(	select max(aud_ts)
		  from aud_hostdb.who_attr 
		 where princ=w.princ 
		   and aud_ts <= (	select ts
					  from UTILITY.asofv_param
					 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
				)
	) wa_aud_ts
	,w.aud_urowid
	,n.name
	,n.pri
	,n.emp_num
	,'NEW' comment_flag
  from ccreport.who_asofv_2 w
	, ccreport.name_asofv_2 n
	, ccreport.principal_asofv_2 p
	--, ccreport.who_servicelevel_asofv2 svc
 where w.princ=p.princ
   and p.name=n.princ
   and n.pri=0
--   and w.princ=svc.princ(+)
   and w.princ in (select princ from ccreport.who_touched_princ_v)
union
select
	w.princ
	--,w.rowflag
	,w.sponsor
	,w.dept
	,w.project
	,w.subproject
	,w.dist
	,w.pct
	,w.charge_by
	--,svc.services
	,(select svc.services from ccreport.who_servicelevel_asofv1 svc where svc.princ=w.princ and w.dist is not null) services
	,w.aud_change_id
	,(select OS_USER_NAME||'-'||session_userid from aud.change_session_log_details_v where change_id=w.aud_change_id) os_user_name
	,w.aud_ts
	,w.aud_ts
	,w.aud_urowid
	,n.name
	,n.pri
	,n.emp_num
	,'OLD' comment_flag
  from ccreport.who_asofv_1 w
	, ccreport.name_asofv_1 n
	, ccreport.principal_asofv_1 p
	--, ccreport.who_servicelevel_asofv1 svc
 where w.princ=p.princ
   and p.name=n.princ
--   and w.princ=svc.princ(+)
   and n.pri=0
   and w.princ in (select princ from ccreport.who_touched_princ_v)
/

--
-- who configuration
--
--create or replace view ccreport.who_touched_namev
--as
--select
--	w.princ
--	,w.rowflag
--	,w.sponsor
--	,w.dept
--	,w.project
--	,w.subproject
--	,w.dist
--	,w.pct
--	,w.aud_change_id
--	,(select OS_USER_NAME||'-'||session_userid from aud.change_session_log_details_v where change_id=w.aud_change_id) os_user_name
--	,w.aud_ts
--	,w.aud_urowid
--	,n.name
--	,n.pri
--	,n.emp_num
--	--,case when w.rowflag='D' then
--	--	(	select OS_USER_NAME 
--	--		  from ccreport.who_touchedbefore_v before
--	--			, aud.change_session_log_details_v audit1 
--	--		 where before.aud_urowid=w.aud_urowid
--	--		   and audit1.change_id=before.aud_change_id
--	--	)
--	--end last_os_user_name
--  from ccreport.who_touched_v w
--	, hostdb.name n
--	, hostdb.principal p
-- where w.princ=p.princ
--   and p.name=n.princ
--   and n.pri=0
--/
