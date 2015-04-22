--$Id: parttimer_analysis.sql,v 1.3 2005/04/08 18:46:47 yangl Exp $
/*
prompt tmcd

select 
	*
from hostdb.tmcd_recorded tr
where 
      -- tr.princ='curmson'
      tr.appointment=42441
  and tr.period_last=
	( select max(period_last) 
	    from tmcd_recorded tr1
	   where tr1.period_last!=(select max(period_last) from tmcd_recorded tr2)
	)
/

prompt current tmcd
select 
	*
from hostdb.tmcd_recorded tr
where 
      -- tr.princ='curmson'
      tr.appointment=42441
  and tr.period_last=
	( select max(period_last) 
	    from tmcd_recorded tr1
	)
/

prompt current labor
select 
	*
  from hostdb.labor_recorded l
 where 
       -- l.princ='curmson'
       l.appointment=42441
   and l.period_last>(select max(period_last)
			from labor_recorded l1
			)-1
/

select 
	*
from who w
where w.princ IN 
(
select unique princ
	-- ,appointment,lname
  from tmcd_recorded tr
 where tr.period_last>to_date('29-DEC-04','DD-MON-YY')
   and tr.appointment  not in (select appointment 
			   from tmcd_recorded tr2
 			  where tr2.period_last<to_date('29-DEC-04','DD-MON-YY')
 			    and tr2.period_last>to_date('29-NOV-04','DD-MON-YY')
			)
   and princ is not null
)
/
			   
*/
------------------------------------------
-- More details
------------------------------------------

set termout off

/*
-- case 3 users
-- follow payroll
spool case3
prompt Full-time
select 
	w.princ
	,w.dist
	,w.dist_src
	,w.project
	,w.subproject
	,w.pct
from hostdb.who w
where
	w.dist is not null
	and w.charge_by is null
	and w.dist_src=upper(w.dist_src)
order by w.dist_src
	,w.princ
/

prompt Part-time
select 
	w.princ
	,w.dist
	,w.dist_src
	,w.project
	,w.subproject
	,w.pct
from hostdb.who w
where
	w.dist is not null
	and w.charge_by is null
	and w.dist_src=lower(w.dist_src)
order by w.dist_src
	,w.princ
/
select avg(pct)
	,max(pct)
	,min(pct)
from hostdb.who w
where
	w.dist is not null
	and w.charge_by is null
	and w.dist_src=lower(w.dist_src)
/
spool off
*/

-- Impact of part-timers change to 3.5%
-- services.monthly decides whether who.pct should be used on top of distribution (dist)
-- or 100% should be used for distribution
-- e.g. 
-- dist_a account_a 50%
-- dist_a account_b 50%
--
-- if services.monthly is not null, then charges for dist_a will be 
--	50%*who.pct to account_a 
--	50%*who.pct to account_b 
-- if services.monthly is null, then charges for dist_a will be 
--	50% to account_a 
--	50% to account_b 
--
spool charge_pt
select 
	wsc.princ
	,w.pct
	,sum(wsc.charge)
	,sum(wsc.amount) old_amount
	,sum(wsc.charge)*0.035 new_amount
	,sum(wsc.amount)-sum(wsc.charge)*0.035 diffs
from hostdb.who_service_charge wsc
	, hostdb.who w
where 
	w.princ=wsc.princ
	and w.dist is not null
	-- Follow payroll instead of hard-coded
	and w.charge_by is null
	and w.dist_src=lower(w.dist_src)
group by wsc.princ
	, w.pct
/

select sum(diffs)
from (
select 
	wsc.princ
	,w.pct
	,sum(wsc.charge)
	,sum(wsc.amount) old_amount
	,sum(wsc.charge)*0.035 new_amount
	,sum(wsc.amount)-sum(wsc.charge)*0.035 diffs
from hostdb.who_service_charge wsc
	, hostdb.who w
where w.princ=wsc.princ
	-- Follow payroll instead of hard-coded
	and w.dist is not null
	and w.charge_by is null
	-- followed timecard data or no timecard data last month and used Project
	and (
		w.dist_src=lower(w.dist_src)
		or w.dist_src='P'
		)
group by wsc.princ
	, w.pct
)
/

select 
	wsc.princ
	,w.pct
	,sum(wsc.charge)
	,sum(wsc.amount) old_amount
	,sum(wsc.charge)*0.035 new_amount
	,sum(wsc.amount)-sum(wsc.charge)*0.035 diffs
from hostdb.who_service_charge wsc
	, hostdb.who w
where 
	w.princ not in (
		select unique princ
			-- ,appointment,lname
		  from tmcd_recorded tr
		 where tr.period_last>to_date('31-JAN-05','DD-MON-YY')
		   and tr.period_last<to_date('01-MAR-05','DD-MON-YY')
		   and princ is not null
		)
	and w.princ=wsc.princ
	and w.dist is not null
	-- Follow payroll instead of hard-coded
	and w.charge_by is null
	and (
		w.dist_src=lower(w.dist_src)
		or w.dist_src='P'
		)
