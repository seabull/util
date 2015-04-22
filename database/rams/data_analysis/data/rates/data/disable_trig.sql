spool disable_trigger.log
alter trigger aud_hostdb.host_service_del disable;
alter trigger aud_hostdb.host_service_iu disable;

alter trigger aud_hostdb.host_service_charge_del disable;
alter trigger aud_hostdb.host_service_charge_iu disable;

alter trigger aud_hostdb.dist_del disable;
alter trigger aud_hostdb.dist_iu disable;

alter trigger aud_hostdb.dist_names_del disable;
alter trigger aud_hostdb.dist_names_iu disable;

alter trigger aud_hostdb.who_service_del disable;
alter trigger aud_hostdb.who_service_iu disable;

alter trigger aud_hostdb.who_service_charge_del disable;
alter trigger aud_hostdb.who_service_charge_iu disable;

alter trigger aud_hostdb.who_del disable;
alter trigger aud_hostdb.who_iu disable;

alter trigger aud_hostdb.hoststab_del disable;
alter trigger aud_hostdb.hoststab_iu disable;

alter trigger aud_hostdb.machtab_del disable;
alter trigger aud_hostdb.machtab_iu disable;

alter trigger aud_hostdb.capequip_del disable;
alter trigger aud_hostdb.capequip_iu disable;

alter trigger aud_hostdb.who_attr_del disable;
alter trigger aud_hostdb.who_attr_iu disable;

alter trigger aud_hostdb.mach_attr_del disable;
alter trigger aud_hostdb.mach_attr_iu disable;

spool off
