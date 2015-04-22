set linesize 1000
column AUD_UROWID format a20
column AUD_TS format a30

spool audit_data.lst
select 
	aud_change_id
	,aud_change_flag
	,aud_action
	,aud_ts
	,princ
	,dist
	,pct
	,dist_src
	,charge_by
	,sponsor
	,type
	,project
	,subproject 
  from aud_hostdb.who 
 where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
   and aud_ts < to_timestamp('02-NOV-05 02.58.35.508603 AM')
/

--
-- dist_names changes
-- Note: those changes took effect for machines but did not populate thru for users.
--
select 
	aud_change_id
	,aud_change_flag
	,aud_action
	,aud_ts
	,dist
	,name
	,subname
	,user_only
	,src
	,pct
  from aud_hostdb.dist_names
 where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
   and aud_ts < to_timestamp('02-NOV-05 01.58.35.508603 AM')
order by aud_ts
/
--02-NOV-05 01.06.35.508603 AM
--02-NOV-05 01.57.54.439005 AM
-- where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
--   and aud_ts < to_timestamp('02-NOV-05 01.58.35.508603 AM')
-- where aud_ts > to_date('11-01-2005','MM-DD-YYYY')
--   and aud_ts < to_date('11-03-2005','MM-DD-YYYY')

--
-- check whether anything updated in who in peopleDistNamesApply
--
select
	*
  from aud_hostdb.who 
 where aud_ts > to_timestamp('02-NOV-05 01.57.54.439005 AM')
   and aud_ts < to_timestamp('02-NOV-05 02.58.35.508603 AM')
/

--
-- dist_names changes in peopleDistNamesApply
--
select 
	d.name
	--,d.subname
	,count(*)
  from aud_hostdb.dist_names d
	,(select 
		aud_change_id
		,aud_change_flag
		,aud_action
		,aud_ts
		,dist
		,name
		,subname
		,user_only
		,src
		,pct
	  from aud_hostdb.dist_names
	 where aud_ts > to_timestamp('02-NOV-05 01.05.35.508603 AM')
	   and aud_ts < to_timestamp('02-NOV-05 01.58.35.508603 AM')
	) x
 where d.aud_ts > to_date('11-01-2005','MM-DD-YYYY')
   and d.name=x.name
   and d.subname=x.subname
group by d.name
--	, d.subname
/

create view oct_who_v
as
select
	princ
	,dist
	,dist_vec
  from (
	select
		w.princ
		,w.dist
		,case when row_number() over (partition by w.princ, w.dist order by d.account, d.pct) then
			stragg(d.account||'@'||d.pct) over (partition by w.princ, w.dist order by d.account, d.pct
				rows between unbounded preceding and unbounded following)
		end dist_vec
	  from hostdb.who w
		,hostdb.dist d
	 where w.dist is not null
	   and d.dist=w.dist
	)
 where dist_vec is not null
/

create view oct_wsc_v
as
select
	princ
	,case when row_number() over (partition by princ order by account, pct) then
		stragg(d.account||'@'||d.pct) over (partition by princ order by account, pct
			rows between unbounded preceding and unbounded following)
	end dist_vec
  from
	(
	select
		unique
		wsc.princ
		,account
		,pct
	  from hostdb.who_service_charge wsc
	) x
 where dist_vec is not null
/

spool off
set linesize 80

