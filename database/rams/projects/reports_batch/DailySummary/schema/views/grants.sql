drop role dailysum_view;

create role dailysum_view;

grant select on utility.asofv_param to ccreport with grant option;

grant select on aud.change_session_log_details_v to dailysum_view;

--grant select on aud.change_log			to dailysum_view;
--grant select on aud.session_log			to dailysum_view;
--grant select on aud.principal_log		to dailysum_view;

grant select on hostdb.accounts_str_v		to dailysum_view;

grant select on hostdb.qualifiers		to dailysum_view;

grant select on ccreport.who_changed_v		to dailysum_view;
grant select on ccreport.dist_string_v		to dailysum_view;
grant select on ccreport.dist_string_aggr_v	to dailysum_view;
grant select on ccreport.dist_names_diff_v	to dailysum_view;

grant select on ccreport.dist_names_asofv_1	to dailysum_view;
grant select on ccreport.dist_names_asofv_2	to dailysum_view;

--
-- who related asofv
--
grant select on ccreport.who_asofv_1		to dailysum_view;
grant select on ccreport.who_asofv_2		to dailysum_view;
grant select on ccreport.name_asofv_1		to dailysum_view;
grant select on ccreport.name_asofv_2		to dailysum_view;
grant select on ccreport.principal_asofv_1	to dailysum_view;
grant select on ccreport.principal_asofv_2	to dailysum_view;
grant select on ccreport.who_servicelevel_asofv1 to dailysum_view;
grant select on ccreport.who_servicelevel_asofv2 to dailysum_view;

grant select on ccreport.who_touched_v		to dailysum_view;
grant select on ccreport.who_touched_princ_v	to dailysum_view;
grant select on ccreport.who_servicelevel_diff_v to dailysum_view;

--grant select on aud_hostdb.who_service		to dailysum_view;
--grant select on aud_hostdb.who			to dailysum_view;
--grant select on aud_hostdb.who_attr		to dailysum_view;
--grant select on aud_hostdb.name			to dailysum_view;
--grant select on aud_hostdb.principal		to dailysum_view;

--
-- host related asofv
--
grant select on ccreport.hoststab_asofv_1	to dailysum_view;
grant select on ccreport.hoststab_asofv_2	to dailysum_view;
grant select on ccreport.machtab_asofv_1	to dailysum_view;
grant select on ccreport.machtab_asofv_2	to dailysum_view;
grant select on ccreport.capequip_asofv_1	to dailysum_view;
grant select on ccreport.capequip_asofv_2	to dailysum_view;
grant select on ccreport.host_attr_asofv_1	to dailysum_view;
grant select on ccreport.host_attr_asofv_2	to dailysum_view;
grant select on ccreport.mach_attr_asofv_1	to dailysum_view;
grant select on ccreport.mach_attr_asofv_2	to dailysum_view;
grant select on ccreport.host_servicelevel_asofv1 to dailysum_view;
grant select on ccreport.host_servicelevel_asofv2 to dailysum_view;

grant select on ccreport.asset_touched_v to dailysum_view;
grant select on ccreport.hoststab_touched_v to dailysum_view;
grant select on ccreport.machtab_touched_v to dailysum_view;
grant select on ccreport.capequip_touched_v to dailysum_view;

grant select on ccreport.hostsmachcapsvc2_touched_1 to dailysum_view;
grant select on ccreport.hostsmachcapsvc2_touched_2 to dailysum_view;

grant select on ccreport.hostsmachcapsvc2_changed_v		to dailysum_view;


grant dailysum_view to "COSTING@CS.CMU.EDU";

--grant select on hostdb.name			to dailysum_view;
--grant select on hostdb.principal		to dailysum_view;
--
--grant select on aud_hostdb.dist_names		to dailysum_view;
--grant select on aud_hostdb.host_service		to dailysum_view;
--grant select on aud_hostdb.who_service		to dailysum_view;
--grant select on aud_hostdb.host_service		to dailysum_view;
--grant select on aud_hostdb.host_attr		to dailysum_view;
--grant select on aud_hostdb.mach_attr		to dailysum_view;
--grant select on aud_hostdb.name			to dailysum_view;
--grant select on aud_hostdb.principal		to dailysum_view;
--grant select on aud_hostdb.who_attr		to dailysum_view;
--grant select on aud_hostdb.name			to dailysum_view;
--grant select on aud_hostdb.principal		to dailysum_view;
--grant select on aud_hostdb.hoststab		to dailysum_view;
--grant select on aud_hostdb.machtab		to dailysum_view;
--grant select on aud_hostdb.capequip		to dailysum_view;
--grant select on aud_hostdb.who			to dailysum_view;
--grant select on aud_hostdb.name			to dailysum_view;
--grant select on aud_hostdb.principal		to dailysum_view;
--grant select on aud_hostdb.hoststab		to dailysum_view;
--grant select on aud_hostdb.machtab		to dailysum_view;
--grant select on aud_hostdb.capequip		to dailysum_view;
--
----grant select on aud.change_log to ccreport;
----grant select on aud.session_log to ccreport;
----grant select on aud.principal_log to ccreport;
--
---- grant select on hostdb.dist to ccreport;
---- grant select on hostdb.accounts to ccreport;
---- grant execute on hostdb.account_string to ccreport;
--
---- grant select on aud_hostdb.hoststab to ccreport;
---- grant select on aud_hostdb.machtab to ccreport;
---- grant select on aud_hostdb.capequip to ccreport;
---- grant select on aud_hostdb.who to ccreport;
