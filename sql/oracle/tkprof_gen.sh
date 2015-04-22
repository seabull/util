#!/bin/ksh
#/***********************************************************
#* $Header:
#* Name:        tkprof_rpt
#* Description: Prompt for tkprof parameters and run tkprof.
#*
#* Inputs:      Trace filename. (Std. udump directory is assumed)
#*              Output filename.
#*              Oracle userid.
#*              Oracle password.
#*
#* Outputs:     tkprof output in current dir., or home dir.
#*
#* Known limitations:
#*
#* Revisions:
#* Date         who                Description
#* 1/10/96      rkupcunas        Created
#************************************************************/

echo "\n\n"

udump=/u00/home/admin/oracle/FSPRD/udump

ls -lt $udump | head

echo "\n\nEnter the name of the trace file ................ \c"
read ans
if [ ! -r $udump/$ans ]
then
        echo "You must enter a full file name which you have read permissions"
        echo "from the directroy: $udump"
        exit 1
fi
trcfile=$ans

echo "Enter the name of the output (formatted) file ... \c"
read out

echo "\nEnter the output file directory. Otherwise it will go in your "
echo "current directory: \c"
read dir

if [ "$dir" = "" ]
then
        outfile=$out
else
        outfile=$dir/$out
fi


echo "\nEnter your Oracle userid: \c"
read userid
echo "Enter your Oracle password: \c"
stty -echo
read passwd
stty echo

$ORACLE_HOME/bin/tkprof $udump/$trcfile $outfile sort=FCHQRY explain=${userid}/${passwd}
