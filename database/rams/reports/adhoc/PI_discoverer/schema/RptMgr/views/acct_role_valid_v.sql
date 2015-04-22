-- $Id: acct_role_valid_v.sql,v 1.1 2007/01/15 20:45:31 yangl Exp $

create view pireport.acct_role_valid_v
as
select
        *
  from acct_role
 where valid='Y'
/
