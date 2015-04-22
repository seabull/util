select 0-sum(amount)
  from jnl245_journal_adj j
	,hostdb.accounts a
 where account=a.id 
   and a.funding is not null
   and objcode!='68200'
/

