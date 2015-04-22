exec histview_utils.new(sysdate-7,sysdate);

prompt wsc
select count(*) from wsc_curr_v;
select count(*) from hostdb.who_service_charge;

prompt who
select count(*) from who_curr_v;
select count(*) from hostdb.who;

prompt hsc
select count(*) from hsc_curr_v;
select count(*) from hostdb.host_service_charge;

prompt capequip
select count(*) from capequip_curr_v;
select count(*) from hostdb.capequip;

prompt machtab
select count(*) from machtab_curr_v;
select count(*) from hostdb.machtab;

prompt hoststab
select count(*) from hoststab_curr_v;
select count(*) from hostdb.hoststab;
