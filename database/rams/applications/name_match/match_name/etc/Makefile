DB_HOST=facqa.crescent
SRC=src/
CTL=${SRC}ctl/
TODAY=.today.
X_SCP=/usr/local/bin/scp
EXTERNAL_DIR=/usr/costing/data/external

AFSUSERS=/usr/costing/lib/expire/afs_users
AFS_USER=/afs/cs.cmu.edu/user

X_SORT=sort -T /tmp
X_MAKE=${MAKE} -f premake.mk -f ${SRC}Makefile

_Run_:
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}premake.sql
	${X_MAKE} _Prerequisites_
	${X_MAKE} _Daily_

#
#  These prerequisites are always run before the daily productions.
#
#  ${TODAY} is used to trigger productions which need fire only once a day, e.g.
#  polled data files and is set to a constant modification time of
#  "today at 00:30am".
#
_Prerequisites_:
	touch ${NEEDED:%=.%_touch.} .dummy.
	touch -t `whenis -f "%02nmonth%02day0030.00" now` ${TODAY}


_Daily_: _Polls_ .biweekly. .ices. .labor. .dist_names. .names_apply. \
	_Journal_Entry_ _Profile_Web_Report_


#####
#
#  Polled data files
#
#####

VALIDS=\
    project task award gms_combo gl_combo

SCP_POLLS=$(VALIDS:%=.valid_%_polled.) .hris_org_polled.
#SCP_POLLS=$(VALIDS:%=.valid_%_polled.) 

AFS_POLL=.afs_polled.

EMP_MAP=scs_id_ssn

BACKUP_POLL=.backup_polled.

_Polls_: ${SCP_POLLS} ${AFS_POLL} ${BACKUP_POLL} .unlimbo. .acl_load.

${SCP_POLLS}: ${TODAY}

valid_award_SYNC=DOT15_
valid_project_SYNC=DOT15_
DOT15_SYNC_FIRST=...............
DOT15_SYNC_EMPTY="               "
DOT15_SYNC_PREPEND=p

SYNC_FIRST=.
SYNC_EMPTY=" "
SYNC_PREPEND=s;^;X,;p

FIRST_COLUMN=${${$*_SYNC}SYNC_FIRST}
EMPTY_COLUMN=${${$*_SYNC}SYNC_EMPTY}
PREPEND_COLUMN=${${$*_SYNC}SYNC_PREPEND}


.%_polled.:
	${X_SCP} -q -i ${HOME}/docs-down transfer@superman.as.cmu.edu:$*.dat $*.new
	sed -n <$*.new -e "${PREPEND_COLUMN}" | \
		sed -e "s;${FIRST_COLUMN};"${EMPTY_COLUMN}";" -e 's;^.;X;' \
		>$*.tmp
	@${X_SORT} -o $*.new $*.tmp
	@rm -f $*.tmp
	@\
	set -x;\
	l_stamp=`whenis -f "%04year%02nmonth%02day" now`;\
	if [ ! -d Archive/$$l_stamp ]; then	\
		mkdir Archive/$$l_stamp;	\
	fi;	\
	cp $** Archive/$$l_stamp
	${SRC}new-table-sync.sh $* ${SRC}ctl \
	     /@${DB_HOST} "${FIRST_COLUMN}" ${EMPTY_COLUMN} "${SRC}oasme.sh"
	${SRC}mvcmp.sh $*.new $*.dat
	>$@


#.%_polled.:
#	${X_SCP} -q -i ${HOME}/docs-down transfer@superman.as.cmu.edu:$*.dat $*.new
#	@sed -n <$*.new -e "${PREPEND_COLUMN}"  >$*.tmp
#	@${X_SORT} -o $*.new $*.tmp
#	@rm -f $*.tmp
#	${SRC}table-sync.sh ${CTL}$*.ctl $*.bad log/$*.log $*.dat $*.new \
#	     /@${DB_HOST} "${FIRST_COLUMN}" ${EMPTY_COLUMN} "${SRC}oasme.sh sqlldr"
#	${SRC}mvcmp.sh $*.new $*.dat
#	>$@

jhutz_test_%:
	${X_SCP} -q -i ${HOME}/docs-down transfer@superman.as.cmu.edu:$*.dat $*.new
	@sed -n <$*.new -e "${PREPEND_COLUMN}"  >$*.tmp
	@${X_SORT} -o $*.new $*.tmp
	@rm -f $*.tmp
	${SRC}new-table-sync.sh $* ${SRC}ctl-jhutz \
	     /@${DB_HOST} "${FIRST_COLUMN}" ${EMPTY_COLUMN} "${SRC}oasme.sh"


