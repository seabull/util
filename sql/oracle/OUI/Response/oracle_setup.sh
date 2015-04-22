#!/bin/sh
# initial oracle setup
# this happens only if user oracle does not exist

#--------------------------------------------------------------
# set up some pre-requisites for running OUI. --yangl
#--------------------------------------------------------------
INVPTR=/etc/oracle/oraInst.loc
INVLOC=/etc/oracle/oraInventory
#Group name for Inventory related directories
GRP=oradba
PTRDIR="`dirname $INVPTR`";

# TODO: make the release configurable instead of hardcode. --yangl
ORACLE_BASE=/usr/tmp/oracle
ORACLE_HOME=${ORACLE_BASE}/product/10.1
#group name for Oracle products tree
ORA_GRP=${GRP}
ORA_OWNER=oracle

set -e

#--------------------------------------------------------------
# Adding user oracle and group oradba.
#
# group name can be specified in the response file of OUI
# --yangl
#--------------------------------------------------------------
if grep '^oradba:' /etc/group ; then : ; else
  echo "Adding ${GRP} group to /etc/group"
  cp /etc/group /etc/group.new
  echo "${GRP}::397:oracle" >> /etc/group.new
  mv /etc/group.new /etc/group
fi

if grep '^oracle:' /etc/passwd ; then : ; else
  echo 'Adding oracle user to /etc/passwd'
  grp_id=`grep '^oradba:' /etc/group | cut -d: -f3`
  cp /etc/passwd /etc/passwd.new
  echo "oracle:x:7532:${grp_id}:Oracle Database Software:/usr/oracle:/usr/local/bin/tcsh" >> /etc/passwd.new
  mv /etc/passwd.new /etc/passwd
fi

#--------------------------------------------------------------
# Oracle Universal Installer (OUI) looks for file oraInst.loc ($INVPTR)
# in /etc/ for Linux.
#--------------------------------------------------------------
# The following section is similiar to orainstRoot.sh from Oracle, which
# has to be run during a normal installation.
# --yangl
# Create the software inventory location pointer file
if [ ! -d "$PTRDIR" ]; then
 mkdir -p $PTRDIR;
fi

if [ ! -f ${INVPTR} ] ; then
  echo "Creating the Oracle inventory pointer file ($INVPTR)";
  echo    inventory_loc=${INVLOC} > $INVPTR
  echo    inst_group=$GRP >> $INVPTR
fi

chmod 644 ${INVPTR}

# Create the inventory directory if it doesn't exist
if [ ! -d "${INVLOC}" ];then
 echo "Creating the Oracle inventory directory ($INVLOC)";
 mkdir -p $INVLOC;
 chmod 775 $INVLOC;
fi

echo "Changing groupname of $INVLOC to ${GRP}.";
chgrp users $INVLOC;

if [ $? != 0 ]; then
  echo "WARNING: chgrp of $INVLOC to $GRP failed!";
fi

#--------------------------------------------------------------
# Check Oracle Home Directory
#--------------------------------------------------------------
if [ ! -d "${ORACLE_BASE}" ];then
 echo "Creating the Oracle base directory ($ORACLE_BASE)";
 mkdir -p $ORACLE_BASE;
fi
chown ${ORA_OWNER}:${ORA_GRP} $ORACLE_BASE
#chmod 755 $ORACLE_BASE

#if [ ! -f /etc/httpd/httpd.conf ] ; then
  #echo 'Installing example httpd.conf'
  #cp /etc/httpd/httpd.conf.example /etc/httpd/httpd.conf
#
  #if [ ! -d /usr/wwwsrv ] ; then
    #if [ ! -d /usr0/wwwsrv ] ; then
      #echo 'Creating /usr0/wwwsrv'
      #mkdir /usr0/wwwsrv /usr0/wwwsrv/cgi-bin /usr0/wwwsrv/htdocs
    #fi
    #echo 'Linking /usr/wwwsrv to /usr0/wwwsrv'
    #ln -s /usr0/wwwsrv /usr/wwwsrv
  #fi
#fi

