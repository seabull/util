#!/bin/sh
#$Header: c:\\Repository/database/rams/scripts/sunspot/common.sh,v 1.1 2005/01/06 16:28:06 yangl Exp $

#------------------------------------------------
XSED=sed

#------------------------------------------------
XDB_SID=facqa
XDB_DOMAIN=sunspot.srv.cs.cmu.edu
XDB_BASE=${ORACLE_BASE:-/usr1/app/oracle}
XDB_HOME=${ORACLE_HOME:-/usr1/app/oracle/product/9.2}

XSCRIPT_BASE=.
XSCRIPT_LOGDIR=logs

XDUMP_BASE=${XDB_BASE}/admin/${XDB_SID}
XDBF_DIR=/usr0/oradata

#XREDO_LOG_BASE=/usr0/oralogs
XREDO_LOG_DIR1=/usr0/oralogs
XREDO_LOG_DIR2=/usr0/oralogs
XREDO_LOG_DIR3=/usr0/oralogs

XARCH_LOG_BASE=/usr0/oralogs/${XDB_SID}/arch
XCTL_FILE1=/usr0/oradata/${XDB_SID}/control_01.ctl
XCTL_FILE2=/usr0/oradata/${XDB_SID}/control_02.ctl
XCTL_FILE3=/usr0/oradata/${XDB_SID}/control_03.ctl

XTEMPLATE_LIST="init.ora		\
		CreateDB.sql		\
		CreateDBCatalog.sql 	\
		CreateDBFiles.sql 	\
		JServer.sql		\
		context.sql		\
		cwmlite.sql 		\
		interMedia.sql		\
		odm.sql			\
		ordinst.sql		\
		postDBCreation.sql	\
		spatial.sql		\
		ultraSearch.sql		\
		xdb_protocol.sql	\
		"

XEXEC_SQLLIST="	CreateDB.sql		\
		CreateDBCatalog.sql 	\
		CreateDBFiles.sql 	\
		JServer.sql		\
		context.sql		\
		cwmlite.sql 		\
		interMedia.sql		\
		odm.sql			\
		ordinst.sql		\
		postDBCreation.sql	\
		spatial.sql		\
		ultraSearch.sql		\
		xdb_protocol.sql	\
		"

XDBF_LIST="SYSTEM	\
		UNDO	\
		TEMP	\
		APPS	\
		COSTING	\
		CWMLITE	\
		DRSYS	\
		INDX	\
		ODM	\
		TEMP2	\
		TOOLS	\
		USERS	\
		XDB	\
		"
#-----------------------------------------
# Place Holders
#-----------------------------------------
#_DB_SID_
#_INIT_ORA_
#_LOGS_DIR_
#_DB_HOME_
#_DB_DOMAIN_
#_DB_BASE_
#_CTL_FILE1_
#_CTL_FILE2_
#_CTL_FILE3_

#_DBF_SYSTEM_
#_DBF_UNDO_
#_DBF_TEMP_
#_REDO_LOG_1_
#_REDO_LOG_2_
#_REDO_LOG_3_
#_ARCHLOG_DIR_
#
#_DBF_APPS_
#_DBF_COSTING_
#_DBF_CWMLITE_
#_DBF_DRSYS_
#_DBF_INDX_
#_DBF_ODM_
#_DBF_TEMP2_
#_DBF_TOOLS_
#_DBF_USERS_
#_DBF_XDB_
#_SPFILE_NAME_

#set -x