group by wsc.princ
	, w.pct
/

select sum(diffs)
from (
select 
	wsc.princ
	,w.pct
	,sum(wsc.charge)
	,sum(wsc.amount) old_amount
	,sum(wsc.charge)*0.035 new_amount
	,sum(wsc.amount)-sum(wsc.charge)*0.035 diffs
from hostdb.who_service_charge wsc
	, hostdb.who w
where 
	w.princ not in (
		select unique princ
			-- ,appointment,lname
		  from tmcd_recorded tr
		 where tr.period_last>to_date('31-JAN-05','DD-MON-YY')
		   and tr.period_last<to_date('01-MAR-05','DD-MON-YY')
		   and princ is not null
		)
	and w.princ=wsc.princ
	and w.dist is not null
	-- Follow payroll instead of hard-coded
	and w.charge_by is null
	and (
		w.dist_src=lower(w.dist_src)
		or w.dist_src='P'
		)
group by wsc.princ
	, w.pct
)
/

select 
	wsc.princ
	,wsc.pct wsc_pct
	,w.pct who_pct
	,wsc.charge
	,wsc.amount 
from hostdb.who_service_charge wsc
	, hostdb.who w
where w.princ=wsc.princ
	-- Follow payroll instead of hard-coded
	and w.dist is not null
	and w.charge_by is null
	and (
		w.dist_src=lower(w.dist_src)
		or w.dist_src='P'
		)
/

select 
	w.princ
	,w.dist
	,w.dist_src
	,w.project
	,w.subproject
	,w.pct
from hostdb.who w
where
	w.dist is not null
	and w.charge_by is null
	and (
		w.dist_src=lower(w.dist_src)
		or w.dist_src='P'
		)
order by w.dist_src
	,w.princ
/
select *
from services 
where monthly is not null
/

select 
	hsc.*
	,m.usrprinc
	,m.dist
from hostdb.host_service_charge hsc
	,hostdb.machtab m
where 
	hsc.assetno=m.assetno
	and m.usrprinc in 
		( select princ
	    	    from hostdb.who w
	   	   where w.dist is not null
	     	     and w.charge_by is null
	     	     and w.dist_src=lower(w.dist_src)
		)
  	  and m.dist_src='U'
/
spool off
set termout on

/*
select 
	wsc.princ
	--,wsc.pct
	,w.pct
	,sum(wsc.charge)
	,sum(wsc.amount)
	--,wsc.account
	--,wsc.service_id
from hostdb.who_service_charge wsc
	, hostdb.who w
where w.princ=wsc.princ
	and w.dist is not null
	-- Follow payroll instead of hard-coded
	and w.charge_by is null
	and w.dist_src=lower(w.dist_src)
group by wsc.princ
	, w.pct
/

select * from host_service where pct!=100
/

select 
	c.verified
from host_service hs
	,capequip c
where c.assetnum=hs.assetno
and hs.pct!=100
/

spool dist_pct
select 
	d.*
from hostdb.dist_names d
where d.pct is not null
/
spool off

hostdb@FAC.SUNSPOT.SRV.CS.CMU.EDU> desc  who_service_charge
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 PRINC                                                 NOT NULL VARCHAR2(8)
 PCT                                                   NOT NULL NUMBER(5,2)
 CHARGE                                                NOT NULL NUMBER(6,2)
 AMOUNT                                                NOT NULL NUMBER(6,2)
 ACCOUNT                                               NOT NULL NUMBER(6)
 SERVICE_ID                                            NOT NULL NUMBER(3)

hostdb@FAC.SUNSPOT.SRV.CS.CMU.EDU> desc machtab
 Name                                                  Null?    Type
 ----------------------------------------------------- -------- ------------------------------------
 ASSETNO                                               NOT NULL VARCHAR2(9)
 CPUTYPE                                               NOT NULL VARCHAR2(10)
 CPUMODEL                                              NOT NULL VARCHAR2(20)
 CPUMODELEXT                                                    VARCHAR2(20)
 HOSTID                                                         VARCHAR2(20)
 PROJECT                                                        VARCHAR2(30)
 HWADDR                                                         VARCHAR2(20)
 USRPRINC                                                       VARCHAR2(8)
 PRJPRINC                                                       VARCHAR2(8)
 USAGE                                                          CHAR(1)
 IROWID                                                         CHAR(1)
 DIST                                                           NUMBER(6)
 CHARGE_BY                                                      CHAR(1)
 OPROJECT                                                       CHAR(1)
 OUSAGE                                                         CHAR(1)
 SUBPROJECT                                                     VARCHAR2(12)
 DIST_SRC                                                       VARCHAR2(3)
 MR_CLASS                                                       VARCHAR2(10)
 FILTER_CODE                                                    VARCHAR2(10)
 DESCRIPTION                                                    VARCHAR2(100)

*/
