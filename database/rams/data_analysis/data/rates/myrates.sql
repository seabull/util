spool myrates.log

drop table rates_test;

create table rates_test
as
select
        service_id
        ,amount old_rate
        ,amount new_rate
  from hostdb.cost
 where 0=1
/

set define on
set verify off
define effective_date='FEB-01-2007'

insert into rates_test
    (service_id, old_rate, new_rate)
select
        service_id
        ,amount
        ,0
  from hostdb.cost
-- where period_end is null
 where period_end=to_date('&effective_date', 'MON-DD-YYYY') or (period_end is null and period_begin < to_date('&effective_date', 'MON-DD-YYYY'))
/

define backup_rate  =25.54
define hardware_rate=19.06
define repair_rate  =10.11
define network_rate =14.02
define license_rate =8.21
define software_rate=12.19
define zero_rate    =0

update rates_test
   set new_rate=&backup_rate
 where service_id in (2, 3, 4, 5)
/
update rates_test
   set new_rate=&hardware_rate
 where service_id>=9 
   and service_id<=17
/
update rates_test
   set new_rate=&repair_rate
 where service_id in (18, 21, 22, 23, 24, 25, 26, 120)
/
update rates_test
   set new_rate=&network_rate
 where service_id=27
/
update rates_test
   set new_rate=&license_rate
 where service_id>=29 
   and service_id<=37
/

update rates_test
   set new_rate=&software_rate
 where service_id>=38 
   and service_id<=45
/

update rates_test
   set new_rate=old_rate
 where new_rate=0
/

update rates_test
   set new_rate=&zero_rate
 where service_id in (21, 22, 23, 24, 25, 26, 120)
/

update rates_test
   set new_rate=&zero_rate
 where service_id>=10 
   and service_id<=17
/

spool off
