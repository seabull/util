select unique 
	wr_id
	, princ 
	, nvl(wc.account_flag, 'v')
  from who_charged wc
	, who_recorded wr
 where journal=245
   and wr.id=wc.wr_id
   and princ in (select princ from "YANGL@CS.CMU.EDU".jnl245_user_adj)
   and (account_flag!='l' or account_flag is null)
   --and account_flag='l'
/
-- 304
--  53
-- 251
