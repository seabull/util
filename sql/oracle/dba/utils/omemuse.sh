#!/usr/bin/sh
#$Id: omemuse.sh,v 1.1 2005/09/06 14:21:25 yangl Exp $
# Solaris 8
# based on codes from Oracle
#

usage()
{
	echo "Usage: $0 [ SB ]"
	echo "Usage: $0 [ P <pid> ]"
	echo "Usage: $0 [ h ]"
	echo " "
	echo "specify 'S' for Oracle shadow processes"
	echo "specify 'B' for Oracle background processes (includes shared memory SGA)"
	echo "specify 'h' for help"
	echo " "
}

echo " "

#
# check usage
#
if [ $# = "0" ];then
	usage;exit 1
fi

Parm1=$1

if [ $Parm1 = "h" ];then
	echo "This script uses the Sun Solaris pmap command to determine memory usage"
	echo "for Oracle server [B]ackground processes and/or [S]hadow processes."
	echo "An individual [P]rocess can also be specified."
	echo " "
	echo "Although the Oracle server background processes memory usage should"
	echo "remain fairly constant, the memory used by any given shadow process"
	echo "can vary greatly.  This script shows only a snapshot of the current"
	echo "memory usage for the processes specified."
	echo " "
	echo "The 'B' option shows the sum of memory usage for all Oracle server"
	echo "background processes, including shared memory like the SGA."
	echo " "
	echo "The 'S' option shows the sum of private memory usage by all"
	echo "shadow processes.  It does not include any shared memory like the"
	echo "SGA since these are part of the Oracle server background processes."
	echo " "
	echo "The 'P' option shows memory usage for a specified process, broken"
	echo "into two categories, private and shared.  If the same executable"
	echo "for this process was invoked again, only the private memory"
	echo "would be allocated, the rest is shared with the currently running"
	echo "process."
	echo " "
	usage;exit 1
fi

echo $Parm1 | grep '[SBP]' > /dev/null

ParmFound=$?

if [ $ParmFound != "0" ];then
	usage
	exit 1
fi

echo $Parm1|grep P > /dev/null
ParmFound=$?

if [ $ParmFound = "0" ];then
	if [ $Parm1 != "P" ];then
		usage;exit 1
	fi
	if [ "X$2" = "X" ];then
		usage;exit 1
	fi
	Parm2=$2
	echo $Parm2|grep '[^0-9]' > /dev/null
	ParmFound=$?
	if [ $ParmFound = "0" ];then
		usage;exit 1
	fi
	PidOwner=`ps -ef | grep -v grep | grep $Parm2 | grep -v $0 | awk '{print $1}'`
	CurOwner=`/usr/xpg4/bin/id -un`
	if [ "X$PidOwner" != "X$CurOwner" ];then
		echo "Not owner of pid $Parm2, or pid $Parm2 does not exist"
		echo " "
		usage;exit 1
	fi
else
	if [ "X${ORACLE_SID}" = "X" ];then
		echo "You must set ORACLE_SID first"
		usage;exit1
	fi
fi

#
# initialize variables
#
Pmap="/usr/proc/bin/pmap"
SharUse="/tmp/omemuseS$$"
PrivUse="/tmp/omemuseP$$"
ShadUse="/tmp/omemuseD$$"
PidPUse="/tmp/omemusePP$$"
PidSUse="/tmp/omemusePS$$"
TotalShad=0
TotalShar=0
TotalPriv=0
PidPriv=0
PidShar=0

#
# shadow processes
#
echo $Parm1|grep S > /dev/null
ParmFound=$?
if [ $ParmFound = "0" ];then
	ShadPrc="`ps -ef|grep -v grep|grep oracle$ORACLE_SID|awk '{print $2}'`"
	echo "" > $ShadUse
	for i in $ShadPrc;do
		$Pmap $i | grep "read/write" | grep -v shared | \
			awk '{print $2}' | awk -FK '{print $1}' >> $ShadUse
	done
	for i in `cat $ShadUse`;do
		TotalShad=`expr $TotalShad + $i`
	done
	TotalShad=`expr $TotalShad "*" 1024`
	echo "Total Shadow  (bytes) :	$TotalShad"
	/bin/rm $ShadUse
fi

#
# non-shared portion of background processes
#
echo $Parm1|grep B > /dev/null
ParmFound=$?
if [ $ParmFound = "0" ];then
	OrclPrc="`ps -ef|grep -v grep|grep ora_|grep $ORACLE_SID|awk '{print $2}'`"
	BkgdPrc="`echo $OrclPrc|awk '{print $1}'`"
	echo "" > $PrivUse
	for i in $OrclPrc;do
		$Pmap $i | grep "read/write" | grep -v shared | \
	    awk '{print $2}' | awk -FK '{print $1}' >> $PrivUse
	done
	for i in `cat $PrivUse`;do
		TotalPriv=`expr $TotalPriv + $i`
	done
	TotalPriv=`expr $TotalPriv "*" 1024`
	echo "Total Private (bytes) :	$TotalPriv"

	#
	# shared portion of background processes
	#
	echo "" > $SharUse
	$Pmap $BkgdPrc | grep "read/exec" | \
		awk '{print $2}' | awk -FK '{print $1}' >> $SharUse
	$Pmap $BkgdPrc | grep "shared" | \
		awk '{print $2}' | awk -FK '{print $1}' >> $SharUse
	for i in `cat $SharUse`;do
	  TotalShar=`expr $TotalShar + $i`
	done
	TotalShar=`expr $TotalShar "*" 1024`
	echo "Total Shared  (bytes) :	$TotalShar"
	/bin/rm $SharUse $PrivUse
fi

#
# non-shared portion of pid
#
echo $Parm1|grep P > /dev/null
ParmFound=$?
if [ $ParmFound = "0" ];then
	echo "" > $PidPUse
	$Pmap $Parm2 | grep "read/write" | grep -v shared | \
		awk '{print $2}' | awk -FK '{print $1}' >> $PidPUse
	for i in `cat $PidPUse`;do
		PidPriv=`expr $PidPriv + $i`
	done
	PidPriv=`expr $PidPriv "*" 1024`
	echo "Total Private (bytes) :	$PidPriv"

	#
	# shared portion of pid
	#
	echo "" > $PidSUse
	$Pmap $Parm2 | grep "read/exec" | awk '{print $2}' | \
		awk -FK '{print $1}' >> $PidSUse
	$Pmap $Parm2 | grep "shared" | awk '{print $2}' | \
		awk -FK '{print $1}' >> $PidSUse
	for i in `cat $PidSUse`;do
		PidShar=`expr $PidShar + $i`
	done
	PidShar=`expr $PidShar "*" 1024`
	echo "Total Shared  (bytes) :	$PidShar"
	/bin/rm $PidPUse $PidSUse
fi

#
# Display grand total
#
Gtotal="`expr $TotalShad + $TotalPriv + $TotalShar + $PidPriv + $PidShar`"
echo "			-----"
echo "Grand Total   (bytes) :	$Gtotal"
echo " "

