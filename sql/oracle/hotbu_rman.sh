#!/usr/local/bin/sh 

ORACLE_HOME=/usr1/app/oracle/product/9.2
ORACLE_SID=facdev
BKUP_DIR=/
CTLBK_DIR=${BKUP_DIR}/ctl/${ORACLE_SID}
RMANBK_DIR=${BKUP_DIR}/rman/${ORACLE_SID}

NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"; export NLS_DATE_FORMAT 
NLS_LANG=AMERICAN_AMERICA.UTF8; export NLS_LANG 
DOW=`date '+%a'` 
BD='${BKUP_DIR}/rman/${ORACLE_SID}' 
#tf=`date '+%Y-%m-%d_%H%M%S'` 
#ctlfile=${BKUP_DIR}/ctl/${ORACLE_SID}/${tf}.ctl.bk 

ZIP=gzip
FIND=find

#ctlbkfile="'${BKUP_DIR}/ctl/${ORACLE_SID}/`date '+%Y-%m-%d_%H%M%S'`_ctl_bk'" 
#level0="'${BKUP_DIR}/rman/${ORACLE_SID}/`date '+%Y-%m-%d_%H%M%S'`_level0_%U'" 
#level1="'${BKUP_DIR}/rman/${ORACLE_SID}/`date '+%Y-%m-%d_%H%M%S'`_level1_%U'" 
#level2="'${BKUP_DIR}/rman/${ORACLE_SID}/`date '+%Y-%m-%d_%H%M%S'`_level2_%U'" 
#arch="'${BKUP_DIR}/rman/${ORACLE_SID}/`date '+%Y-%m-%d_%H%M%S'`_arch_%U'" 
ctlbkfile="'${CTLBK_DIR}/`date '+%Y-%m-%d_%H%M%S'`_ctl_bk'" 
level0="'${RMANBK_DIR}/`date '+%Y-%m-%d_%H%M%S'`_level0_%U'" 
level1="'${RMANBK_DIR}/`date '+%Y-%m-%d_%H%M%S'`_level1_%U'" 
level2="'${RMANBK_DIR}/`date '+%Y-%m-%d_%H%M%S'`_level2_%U'" 
arch="'${RMANBK_DIR}/`date '+%Y-%m-%d_%H%M%S'`_arch_%U'" 

############### FUNCTIONS ################ 
CTLBK() { 
$ORACLE_HOME/bin/sqlplus /nolog << EOF 
connect internal; 
alter system switch logfile; 
alter database backup controlfile to $ctlbkfile; 
exit; 
EOF 
} 

XCHECK() { 
$ORACLE_HOME/bin/rman target / nocatalog << EOF 
allocate channel for maintenance type disk; 
crosscheck backup completed before 'SYSDATE - 14' ; 
#crosscheck backup completed before 'SYSDATE - 4' ; 
delete expired backupset; 
release channel ; 
EOF 
} 
INCR0() { 
$ORACLE_HOME/bin/rman target / nocatalog << EOF 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
sql "alter system archive log current"; 
backup incremental level 0 
format $level0 
database; 
release channel dev1; 
release channel dev2; 
} 
# backs up all archive logs and deletes them 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
backup 
format $arch 
(archivelog from time 'sysdate -1' ); 
#(archivelog all delete input); 
release channel dev1; 
release channel dev2; 
} 
EOF 
} 

INCR1() { 
$ORACLE_HOME/bin/rman target / nocatalog << EOF 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
sql "alter system archive log current"; 
backup incremental level 1 
format $level1 
database; 
release channel dev1; 
release channel dev2; 
} 
# backs up all archive logs and deletes them 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
backup 
format $arch 
(archivelog from time 'SYSDATE-1' ); 
#(archivelog all delete input); 
release channel dev1; 
release channel dev2; 
} 
EOF 
} 

INCR2() { 
$ORACLE_HOME/bin/rman target / nocatalog << EOF 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
sql "alter system archive log current"; 
backup incremental level 2 
format $level2 
database; 
release channel dev1; 
release channel dev2; 
} 
# backs up all archive logs and deletes them 
run { 
allocate channel dev1 type disk; 
allocate channel dev2 type disk; 
backup 
format $arch 
(archivelog from time 'SYSDATE-1' ); 
#(archivelog all delete input); 
release channel dev1; 
release channel dev2; 
} 
EOF 
} 

case $DOW in 
Mon ) INCR0; CTLBK ;; 
Tue ) INCR2; CTLBK ;; 
Wed ) INCR2; CTLBK ;; 
Thu ) INCR0; CTLBK ;; 
Fri ) INCR1; CTLBK ;; 
Sat ) INCR0;XCHECK; CTLBK ;; 
Sun ) INCR1; CTLBK ;; 
esac 

${ZIP} ${BKUP_DIR}/rman/${ORACLE_SID}/*_1_1 
${FIND} ${BKUP_DIR}/rman/${ORACLE_SID}/*.gz -mtime +7 -exec rm {} \; 
${FIND} /oracle/ora12/oracle/arch/${ORACLE_SID}/*.arc -mtime +14 -exec rm {} \; 
${FIND} ${BKUP_DIR}/ctl/${ORACLE_SID} -mtime +7 -exec rm {} \;