#####
#
#  Unix backup attribute poll
#
#  uudecode and tar are used to obtain a reliable exit status fromn days when
#  it had to be fetched from Mach.  Could be replaced by a more modern
#  mechanism now that doesn't need the helper bin/fetch-costing.sh
#  script on MAST either.
#
#####

${BACKUP_POLL}:
	rm -f fetch-costing.tar
	/usr/costing/bin/asme ${SRC}rsh.sh costing mast \
	    bin/fetch-costing.sh > BackupReport.uu
	uudecode BackupReport.uu
	tar xf fetch-costing.tar
	awk '$$1 == "HOST" {print " ," $$5; }' \
	     <BackupReport.txt >BackupReport.new
	sort -u BackupReport.new -o BackupReport.new
	${SRC}table-sync.sh ${CTL}BackupReport.ctl BackupReport.bad log/BackupReport.log BackupReport.dat BackupReport.new /@${DB_HOST} '.' ' ' "${SRC}oasme.sh sqlldr"
	${SRC}mvcmp.sh BackupReport.new BackupReport.dat 
	rm -f fetch-costing.tar BackupReport.uu BackupReport.txt
	touch $@

#####
#
#  AFS user atrribute poll (of /afs/cs/user)
#
#####

${AFS_POLL} ${AFSUSERS}: ${TODAY}
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}users_only.sql
	test -d ${AFS_USER}
	ls ${AFS_USER} | (umask 22; exec tee ${AFSUSERS}.tmp >afs_users.tmp)
	comm -12 users_only.dat afs_users.tmp >afs_users_only.tmp
	test -d ${AFS_USER}
	sed <afs_users_only.tmp -e 's;$$;        ;' \
		-e 's;^\(........\).*;X,\1,AFS,+;' \
		| ${X_SORT} >afs_users.new
	rm -f afs_users.tmp afs_users_only.tmp
	@\
	set -x;\
	l_stamp=`whenis -f "%04year%02nmonth%02day" now`;\
	if [ ! -d Archive/$$l_stamp ]; then	\
		mkdir Archive/$$l_stamp;	\
	fi;	\
	cp afs_users* Archive/$$l_stamp
	${SRC}new-table-sync.sh afs_users ${SRC}ctl \
	     /@${DB_HOST} '.' ' ' "${SRC}oasme.sh"
	${SRC}mvcmp.sh afs_users.new afs_users.dat
	>$@

#####
#
# Unmark accounts which appear to be valid yet are marked as limbo
#
#####

.unlimbo.: ${SCP_POLLS}
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}unlimbo.sql
	>$@

#####
#
# Pick up the upload file for acl tables from ACIS daily
#
#####
.acl_load.: ${TODAY}
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload_pta_status.csv ${HOME}/Run/src/fmp/upload
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload_acl_users.csv ${HOME}/Run/src/fmp/upload
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload_projects.csv ${HOME}/Run/src/fmp/upload
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload_gl_orgs.csv ${HOME}/Run/src/fmp/upload
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload_acl_profile_users.csv ${HOME}/Run/src/fmp/upload
	@rm -f ${HOME}/Run/src/fmp/log/acl_ldrs.log
	${HOME}/Run/src/fmp/bin/acl_ldrs.sh > ${HOME}/Run/src/fmp/log/acl_ldrs.log
	>$@
	#${SRC}pickup.pl $@.txt
	
#####
#
#  Biweekly timecard processing
#
#####

TIMECARDS=$(BIWEEKLY_MAYBE:%=timecards.b%)

#  Loop backward through the candidate set, stopping when we receive
#  a batch which is loaded successfully.  When we don't get a loaded
#  batch, remove both the temporary and target file.  The temporary
#  file is left as residue from an unsuccessful pickup and the
#  the target file should be refetched if the load failed in case a
#  format problem with the data at the source caused the failure.

#.biweekly.: .biweekly_touch.
#.biweekly.: ${EMP_MAP}
.biweekly.: .scs_id_ssn.
	@\
	set -x; \
	for t in ${TIMECARDS}; do \
	    ${X_MAKE} $$t.sqlldr && touch $@ && break; \
	    rm -f $$t $$t.tmp; \
	done
	@test -f $@
	#echo "No timecard load"

