#!/usr/bin/ksh
#$Id#
#-------------------------------------------------------
# Generate random strings to use as password for Oracle
# user.
#-------------------------------------------------------

SID=$1
echo $SID
export ORACLE_SID=${SID}

echo "userid (password will be generated)"
read userid
set -A M 0 1 2 3 4 5 6 7 8 9 \
A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
a b c d e f g h i j k l m n o p q r s t u v w x y z \
@ \& \# \$ \*
L="10"

while [ 1 ]; do
password=""
L=10
while [ $L -gt 0 ] 
do
	password="$password${M[$(($RANDOM%${#M[*]}+1))]}"
	L="$(($L-1))"
done
echo "userid ${userid}"
echo "newpassword: $password"
read nothing
done

if [ -z "${userid}" ] || [ -z "${password}" ] ; then
	echo "wrong number of items entered. Press to quit."
	read nothing
	exit
fi

### DOES USER ALREADY EXIST? IF SO, EXIT ###

check_the_user()
{
	sqlplus -s <internal
	set pages 0 lines 150 head off veri off feed off term off echo off
	select count(*) from dba_users where username = upper('${userid}');
	END
}

if [[ `check_the_user` -gt 0 ]] ; then
	echo "ERROR -- user ${userid} already exists - to exit."
	read nothing
	exit
fi

echo "userid ${userid}"
echo "newpassword: $password"

if [ -z "${userid}" ] || [ -z "${password}" ] ; then
	echo "wrong number of items entered. Press to quit."
	read nothing
	exit
fi

echo " is this correct (y/n)?"
yesno="n"
read yesno
if [ -z "${yesno}" ] || [ ${yesno} != "Y" ] && [ ${yesno} != "y" ] ; then
	exit
fi

sqlplus -s <internal
set pages 0 lines 150 head off veri off feed off term off echo off

create user ${userid}
	identified by "$password"
	default tablespace data01
	temporary tablespace temp
	QUOTA UNLIMITED ON DATA01
	QUOTA 0 ON SYSTEM ;
exit
ENDSQL

#GRANT SSE_ROLE TO ${userid} ;

echo "All done. Press to continue."
read nothing

exit
