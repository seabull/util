-- $Id: hc_forgiven_details_v.sql,v 1.1 2007/09/21 14:15:52 yangl Exp $
create or replace view hostdb.hc_forgiven_details_v
as
select
        hc.hr_id
        ,hr.assetno
        ,hr.hostname name
        ,hr.charge_src
        ,hr.cpu
        ,hr.os
        ,hr.qual
        ,hr.location
        ,hr.usrprinc
        ,hr.prjprinc
        ,hr.princ
        ,hr.project
        ,hr.subproject
        ,hc.journal
        ,hc.account
        ,hc.account_flag
        ,(select unique acct_string from hostdb.accounts_str_v where id=hc.account) acct_string
        ,hc.service_id
        ,hc.charge
        ,hc.pct
        ,hc.amount
        ,hc.trans_date
        ,hc.notes
        ,hf.operation
        ,hf.op_date
        ,hf.hc_rowid
  from hostdb.hc_forgiven hf
        ,hostdb.host_charged hc
        ,hostdb.host_recorded hr
 where hf.hc_rowid=hc.rowid
   and hc.hr_id=hr.id
/
