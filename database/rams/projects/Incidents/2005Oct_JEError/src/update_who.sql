spool update_who.log
update hostdb.who
   set pct=pct-1
 where princ in (select princ from "YANGL@CS.CMU.EDU".jnl245_user_adj)
/
update hostdb.who
   set pct=pct+1
 where princ in (select princ from "YANGL@CS.CMU.EDU".jnl245_user_adj)
/
spool off
