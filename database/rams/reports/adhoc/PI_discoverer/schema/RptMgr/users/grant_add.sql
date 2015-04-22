-- $Id: grant_add.sql,v 1.3 2007/04/30 19:02:36 yangl Exp $
--

grant connect to            pireport;

grant create procedure to	pireport;
grant create table to		pireport;
grant create trigger to		pireport;
grant create type to		pireport;
grant create materialized view to pireport;

grant costing_view to		pireport;

grant execute on hostdb.account_string to		pireport;

grant select on hostdb.accounts     to  pireport;
grant select on hostdb.accounts_str_v to  pireport;
grant select on hostdb.dist         to  pireport;
grant select on hostdb.services     to  pireport;
grant select on hostdb.name         to  pireport;
grant select on hostdb.principal    to  pireport;
grant select on hostdb.bldgs        to  pireport;
grant select on hostdb.depts        to  pireport;
grant select on hostdb.qualifiers   to  pireport;
grant select on hostdb.journals     to  pireport;
grant select on hostdb.report_person to  pireport;
-- inline views require direct grant, not via roles
grant select on hostdb.pta_status   to  pireport;

--grant execute on hostdb.Account_Report_Email to	pireport;

-- vim: ts=4:sw=4:et:
