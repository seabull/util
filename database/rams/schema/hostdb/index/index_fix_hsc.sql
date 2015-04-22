create index hostdb.hsc_assetno_idx on hostdb.host_service_charge (assetno)
        tablespace indx
        pctfree 30
	compute statistics
/

drop index hostdb.hsc_apsa_idx;
