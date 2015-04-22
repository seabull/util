set linesize 1000
set colsep ','
spool acct_subs.log
column src_acct format a28
column dst_acct format a28
column name format a20 trunc
column status format a10 trunc

prompt note 
prompt empty src_acct or dst_acct results in no substitution 
prompt
prompt princ ALL, substitution apply to all users
prompt
select
        nvl(princ, 'ALL') princ
        ,(select name from hostdb.name where a.princ=princ and rownum<2) name
        ,(select decode(dist, null, 'uncharged','charged-'||dist_src) from hostdb.who where a.princ=princ) status
        ,(select nvl(flag, 'v')||','||acct_string from hostdb.accounts_str_v where a.src_account=id) "src_flag,src_acct"
        ,(select sum(amount) from hostdb.host_service_charge where account=src_account) src_host_charge
        ,(select sum(amount) from hostdb.who_service_charge where account=src_account) src_who_charge
        ,(select nvl(flag,'v')||','||acct_string from hostdb.accounts_str_v where a.dst_account=id) "dst_flag,dst_acct"
        ,(select sum(amount) from hostdb.host_service_charge where account=dst_account) dst_host_charge
        ,(select sum(amount) from hostdb.who_service_charge where account=dst_account) dst_who_charge
  from hostdb.account_subs a
order by princ
/
spool off
set linesize 80
set colsep ' '
