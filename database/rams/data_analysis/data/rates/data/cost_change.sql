-- $Id: cost_change.sql,v 1.2 2007/06/05 15:07:29 yangl Exp $
-- scripts to update hostdb.cost table with new rates
--
set define on
set linesize 200
set pagesize 50000

define effective_date='MAR-01-2007'

--define backup_rate  =25.54
--define hardware_rate=19.06
--define repair_rate  =10.11
--define network_rate =14.02
--define network_rate =19.95
--define license_rate =8.21
--define software_rate=12.19
define zero_rate    =0

--define user_general_rate=44.06
-- make user charge $100
--define user_general_rate=49.06
define user_general_rate=100
define hardware_rate=25.00
define software_rate=25.00
define network_rate =20
define backup_rate  =25.00
define mr1_rate     =30.00
define repair_rate  =0
define license_rate =0

spool cost_change.log

@@cost_check.sql

prompt expire all machine rates except CLH/CLS/CLR

update hostdb.cost
   set period_end=to_date('&effective_date','MON-DD-YYYY')
 where service_id in (select id from hostdb.services where type='M')
   and period_end is null
   and (
        amount > 0 
        or service_id in (
            select id from hostdb.services where type='M' and subtype in ('S','L')
                )
        )
        -- not touch MR1/MR2 and those rates that remain same
   --and service_id not in (2, 5, 37, 45, 47, 48, 122, 123, 124)
    -- only cluster charges no change
   and service_id not in (122, 123, 124)
/

prompt expire all user rates 
update hostdb.cost
   set period_end=to_date('&effective_date','MON-DD-YYYY')
 where
         --service_id=8
        period_end is null
   and (
        --amount > 0 
        --or 
        service_id in (
            select id from hostdb.services where type='W' 
                )
        )
   and service_id not in (122, 123, 124)
/

prompt zero rate for all rates except Bkup/Net/MR/H/G/S-*

insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
select
    service_id
    ,period_end
    ,null
    ,&zero_rate
  from hostdb.cost
 where period_end >= to_date('&effective_date','MON-DD-YYYY')-1
   and service_id not in (2,3,4,5,9, 27, 47, 8)
   and service_id not in (select id from hostdb.services where type='M' and subtype='S')
    -- backups, harware, network, mr1, general user
/

--select
--    service_id
--    ,category
--    ,period_begin
--    ,period_end
--    ,amount
--  from hostdb.cost c
--    ,hostdb.services s
-- where c.service_id=s.id
--   --and type='M'
--   and period_end is null
--order by period_end, service_id
--/

prompt set general user rate
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (8, to_date('&effective_date','MON-DD-YYYY'), null, &user_general_rate)
/

prompt set backup rate
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (2, to_date('&effective_date','MON-DD-YYYY'), null, &backup_rate)
/
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (3, to_date('&effective_date','MON-DD-YYYY'), null, &backup_rate)
/
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (4, to_date('&effective_date','MON-DD-YYYY'), null, &backup_rate)
/
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (5, to_date('&effective_date','MON-DD-YYYY'), null, &backup_rate)
/

prompt set hardware rate
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (9, to_date('&effective_date','MON-DD-YYYY'), null, &hardware_rate)
/

-- set to zero
--prompt repair rate
--insert into hostdb.cost
--    (service_id, period_begin, period_end, amount)
--values
--    (18, to_date('&effective_date','MON-DD-YYYY'), null, &repair_rate)
--/

prompt set network rate
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (27, to_date('&effective_date','MON-DD-YYYY'), null, &network_rate)
/

prompt set MR1 rate
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
values
    (47, to_date('&effective_date','MON-DD-YYYY'), null, &mr1_rate)
/

prompt software rates
insert into hostdb.cost
    (service_id, period_begin, period_end, amount)
select 
        unique
        id
        ,to_date('&effective_date','MON-DD-YYYY')
        ,null
        ,&software_rate
  from hostdb.services
 where subtype='S'
   and type='M'
/


--prompt software rate
--insert into hostdb.cost
--    (service_id, period_begin, period_end, amount)
--    select
--        unique
--        id
--        ,to_date('&effective_date','MON-DD-YYYY')
--        ,null
--        ,&software_rate
--      from hostdb.services
--     where subtype='S'
--       and type='M'
--       and id < 46
--       and id not in (select service_id from hostdb.cost where period_end is null)
--/
--
--prompt license rate
--insert into hostdb.cost
--    (service_id, period_begin, period_end, amount)
--    select
--        unique
--        id
--        ,to_date('&effective_date','MON-DD-YYYY')
--        ,null
--        ,&license_rate
--      from hostdb.services
--     where subtype='L'
--       and type='M'
--       and id < 38
--       and id not in (select service_id from hostdb.cost where period_end is null)
--/
--
--prompt os-dependent h/w and repair rate (zero)
--
--insert into hostdb.cost
--    (service_id, period_begin, period_end, amount)
--    select
--        unique
--        id
--        ,to_date('&effective_date','MON-DD-YYYY')
--        ,null
--        ,&zero_rate
--      from hostdb.services
--     where subtype in ('H', 'R')
--       and type='M'
--       and id not in (9, 18)
--       and id in (select service_id from hostdb.cost where period_end=to_date('&effective_date','MON-DD-YYYY') and amount > 0)
--/

@@cost_check.sql

spool off
set linesize 80
