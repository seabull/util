select sum(amount) from "YANGL@CS.CMU.EDU".jnl245_who_charged_adj;
select sum(amount) from hostdb.who_charged where journal=245 and account_flag='b';
