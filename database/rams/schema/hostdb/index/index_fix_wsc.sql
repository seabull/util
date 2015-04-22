
create index hostdb.wsc_princ_idx on hostdb.who_service_charge (princ)
        tablespace indx
        pctfree 30
	compute statistics
/

drop index hostdb.whosvcchg_princsvcidacct_idx;

