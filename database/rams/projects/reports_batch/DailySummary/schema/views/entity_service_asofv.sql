--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.who_service to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.who_service_ASOFV_1

create or replace view CCREPORT.who_service_ASOFV_1
as
select
	x.*
  from (
		select
			b.*
			,case when row_number() over (partition by 
				princ, service_id
				order by aud_ts desc)=1 then
				aud_action
			end rowflag
		  from aud_hostdb.who_service b
		 where aud_ts <= (
				select ts 
				  from UTILITY.asofv_param
				 where id=(	select max(id)
						  from UTILITY.ASOFV_PARAM 
						 where flag='1'
					)
				)
	) x
 where x.rowflag!='D'
   and x.rowflag is not null
/

PROMPT Creating view CCREPORT.who_service_ASOFV_2

create or replace view CCREPORT.who_service_ASOFV_2
as
select
	x.*
  from (
		select
			b.*
			,case when row_number() over (partition by 
				princ, service_id
				order by aud_ts desc)=1 then
				aud_action
			end rowflag
		  from aud_hostdb.who_service b
		 where aud_ts <= (
				select ts 
				  from UTILITY.asofv_param
				 where id=(	select max(id)
						  from UTILITY.ASOFV_PARAM 
						 where flag='2'
					)
				)
	) x
 where x.rowflag!='D'
   and x.rowflag is not null
/

--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.host_service to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.host_service_ASOFV_1

create or replace view CCREPORT.host_service_ASOFV_1
as
select
	x.*
  from (
		select
			b.*
			,case when row_number() over (partition by 
				assetno, pri, service_id
				order by aud_ts desc)=1 then
				aud_action
			end rowflag
		  from aud_hostdb.host_service b
		 where aud_ts <= (
				select ts 
				  from UTILITY.asofv_param
				 where id=(	select max(id)
						  from UTILITY.ASOFV_PARAM 
						 where flag='1'
					)
				)
	) x
 where x.rowflag!='D'
   and x.rowflag is not null
/

PROMPT Creating view CCREPORT.host_service_ASOFV_2

create or replace view CCREPORT.host_service_ASOFV_2
as
select
	x.*
  from (
		select
			b.*
			,case when row_number() over (partition by 
				assetno, pri, service_id
				order by aud_ts desc)=1 then
				aud_action
			end rowflag
		  from aud_hostdb.host_service b
		 where aud_ts <= (
				select ts 
				  from UTILITY.asofv_param
				 where id=(	select max(id)
						  from UTILITY.ASOFV_PARAM 
						 where flag='2'
					)
				)
	) x
 where x.rowflag!='D'
   and x.rowflag is not null
/

