column category format a20 trunc
select
    service_id
    ,category
    ,period_begin
    ,period_end
    ,amount
  from hostdb.cost c
    ,hostdb.services s
 where c.service_id=s.id
   and type='M'
order by period_end, service_id
/

select
    service_id
    ,category
    ,period_begin
    ,period_end
    ,amount
  from hostdb.cost c
    ,hostdb.services s
 where c.service_id=s.id
   and type='M'
   and period_end is null
order by period_end, service_id
/
