set linesize 1000
set feedback on
set heading on
set termout off
whenever sqlerror exit failure rollback
whenever oserror exit failure rollback
spool correctit.log
prompt BEFORE UPDATE
select
unique
w.princ
,w.pct pct_configured
,x.pct pct_charged
,w.charge_by
,w.dist_src
,w.project
,w.subproject
,w.dist
from hostdb.who w
,(
select
unique
princ
,sum(pct) pct
,service_id
from
hostdb.who_service_charge wsc
group by princ, service_id
) x
where w.princ=x.princ
and w.pct != x.pct
and w.dist is not null
order by w.princ
/
prompt UPDATING
select * from hostdb.who where princ='abelhc';
select * from hostdb.who_service_charge where princ='abelhc';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='abelhc';
update hostdb.who set pct=3.5 where princ='abelhc';
select * from hostdb.who where princ='aeow';
select * from hostdb.who_service_charge where princ='aeow';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='aeow';
update hostdb.who set pct=3.5 where princ='aeow';
select * from hostdb.who where princ='aphillip';
select * from hostdb.who_service_charge where princ='aphillip';
  -- from 100 to 30
update hostdb.who set pct=29.5 where princ='aphillip';
update hostdb.who set pct=30 where princ='aphillip';
select * from hostdb.who where princ='asangpet';
select * from hostdb.who_service_charge where princ='asangpet';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='asangpet';
update hostdb.who set pct=3.5 where princ='asangpet';
select * from hostdb.who where princ='dhousman';
select * from hostdb.who_service_charge where princ='dhousman';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='dhousman';
update hostdb.who set pct=3.5 where princ='dhousman';
select * from hostdb.who where princ='djseo';
select * from hostdb.who_service_charge where princ='djseo';
  -- from 100 to 60
update hostdb.who set pct=59.5 where princ='djseo';
update hostdb.who set pct=60 where princ='djseo';
select * from hostdb.who where princ='drulhe';
select * from hostdb.who_service_charge where princ='drulhe';
  -- from 100 to 5
update hostdb.who set pct=4.5 where princ='drulhe';
update hostdb.who set pct=5 where princ='drulhe';
select * from hostdb.who where princ='ewj';
select * from hostdb.who_service_charge where princ='ewj';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='ewj';
update hostdb.who set pct=3.5 where princ='ewj';
select * from hostdb.who where princ='eyoon';
select * from hostdb.who_service_charge where princ='eyoon';
  -- from 4.92 to 3.5
update hostdb.who set pct=3 where princ='eyoon';
update hostdb.who set pct=3.5 where princ='eyoon';
select * from hostdb.who where princ='fukao';
select * from hostdb.who_service_charge where princ='fukao';
  -- from 100 to 1
update hostdb.who set pct=.5 where princ='fukao';
update hostdb.who set pct=1 where princ='fukao';
select * from hostdb.who where princ='garima';
select * from hostdb.who_service_charge where princ='garima';
  -- from 100 to 30
update hostdb.who set pct=29.5 where princ='garima';
update hostdb.who set pct=30 where princ='garima';
select * from hostdb.who where princ='guyb';
select * from hostdb.who_service_charge where princ='guyb';
  -- from 5.01 to 5
update hostdb.who set pct=4.5 where princ='guyb';
update hostdb.who set pct=5 where princ='guyb';
select * from hostdb.who where princ='jeffreyc';
select * from hostdb.who_service_charge where princ='jeffreyc';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='jeffreyc';
update hostdb.who set pct=3.5 where princ='jeffreyc';
select * from hostdb.who where princ='jiloreta';
select * from hostdb.who_service_charge where princ='jiloreta';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='jiloreta';
update hostdb.who set pct=3.5 where princ='jiloreta';
select * from hostdb.who where princ='jimi';
select * from hostdb.who_service_charge where princ='jimi';
  -- from 50 to 100
update hostdb.who set pct=99.5 where princ='jimi';
update hostdb.who set pct=100 where princ='jimi';
select * from hostdb.who where princ='jkirchho';
select * from hostdb.who_service_charge where princ='jkirchho';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='jkirchho';
update hostdb.who set pct=3.5 where princ='jkirchho';
select * from hostdb.who where princ='kdevale';
select * from hostdb.who_service_charge where princ='kdevale';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='kdevale';
update hostdb.who set pct=3.5 where princ='kdevale';
select * from hostdb.who where princ='klibby';
select * from hostdb.who_service_charge where princ='klibby';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='klibby';
update hostdb.who set pct=3.5 where princ='klibby';
select * from hostdb.who where princ='kling';
select * from hostdb.who_service_charge where princ='kling';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='kling';
update hostdb.who set pct=3.5 where princ='kling';
select * from hostdb.who where princ='knw';
select * from hostdb.who_service_charge where princ='knw';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='knw';
update hostdb.who set pct=3.5 where princ='knw';
select * from hostdb.who where princ='kosy';
select * from hostdb.who_service_charge where princ='kosy';
  -- from 20 to 3.5
update hostdb.who set pct=3 where princ='kosy';
update hostdb.who set pct=3.5 where princ='kosy';
select * from hostdb.who where princ='lcp';
select * from hostdb.who_service_charge where princ='lcp';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='lcp';
update hostdb.who set pct=3.5 where princ='lcp';
select * from hostdb.who where princ='lkirtane';
select * from hostdb.who_service_charge where princ='lkirtane';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='lkirtane';
update hostdb.who set pct=3.5 where princ='lkirtane';
select * from hostdb.who where princ='lowerre';
select * from hostdb.who_service_charge where princ='lowerre';
  -- from 50 to 5
