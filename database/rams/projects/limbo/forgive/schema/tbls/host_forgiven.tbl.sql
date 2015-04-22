-- $Id: host_forgiven.tbl.sql,v 1.1 2007/09/13 22:00:34 yangl Exp $

create sequence hostdb.hf_seq
    start with 1
    increment by 1
/

create table hostdb.hc_forgiven
(
    hf_id       number   primary key
    ,hc_rowid   rowid
    ,operation  char(1)
    ,op_date    date        default sysdate
    ,constraint hf_oper_chk check ( operation in ('f','u') )
)
/
