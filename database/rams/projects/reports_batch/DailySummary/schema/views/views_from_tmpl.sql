--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.who to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.who_TOUCHED_V

create or replace view CCREPORT.who_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.who b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.who_TOUCHEDBEFORE_V

create or replace view CCREPORT.who_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.who b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.name to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.name_TOUCHED_V

create or replace view CCREPORT.name_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.name b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.name_TOUCHEDBEFORE_V

create or replace view CCREPORT.name_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.name b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.principal to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.principal_TOUCHED_V

create or replace view CCREPORT.principal_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.principal b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.principal_TOUCHEDBEFORE_V

create or replace view CCREPORT.principal_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.principal b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.hoststab to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.hoststab_TOUCHED_V

create or replace view CCREPORT.hoststab_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.hoststab b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.hoststab_TOUCHEDBEFORE_V

create or replace view CCREPORT.hoststab_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.hoststab b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.machtab to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.machtab_TOUCHED_V

create or replace view CCREPORT.machtab_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.machtab b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.machtab_TOUCHEDBEFORE_V

create or replace view CCREPORT.machtab_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.machtab b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
--
-- Make sure ccreport has the following priv granted (not thru roles)
--
grant select on aud_hostdb.capequip to CCREPORT with grant option;

--
-- prepare touched views
--
PROMPT Creating view CCREPORT.capequip_TOUCHED_V

create or replace view CCREPORT.capequip_TOUCHED_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.capequip b
	 where aud_ts >= (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
	   and aud_ts <= (	select ts 
				  from UTILITY.asofv_param
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='2')
			)
) x
 where x.rowflag is not null
/

PROMPT Creating view CCREPORT.capequip_TOUCHEDBEFORE_V

create or replace view CCREPORT.capequip_TOUCHEDBEFORE_V
as
select
	x.*
  from
(
	select
		b.*
		,case when row_number() over (partition by aud_urowid order by aud_ts desc)=1 then
			aud_action
		end rowflag
	  from aud_hostdb.capequip b
	 where aud_ts < (	select ts 
				  from UTILITY.ASOFV_PARAM
				 where id=(select max(id) from UTILITY.ASOFV_PARAM where flag='1')
			)
) x
 where x.rowflag is not null
/
