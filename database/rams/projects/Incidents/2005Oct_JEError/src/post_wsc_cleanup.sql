create table jnl254_who_service_charge
as
select * from hostdb.who_service_charge
/

grant select on jnl254_who_service_charge to hostdb;
