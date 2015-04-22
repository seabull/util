-- $Id: who_forgiven.tbl.sql,v 1.1 2007/09/13 22:00:34 yangl Exp $

create sequence hostdb.wf_seq
    start with 1
    increment by 1
/

create table hostdb.wc_forgiven
(
    wf_id       number  primary key
    ,wc_rowid   rowid
    ,operation  char(1) 
    ,op_date    date    default sysdate
    ,constraint wf_oper_chk check (operation in ('f','u'))
)
/
