#!/bin/sh

set -e
#set -x

OLD_SID=fac
SID=fac_02
TS=`whenis -f "%04year%02nmonth%02day%02hour%02min" now`

SRC_DIR=/usr13/temp/pre

ORA_OWNER=oracle
ORA_GRP=oradba
ORACLE_BASE=/usr1/app/oracle
ORACLE_HOME=/usr1/app/oracle/product/9.2

ARCHLOG_1=/usr12/oralogs/arch/$SID
ARCHLOG_2=/usr22/oralogs/arch/$SID

DBFILES="/usr10/oradata/$SID/system01.dbf /usr10/oradata/$SID/tools01.dbf /usr13/oradata/$SID/undotbs01.dbf /usr20/oradata/$SID/apps.dbf /usr20/oradata/$SID/costing.dbf /usr20/oradata/$SID/costing_lg.dbf /usr20/oradata/$SID/cwmlite01.dbf /usr20/oradata/$SID/drsys01.dbf /usr20/oradata/$SID/odm01.dbf /usr20/oradata/$SID/users01.dbf /usr20/oradata/$SID/xdb01.dbf /usr21/oradata/$SID/indx01.dbf"
#DBFILES="/usr10/oradata/$SID/system01.dbf /usr10/oradata/$SID/temp01.dbf /usr10/oradata/$SID/temp2.dbf /usr10/oradata/$SID/tools01.dbf /usr13/oradata/$SID/undotbs01.dbf /usr20/oradata/$SID/apps.dbf /usr20/oradata/$SID/costing.dbf /usr20/oradata/$SID/costing_lg.dbf /usr20/oradata/$SID/cwmlite01.dbf /usr20/oradata/$SID/drsys01.dbf /usr20/oradata/$SID/odm01.dbf /usr20/oradata/$SID/users01.dbf /usr20/oradata/$SID/xdb01.dbf /usr21/oradata/$SID/indx01.dbf"

REDODIR_1=/usr11/oralogs/$SID
REDODIR_2=/usr23/oralogs/$SID
REDOPREFIX=redo
REDOSUF=.log

REDO_FILES="${REDODIR_1}/${REDOPREFIX}01${REDOSUF} ${REDODIR_2}/${REDOPREFIX}01${REDOSUF} \
	${REDODIR_1}/${REDOPREFIX}02${REDOSUF} ${REDODIR_2}/${REDOPREFIX}02${REDOSUF} \
	${REDODIR_1}/${REDOPREFIX}03${REDOSUF} ${REDODIR_2}/${REDOPREFIX}03${REDOSUF} \
	${REDODIR_1}/${REDOPREFIX}04${REDOSUF} ${REDODIR_2}/${REDOPREFIX}04${REDOSUF}"

# not use the control files, instead re-create them
#CTL_FILES="/usr12/oradata/$SID/control01.ctl /usr21/oradata/$SID/control02.ctl /usr23/oradata/$SID/control03.ctl"

#------------------------------------------------------------------------

for DIR in $ARCHLOG_1 $ARCHLOG_2 /usr10/oradata/$SID /usr13/oradata/$SID /usr20/oradata/$SID /usr21/oradata/$SID $REDODIR_1 $REDODIR_2 /usr12/oradata/$SID /usr21/oradata/$SID /usr23/oradata/$SID; do
	if [ -d ${DIR} ]; then
		echo "Renaming ${DIR} to ${DIR}.${TS}"
		mv ${DIR} ${DIR}.${TS}
	fi
	mkdir -p ${DIR}
	chown ${ORA_OWNER}:${ORA_GRP} ${DIR}
done

#------------------------------------------------------------------------

for FILE in $DBFILES; do
	echo "Uncompress and restoring file $FILE"
	uncompress -c ${SRC_DIR}/`basename ${FILE}`.Z > ${FILE}
	chown ${ORA_OWNER}:${ORA_GRP} ${FILE}
done

#------------------------------------------------------------------------
if [ ! -d ${ORACLE_BASE}/admin/$SID ]; then
	mkdir -p ${ORACLE_BASE}/admin/$SID
	mkdir -p ${ORACLE_BASE}/admin/$SID/pfile
	mkdir -p ${ORACLE_BASE}/admin/$SID/create
	mkdir -p ${ORACLE_BASE}/admin/$SID/udump
	mkdir -p ${ORACLE_BASE}/admin/$SID/bdump
	mkdir -p ${ORACLE_BASE}/admin/$SID/cdump
	chown -R ${ORA_OWNER}:${ORA_GRP} ${ORACLE_BASE}/admin/$SID
fi

if [ ! -d ${ORACLE_BASE}/admin/$SID/pfile ]; then
	mkdir -p ${ORACLE_BASE}/admin/$SID/pfile
	chown -R ${ORA_OWNER}:${ORA_GRP} ${ORACLE_BASE}/admin/$SID/pfile
fi

sed -e 's/'${OLD_SID}'/'${SID}'/g' < ${SRC_DIR}/init.ora > ${ORACLE_BASE}/admin/$SID/pfile/init${SID}.ora
chown ${ORA_OWNER}:${ORA_GRP} ${ORACLE_BASE}/admin/$SID/pfile/init${SID}.ora
sed -e 's/'${OLD_SID}'/'${SID}'/g' <  ${SRC_DIR}/spfile${OLD_SID}.ora > ${ORACLE_BASE}/admin/$SID/pfile/spfile${SID}.ora
chown ${ORA_OWNER}:${ORA_GRP} ${ORACLE_BASE}/admin/$SID/pfile/spfile${SID}.ora

(cd ${ORACLE_HOME}/dbs;ln -s ${ORACLE_BASE}/admin/$SID/pfile/init${SID}.ora .)
(cd ${ORACLE_HOME}/dbs;ln -s ${ORACLE_BASE}/admin/$SID/pfile/spfile${SID}.ora .)

#------------------------------------------------------------------------
# the following command need to be run as oracle owner
#(su ${ORA_OWNER};orapwd file=orapw${SID} password=Weh3205 entries=6)
