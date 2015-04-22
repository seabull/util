set linesize 1000
column services format a24 trunc
set colsep ','
spool machine_check.log
select
        h.assetno
        h.pri
        '"'||h.services||'"'
        ,(select hostname from hostdb.hoststab where assetno=h.assetno and rownum < 2) hostname
  from hs_services_v h
 where assetno in (
        select
                unique
                hs.assetno
          from hostdb.host_service hs
                --,hostdb.services s
         where --hs.service_id=s.id
                hs.service_id not in (9, 27, 2,3,4,5,47,48,122,123,124)
           and hs.assetno not in (select assetno from hostdb.host_service where service_id=9)
    )
/
spool off
set linesize 80
set colsep ' '