update hostdb.who set pct=4.5 where princ='lowerre';
update hostdb.who set pct=5 where princ='lowerre';
select * from hostdb.who where princ='mecarson';
select * from hostdb.who_service_charge where princ='mecarson';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='mecarson';
update hostdb.who set pct=3.5 where princ='mecarson';
select * from hostdb.who where princ='meredyth';
select * from hostdb.who_service_charge where princ='meredyth';
  -- from 100 to 60
update hostdb.who set pct=59.5 where princ='meredyth';
update hostdb.who set pct=60 where princ='meredyth';
select * from hostdb.who where princ='mmonroe';
select * from hostdb.who_service_charge where princ='mmonroe';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='mmonroe';
update hostdb.who set pct=3.5 where princ='mmonroe';
select * from hostdb.who where princ='moldy';
select * from hostdb.who_service_charge where princ='moldy';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='moldy';
update hostdb.who set pct=3.5 where princ='moldy';
select * from hostdb.who where princ='mseltzer';
select * from hostdb.who_service_charge where princ='mseltzer';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='mseltzer';
update hostdb.who set pct=3.5 where princ='mseltzer';
select * from hostdb.who where princ='muralik';
select * from hostdb.who_service_charge where princ='muralik';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='muralik';
update hostdb.who set pct=3.5 where princ='muralik';
select * from hostdb.who where princ='nancy';
select * from hostdb.who_service_charge where princ='nancy';
  -- from 100 to 1
update hostdb.who set pct=.5 where princ='nancy';
update hostdb.who set pct=1 where princ='nancy';
select * from hostdb.who where princ='nobori';
select * from hostdb.who_service_charge where princ='nobori';
  -- from 100 to 1
update hostdb.who set pct=.5 where princ='nobori';
update hostdb.who set pct=1 where princ='nobori';
select * from hostdb.who where princ='queenie';
select * from hostdb.who_service_charge where princ='queenie';
  -- from 50 to 5
update hostdb.who set pct=4.5 where princ='queenie';
update hostdb.who set pct=5 where princ='queenie';
select * from hostdb.who where princ='rehak';
select * from hostdb.who_service_charge where princ='rehak';
  -- from 0 to 100
update hostdb.who set pct=99.5 where princ='rehak';
update hostdb.who set pct=100 where princ='rehak';
select * from hostdb.who where princ='rowan';
select * from hostdb.who_service_charge where princ='rowan';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='rowan';
update hostdb.who set pct=3.5 where princ='rowan';
select * from hostdb.who where princ='rsalgado';
select * from hostdb.who_service_charge where princ='rsalgado';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='rsalgado';
update hostdb.who set pct=3.5 where princ='rsalgado';
select * from hostdb.who where princ='sdavidof';
select * from hostdb.who_service_charge where princ='sdavidof';
  -- from 30 to 100
update hostdb.who set pct=99.5 where princ='sdavidof';
update hostdb.who set pct=100 where princ='sdavidof';
select * from hostdb.who where princ='smau';
select * from hostdb.who_service_charge where princ='smau';
  -- from 100 to 30
update hostdb.who set pct=29.5 where princ='smau';
update hostdb.who set pct=30 where princ='smau';
select * from hostdb.who where princ='sswarup';
select * from hostdb.who_service_charge where princ='sswarup';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='sswarup';
update hostdb.who set pct=3.5 where princ='sswarup';
select * from hostdb.who where princ='sub';
select * from hostdb.who_service_charge where princ='sub';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='sub';
update hostdb.who set pct=3.5 where princ='sub';
select * from hostdb.who where princ='suprnoop';
select * from hostdb.who_service_charge where princ='suprnoop';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='suprnoop';
update hostdb.who set pct=3.5 where princ='suprnoop';
select * from hostdb.who where princ='takuyat';
select * from hostdb.who_service_charge where princ='takuyat';
  -- from 60 to 3.5
update hostdb.who set pct=3 where princ='takuyat';
update hostdb.who set pct=3.5 where princ='takuyat';
select * from hostdb.who where princ='thati';
select * from hostdb.who_service_charge where princ='thati';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='thati';
update hostdb.who set pct=3.5 where princ='thati';
select * from hostdb.who where princ='tokura';
select * from hostdb.who_service_charge where princ='tokura';
  -- from 60 to 3.5
update hostdb.who set pct=3 where princ='tokura';
update hostdb.who set pct=3.5 where princ='tokura';
select * from hostdb.who where princ='tomoki';
select * from hostdb.who_service_charge where princ='tomoki';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='tomoki';
update hostdb.who set pct=3.5 where princ='tomoki';
select * from hostdb.who where princ='ttwu';
select * from hostdb.who_service_charge where princ='ttwu';
  -- from 100 to 3.5
update hostdb.who set pct=3 where princ='ttwu';
update hostdb.who set pct=3.5 where princ='ttwu';
select * from hostdb.who where princ='yegna';
select * from hostdb.who_service_charge where princ='yegna';
  -- from 30 to 3.5
update hostdb.who set pct=3 where princ='yegna';
update hostdb.who set pct=3.5 where princ='yegna';
Elapsed: 00:00:00.78
prompt AFTER UPDATE
select
unique
w.princ
,w.pct pct_configured
,x.pct pct_charged
,w.charge_by
,w.dist_src
,w.project
,w.subproject
,w.dist
from hostdb.who w
,(
select
unique
princ
,sum(pct) pct
,service_id
from
hostdb.who_service_charge wsc
group by princ, service_id
) x
where w.princ=x.princ
and w.pct != x.pct
and w.dist is not null
order by w.princ
/
spool off
set termout on
