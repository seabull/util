--yangl@cs.cmu.edu@FAC.SUNSPOT> set linesize 1000
--yangl@cs.cmu.edu@FAC.SUNSPOT> select * from hostdb.who where dist is not null and dist_src!=upper(dist_src) order by princ;
--

spool 20070701-user-tmcd.log
update hostdb.who
   set pct=100
 where charge_by is null
   and princ in (
'abarkin'
,'ahalapin'
,'amaries'
,'ankura'
,'awoolsey'
,'bkisiel'
,'cyp'
,'dack'
,'dhora'
,'emcconvi'
,'fahd'
,'farahh'
,'firebird'
,'fslick'
,'gkanga'
,'jakinyel'
,'jaroot'
,'jbrun'
,'jdamato'
,'jmwaura'
,'jngiam'
,'joeldaws'
,'jtpender'
,'jywu'
,'lbancrof'
,'lisa'
,'lrprice'
,'lynn12'
,'mbell'
,'memers'
,'mhagenia'
,'mor7226'
,'payoub'
,'pfriedma'
,'pmckenne'
,'sjaganna'
,'snidhiry'
,'stkaplan'
,'syng'
,'tamirs'
,'tblose'
,'wko2'
)
/
spool off
