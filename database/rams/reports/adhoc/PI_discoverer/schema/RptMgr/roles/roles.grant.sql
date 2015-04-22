-- $Id: roles.grant.sql,v 1.3 2007/03/21 19:45:08 yangl Exp $

grant select on hostdb.journals         to pireport_view;
grant select on hostdb.charge_sources   to pireport_view;
grant select on hostdb.capequip         to pireport_view;
grant select on hostdb.bldgs            to pireport_view;
grant select on hostdb.host_recorded    to pireport_view;
grant select on hostdb.who_recorded     to pireport_view;

grant select on pireport.accts          to pireport_view;
grant select on pireport.acct_role      to pireport_view;
grant select on pireport.charges        to pireport_view;
grant select on pireport.jnls           to pireport_view;
grant select on pireport.investigator   to pireport_view;

grant select on pireport.acct_role_valid_v  to pireport_view;
grant select on pireport.charges_distvec_v  to pireport_view;

--grant execute on pireport.sync_pi_rpt   to pireport_change;
