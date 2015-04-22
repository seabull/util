create table jnl245_journal_adj as
select *
  from hostdb.journal
 where 0=1;

grant select, update, insert, delete on jnl245_journal_adj to hostdb;
