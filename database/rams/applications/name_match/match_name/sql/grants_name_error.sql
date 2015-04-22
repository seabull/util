-- $Id: grants_name_error.sql,v 1.1 2005/04/20 21:21:21 yangl Exp $
--
create role names_view not identified;
create role names_change not identified;

grant select on hostdb.name_error to names_view;
grant select on hostdb.name_error_bids to names_view;

grant names_view to names_change;
grant update,insert,delete on hostdb.name_error to names_change;
grant update,insert,delete on hostdb.name_error_bids to names_change;
grant select,alter on hostdb.name_error_bids to names_change;
grant execute on hostdb.matchnames_pkg to names_change;


grant names_change to "COSTING@CS.CMU.EDU";
grant names_change to "KZM@CS.CMU.EDU";
grant names_view to "TFAULK@CS.CMU.EDU";
