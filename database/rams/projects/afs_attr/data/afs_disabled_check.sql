
select
        *
  from hostdb.who_attr
 where attr='AFS'
order by sense
        ,princ
/

-- service 1 is AFS
select
        unique
        princ
  from hostdb.who_service_charge wsc
 where princ not in (select princ from hostdb.who_service_charge where service_id=1)
/
select
        unique
        princ
  from hostdb.who_service
 where princ not in (select princ from hostdb.who_service where service_id=1)
--   and princ in (select princ from hostdb.who where dist is not null)
/
