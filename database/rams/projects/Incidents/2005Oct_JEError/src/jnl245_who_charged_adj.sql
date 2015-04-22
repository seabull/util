
create table jnl245_who_charged_adj as
select *
  from hostdb.who_charged
 where 0=1
/
grant select, insert, update , delete on jnl245_who_charged_adj to hostdb;
