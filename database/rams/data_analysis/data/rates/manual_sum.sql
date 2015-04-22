
set define on
set verify off
define effective_date='FEB-01-2007'

create or replace view x_rates_v
as
select
        service_id
        ,new_rate new_amount
        ,old_rate old_amount
        ,new_rate-old_rate amount_diff
        ,new_rate/decode(old_rate,0,1,old_rate) new_over_old
  from rates_test c1
/

set termout off
spool manual_sum.log
select
        journal
        ,account_flag
        ,sum(amount)
  from hostdb.host_charged
 where journal=306
group by journal, account_flag
/

select
        journal
        ,account
        ,account_flag
        ,service_id
        ,sum(amount)
  from hostdb.host_charged
 where journal=306
group by journal, account, account_flag, service_id
/

select
        journal
        ,account_flag
        ,sum(decode(amount_estimate,null,amount,1,amount, amount_estimate))
  from (
    select
            c.journal
            ,c.account
            ,c.account_flag
            ,c.service_id
            ,c.hr_id
            ,c.pct
            --,c.amount/decode(r.new_over_old, 0,1, r.new_over_old)   amount_estimate
            --,(select c.amount/decode(r.new_over_old, 0,1, r.new_over_old) from x_rates_v r where service_id=c.service_id)  amount_estimate
            ,(select c.pct*r.new_amount/100 from x_rates_v r where service_id=c.service_id) amount_estimate
            ,c.amount
      from  hostdb.host_charged c
     where journal=306
           -- x_rates_v r
           -- ,(
           --     select
           --             journal
           --             ,account
           --             ,account_flag
           --             ,service_id
           --             ,hr_id
           --             ,amount
           --       from hostdb.host_charged hc
           --      where journal=306
           -- ) c
     --where r.service_id=c.service_id
    ) x
group by journal, account_flag
order by account_flag
/

spool off
set termout on
