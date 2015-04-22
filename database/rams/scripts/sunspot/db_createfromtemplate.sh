#!/bin/sh
#$Header: c:\\Repository/database/rams/scripts/sunspot/db_createfromtemplate.sh,v 1.1 2005/01/06 16:28:06 yangl Exp $

. ./common.sh

if [ ! -d ${XSCRIPT_LOGDIR} ]; then
	mkdir ${XSCRIPT_BASE}/${XSCRIPT_LOGDIR}
fi

if [ x"${XSCRIPT_ONLY}" = "xFALSE" ]; then
	if [ ! -d ${XDBF_DIR}/${XDB_SID} ]; then
		mkdir -p ${XDBF_DIR}/${XDB_SID}
	fi
	
	if [ ! -d ${XARCH_LOG_BASE} ]; then
		mkdir -p ${XARCH_LOG_BASE}
	fi

	if [ ! -d ${XDUMP_BASE}/bdump ]; then
		mkdir ${XDUMP_BASE}/bdump
	fi
	if [ ! -d ${XDUMP_BASE}/cdump ]; then
		mkdir ${XDUMP_BASE}/cdump
	fi
	if [ ! -d ${XDUMP_BASE}/create ]; then
		mkdir ${XDUMP_BASE}/create
	fi

	if [ ! -d ${XDUMP_BASE}/pfile ]; then
		mkdir ${XDUMP_BASE}/pfile
	fi
	if [ -f ${XDUMP_BASE}/pfile/init.ora ]; then
		echo "${XDUMP_BASE}/pfile/init.ora exists, exitting..."
		exit;
	fi
	if [ ! -d ${XDUMP_BASE}/udump ]; then
		mkdir ${XDUMP_BASE}/udump
	fi

	if [ ! -d ${XDB_HOME}/dbs ]; then
		mkdir ${XDB_HOME}/dbs
	fi

	if [ ! -d /usr1/oradata/${XDB_SID} ]; then
		mkdir /usr1/oradata/${XDB_SID}
	fi
	if [ ! -d /usr0/oradata/${XDB_SID} ]; then
		mkdir /usr0/oradata/${XDB_SID}
	fi
	if [ ! -d /usr2/oradata/${XDB_SID} ]; then
		mkdir /usr2/oradata/${XDB_SID}
	fi

fi

ORACLE_SID=${XDB_SID}
export ORACLE_SID
echo Add this entry in the oratab: ${XDB_SID}:${XDB_HOME}:Y
if [ x"${XSCRIPT_ONLY}" = "xFALSE" ]; then
	${XDB_HOME}/bin/orapwd file=${XDB_HOME}/dbs/orapw${ORACLE_SID} password=change_on_install
fi

if [ ! -d ${XSCRIPT_BASE}/work ]; then
	mkdir ${XSCRIPT_BASE}/work
fi
#Generate sql files from the template files
for i in ${XTEMPLATE_LIST}; do
	${XSED} \
		< ${XSCRIPT_BASE}/template/$i \
		-e "s/_DB_SID_/${XDB_SID}/g" \
		-e "s/_DB_DOMAIN_/${XDB_DOMAIN}/g" \
		-e "s,_INIT_ORA_,${XDUMP_BASE}/pfile/init.ora,g" 	\
		-e "s,_SPFILE_NAME_,${XDUMP_BASE}/pfile/spfile${XDB_SID}.ora,g" 	\
		-e "s,_LOGS_DIR_,logs,g" 	\
		-e "s,_DB_BASE_,${XDB_BASE},g"  \
		-e "s,_DB_HOME_,${XDB_HOME},g" 	\
		-e "s,_DB_DUMPBASE_,${XDUMP_BASE},g"    \
		-e "s,_REDO_LOG_1_,${XREDO_LOG_DIR1}/${XDB_SID}/redo_01.log,g" 	\
		-e "s,_REDO_LOG_2_,${XREDO_LOG_DIR2}/${XDB_SID}/redo_02.log,g" 	\
		-e "s,_REDO_LOG_3_,${XREDO_LOG_DIR3}/${XDB_SID}/redo_03.log,g" 	\
		-e "s,_ARCHLOG_DIR_,${XARCH_LOG_BASE},g" 	\
		-e "s,_CTL_FILE1_,${XCTL_FILE1},g" 	\
		-e "s,_CTL_FILE2_,${XCTL_FILE2},g" 	\
		-e "s,_CTL_FILE3_,${XCTL_FILE3},g" 	\
		> ${XSCRIPT_BASE}/work/${i}.tmp;
	#for j in SYSTEM UNDO TEMP APPS COSTING CWMLITE DRSYS INDX ODM TEMP2 TOOLS USERS XDB; do
	for j in ${XDBF_LIST}; do
		j_lower=`echo "$j" | tr '[A-Z]' '[a-z]'`
		${XSED} \
			< ${XSCRIPT_BASE}/work/${i}.tmp \
			-e "s,_DBF_${j}_,/usr0/oradata/${XDB_SID}/${j_lower}_01.dbf,g" 	\
			> ${XSCRIPT_BASE}/work/$i
		\rm -f ${XSCRIPT_BASE}/work/${i}.tmp
		mv ${XSCRIPT_BASE}/work/$i ${XSCRIPT_BASE}/work/${i}.tmp
	done
	mv ${XSCRIPT_BASE}/work/${i}.tmp ${XSCRIPT_BASE}/work/${i}
done

if [ x"${XSCRIPT_ONLY}" = "xFALSE" ]; then
	cp ${XSCRIPT_BASE}/work/init.ora ${XDUMP_BASE}/pfile/init.ora
fi
if [ $? -gt 0 ]; then
	echo "Failed copying init.ora from ${XSCRIPT_BASE}/work/ to ${XDUMP_BASE}/pfile/"
	exit
fi

# Execute the generated sql files
#if [ x"${XSCRIPT_ONLY}" = "xFALSE" ]; then
	#for i in ${XEXEC_SQLLIST}; do
		#${XDB_HOME}/bin/sqlplus /nolog @${XSCRIPT_BASE}/work/$i
	#done
#fi
