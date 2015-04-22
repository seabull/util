-- $Id: who_chgby_ck.sql,v 1.1 2006/12/01 19:32:25 yangl Exp $
--

alter table hostdb.who drop constraint who_chgby_ck
/
alter table hostdb.WHO add constraint who_chgby_ck check((charge_by IN ('P', '!')))
/
