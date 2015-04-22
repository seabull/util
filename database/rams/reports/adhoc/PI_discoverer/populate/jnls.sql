
insert into jnls
(jnl_id, post_date, type)
(
select
	id
	,trunc(post_date)
	,nvl(journal_type_flag, 'M')
  from hostdb.journals
 where id>0
)
/
