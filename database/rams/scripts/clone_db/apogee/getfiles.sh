#!/bin/sh
#$Id: getfiles.sh,v 1.1 2005/03/03 22:23:15 yangl Exp $
#---------------------------------------------------------------------------
# Use scp to copy a directory tree from source host to dest host.
# Currently, you have to be on either source or dest host to run the script.
# i.e. the script does either
#	scp -r source_host:/path/to/tree /path/to/dest
# or 
#	scp -r /path/to/tree dest_host:/path/to/dest
#---------------------------------------------------------------------------

SCP=/usr/local/bin/scp

LOCAL_HOST=`hostname`
LOCAL_HOST=`basename ${LOCAL_HOST} .cs.cmu.edu |sed -e 's/\..*//g'`

SOURCE_HOST=sunspot
DEST_HOST=apogee

DEST_DIR=/usr13/temp
#SOURCE_DIR=/usr11/orabkup/fac/cold
SOURCE_DIR=/usr11/orabkup/fac/je/2005-03-01/pre

if [ x"${LOCAL_HOST}" = x"${SOURCE_HOST}" ]; then
	SOURCE_TREE="${SOURCE_DIR}"
else
	SOURCE_TREE="${SOURCE_HOST}:${SOURCE_DIR}"
fi

if [ x"${LOCAL_HOST}" = x"${DEST_HOST}" ]; then
	DEST_TREE="${DEST_DIR}"
	if [ -d ${DEST_TREE} ]; then
		mkdir -p ${DEST_TREE}
	fi
else
	DEST_TREE="${DEST_HOST}:${DEST_DIR}"
	#---------------------------------------------------------------
	# Assuming you have permission to create the dir on the dest host 
	#---------------------------------------------------------------
	echo "checking ${DEST_TREE}"
	echo "creat it if not exist"
	ssh ${DEST_HOST} "if [ ! -d ${DEST_DIR} ]; then mkdir -p ${DEST_DIR}; fi"

fi

#---------------------------------------------------------------------------

if [ ! x"${LOCAL_HOST}" = x"${SOURCE_HOST}" \
	-a ! x"${LOCAL_HOST}" = x"${DEST_HOST}" ]; then

	echo "**************************************************************************"
	echo "I can not copy files from $SOURCE_HOST to $DEST_HOST thru a third host $LOCAL_HOST."
	echo "**************************************************************************"
	echo ""
	exit
fi


#---------------------------------------------------------------------------

echo "Copying tree ${SOURCE_TREE} to ${DEST_TREE} ..."

$SCP -r ${SOURCE_TREE} ${DEST_TREE}

#---------------------------------------------------------------------------
