#!/bin/sh

set -x

#ACIS_EMAIL="root@as.cmu.edu"
ACIS_EMAIL="yangl+@cs.cmu.edu"
SCS_CONTACT="yangl+@cs.cmu.edu"

KEYFILE=${1:?"Key file expected"}

SUBJECT="Key file - Test "

( echo "This key file should go into production environment. ";	\
  echo "This is the key file intended to be put into production.";	\
  echo "Please contact ${SCS_CONTACT} if have any questions.";	\
  echo "This is the public key for SCS Feeders.";	\
	cat ${KEYFILE}.pub 	\
) 	\
| mailx -s "$SUBJECT" $ACIS_EMAIL