# pick up the ssn/emp_num/name mapping from magenta	--ylj
.scs_id_ssn.: .biweekly_touch.
	${SRC}pickup.pl scs_id_ssn.txt
	#sed  <$@.txt  -e "s;    ;|;g" > $@.dat
	cp -f scs_id_ssn.txt ${EXTERNAL_DIR}
	#${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}exec_sqlproc hostdb.names.emp_load
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}exec_sqlproc hostdb.names.emp_load
	touch $@

#  Pick up a timecard batch from /usr/costdrop/effort on MAGENTA

${TIMECARDS}:
	${SRC}pickup.pl $@

#  Load the record the batch.  If timecardRecord commits, the db date is
#  advance and the next invocation of make will look for the next batch
#  at the designated time.

.SUFFIXES: .sqlldr

timecards.b%.sqlldr: timecards.b%
	sed <timecards.b$* -e 's;^;$*;'  >tmcd.dat
	${SRC}oasme.sh sqlldr /@${DB_HOST} ${CTL}tmcd.ctl \
	     DATA=tmcd.dat LOG=log/tmcd.log SILENT=feedback,header
	rm -f timecards.bad
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run timecardRecord
	#echo "No Timecard load."


#####
#
#  ICES labor distribution processing
#
#####

.ices.: .ices_touch.
	#${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run ICESRecord
	touch $@

	
#####
#
#  Full-time payroll labor distribution processing
#
#####

.labor.: .labor_touch.
	${SRC}pickup.pl scs_id_ssn.txt
	cp -f scs_id_ssn.txt ${EXTERNAL_DIR}
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}exec_sqlproc hostdb.names.emp_load
	#${SRC}oasme.sh sqlldr /@${DB_HOST} ${CTL}emp.ctl \
	#	LOG=log/scs_id_ssn.log \
	#	DATA=scs_id_ssn.txt SILENT=feedback,header
	${X_SCP} -i ${HOME}/fmp-down transfer@superman.as.cmu.edu:cs_recharge/logs/scs_outload.dat .
	${SRC}oasme.sh sqlldr /@${DB_HOST} ${CTL}labor.ctl \
	     LOG=log/scs_outload.log \
	     DATA=scs_outload.dat SILENT=feedback,header
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run laborRecord
	cp scs_outload.dat ${HOME}/Run/ld.archive/`date '+%Y%m%d'`scs_outload.dat
	touch $@


#####
#
#  Process the labor, ICES and timecard data into new dist_names
#
#####

.dist_names.: .dist_names_touch.
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run 'peopleDistNames(null)'
	touch $@


#####
#
#  Process the tentative dist_names into the production table
#
#####

.names_apply.: .names_apply_touch.
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run 'peopleDistNamesApply'
	touch $@

	

#####
#
#  Produce a journal entry from currently captured data.
#
#####

_Journal_Entry_: .feeder_notify.

.journal_entry.: .journal_entry_touch.
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} \
	    @${SRC}run 'journalRecord(true)'
	touch $@

feeder.je feeder-mesg.body: .journal_entry.
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} \
	    @${SRC}je feederT.je feeder-mesgT.body
	mv feeder-mesgT.body feeder-mesg.body
	mv feederT.je feeder.je

.feeder_notify.: feeder.je feeder-mesg.body
	${SRC}feeder-submit.sh feeder.je feeder-mesg.body \
	    "ryanj@andrew.cmu.edu"  "costing+fyi"
	touch $@


#####
#
#  Fetch the report corresponding to the current journal entry
#
#####

_Fetch_Report_:
	${SRC}fetch_report.sh feeder.je feeder.rpt
	

#####
#
#  Trigger resubmission of rejected journal entry
#
#####

_Rejected_:
	rm -f feeder.je


#####
#
#  Confirm acceptance of journal entry, perform cleanup operations and
#  advance the parameters.  Should only be run when a journal entry
#  has been submitted.
#
#####

_Accepted_:
	${SRC}oasme.sh sqlplus -s /@${DB_HOST} @${SRC}run 'journalAccepted'
	${SRC}limbo-rpt-ylj.sh

#####
#
#  Report rejected charges 
#
#####

_Limbo_Report_:
	${SRC}limbo-rpt.sh 
		

_Profile_Web_Report_:
	${SRC}report-gen/web_update/refresh_rpt_tables.sh

_Andrew_Ldap_Dropoff_:
	#${SRC}AndrewLDAP/scs_ldap_drop.sh

