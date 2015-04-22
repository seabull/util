-- $Id: wc_forgiven_details_v.sql,v 1.1 2007/09/21 14:15:52 yangl Exp $
create or replace view hostdb.wc_forgiven_details_v
as
select
        wc.wr_id
        ,wr.princ
        ,wr.name
        ,wr.charge_src
        ,wr.sponsor
        ,wr.project
        ,wr.subproject
        ,wc.journal
        ,wc.account
        ,wc.account_flag
        ,(select unique acct_string from hostdb.accounts_str_v where id=wc.account) acct_string
        ,wc.service_id
        ,wc.charge
        ,wc.pct
        ,wc.amount
        ,wc.trans_date
        ,wc.notes
        ,wf.operation
        ,wf.op_date
        ,wf.wc_rowid
  from hostdb.wc_forgiven wf
        ,hostdb.who_charged wc
        ,hostdb.who_recorded wr
 where wf.wc_rowid=wc.rowid
   and wc.wr_id=wr.id
/
