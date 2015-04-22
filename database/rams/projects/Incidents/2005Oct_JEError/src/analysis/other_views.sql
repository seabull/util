
create or replace view jnl245_wcadj_dist_v
as
select
	*
  from (
	select
		princ
		,case when row_number() over (partition by princ order by account)=1 then
		        stragg(account||'@'||pct*100/tpct) over (partition by princ order by account
		                rows between unbounded preceding and unbounded following)
		end dist_vec
	  from (
		select
		        unique
		        (select princ from hostdb.who_recorded where id=wr_id) princ
		        ,wc.account
		        ,wc.pct
		        ,sum(wc.pct) over (partition by wr_id, service_id) tpct
		  from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj wc
		 where amount>0
		)
	)
 where dist_vec is not null
/

