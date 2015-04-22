-- $Id: summary.sql,v 1.5 2006/09/26 15:15:28 costing Exp $
-------------------------------------------------------------
--	$Author: costing $
--	$Date: 2006/09/26 15:15:28 $
--	$RCSfile: summary.sql,v $
--	$Revision: 1.5 $
-------------------------------------------------------------
set pagesize 50000
set linesize 1000
whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

set colsep ','
set heading off
set feedback off
set define on
set termout on

column distribution format a420 truncated
column services format a24 truncated

define sumfile=&1

@@init.sql

spool &sumfile
select
	',,Daily Change Summary Report generated on '|| to_char(sysdate, 'YYYY-Mon-DD')
  from dual
/

select
	'Start-Time'
	||','||to_char(asofv_util.get_time('1'), 'YYYY-Mon-DD HH24:MI')
  from dual
/

select
	'End-Time'
	||','||to_char(asofv_util.get_time('2'), 'YYYY-Mon-DD HH24:MI')
  from dual
/

select
	'Users'
  from dual
/

prompt ,

select
	'Flag'
	,'Name'
	,'Princ'
	,'Pri'
	,'Services'
	,'Distribution'
	,'Sponsor'
	,'Pct'
	,'Emp_num'
	,'Dept'
	,'Project'
	,'Subproject'
	,'ChargeBy'
	,'LastChangeBy'
	,'LastChangeTime'
	,'DistID*'
	,'ChangeID*'
  from dual
/
	
select
	case when count(comment_flag) over (partition by princ)=1 then
		decode(comment_flag, 'NEW','Inserted','Deleted')
	else
		'Updated-'||comment_flag
	end Flag
	--,comment_flag
	,name
	,princ
	--,rowflag
	,pri
	,'"'||services||'"' services
	,(select '"'||dist_vec||'"' from ccreport.dist_string_aggr_v d where d.dist=w.dist) distribution
	,sponsor
	,pct
	,emp_num
	,dept
	,'"'||project||'"'
	,'"'||subproject||'"'
	,decode(charge_by, 'P','Hardcode', null, 'Labor', 'Unknown')
	,os_user_name
	,aud_ts
	,dist
	,aud_change_id
	--,aud_urowid
  from ccreport.who_changed_v w
order by princ
	,pri
	,name
	,comment_flag
/

select
	'Machines'
  from dual
/

select
	'Flag'
	,'hostname'
	,'assetno'
	,'priority'
	,'services'
	,'distribution'
	,'PrimaryUser'
	,'os'
	,'bldg'
	,'rm'
	,'project'
	,'subproject'
	,'qual'
	,'charge_by'
	,'dist_src'
	,'ProjectContact'
	,'EquipContact'
	,'protocol'
	,'cputype'
	,'cpumodel'
	,'dept'
	,'suffix'
	,'warranty_expire'
	,'LastChangeBy'
	,'LastChangeTime'
	,'dist'
	--,last_change_id
	--,hoststab_change_id
	--,machtab_change_id
	--,capequip_change_id
	--,host_os_user_name
	--,mach_os_user_name
	--,equip_os_user_name
  from dual
/

select
	case when count(comment_flag) over (partition by assetno, pri)=1 then
		decode(comment_flag, 'NEW','Inserted','Deleted')
	else
		'Updated-'||comment_flag
	end Flag
	,hostname
	,assetno
	--,comment_flag
	--,rowflag
	,pri
	,'"'||services||'"' services
	,(select '"'||dist_vec||'"' from ccreport.dist_string_aggr_v d where d.dist=hmc.dist) distribution
	,usrprinc
	,os
	,bldg
	,rm
	,'"'||project||'"'
	,'"'||subproject||'"'
	,(select keyword from hostdb.qualifiers where code=hmc.qual) qualifier
	,decode(charge_by, 'P','Hardcode',null,'FollowUser','Unknown')
	,dist_src
	,prjprinc
	,princ
	,protocol
	,cputype
	,cpumodel
	,dept
	,suffix
	,warranty_expire
	,(	select '"' || OS_USER_NAME || '","' || change_ts || '"'
		  from aud.change_session_log_details_v c
		 where c.change_id=(select max(x.aud_change_id)
				    from
					(	
					select ih.aud_change_id, ih.assetno
					  from ccreport.hoststab_asofv_2 ih
					 --where ih.assetno=h.assetno
					union
					select im.aud_change_id, im.assetno
					  from ccreport.machtab_asofv_2 im
					 --where im.assetno=h.assetno
					union
					select ic.aud_change_id, ic.assetnum
					  from ccreport.capequip_asofv_2 ic
					 --where ic.assetnum=h.assetno
					union
					select iha.aud_change_id, ih.assetno
					  from ccreport.host_attr_asofv_2 iha
						,ccreport.hoststab_asofv_2 ih
					 where iha.hostname=ih.hostname
					union
					select ima.aud_change_id, ima.assetno
					  from ccreport.mach_attr_asofv_2 ima
					) x
				    where x.assetno=hmc.assetno
				)
	) host_os_user_name
	,dist
	--,last_change_id
	--,hoststab_change_id
	--,machtab_change_id
	--,capequip_change_id
	--,host_os_user_name
	--,mach_os_user_name
	--,equip_os_user_name
  from ccreport.hostsmachcapsvc2_changed_v hmc
order by assetno
	,pri
	,hostname
	,comment_flag
/

select
	'Named Distributions'
  from dual
/

select
	'Flag'
	,'Project'
	,'Subproject'
	,'Percent'
	,'Source'
	,'Distribution'
	,'User_Only'
	,'LastChangeTime'
	,'LastChangeBy'
	,'ChangeID'
  from dual
/

select
	case when count(comment_flag) over (partition by name, subname)=1 then
		decode(comment_flag, 'NEW','Inserted','Deleted')
	else
		'Updated-'||comment_flag
	end Flag
	,'"'||name||'"'
	,'"'||subname||'"'
	,pct
	,src
	,(select '"'||dist_vec||'"' from ccreport.dist_string_aggr_v d where d.dist=dn.dist) distribution
	,user_only
	,aud_ts
	,(select os_user_name from aud.change_session_log_details_v c where c.change_id=aud_change_id and rownum<2) os_user_name
	,aud_change_id
  from ccreport.dist_names_diff_v dn
/
spool off
set linesize 80
set colsep " "
set heading on
set feedback on
set termout on

quit
