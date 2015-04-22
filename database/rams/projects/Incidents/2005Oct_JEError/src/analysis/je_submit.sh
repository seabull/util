#!/bin/sh

e=1

prog=`basename $0 .sh` 
export prog

trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$* ${RMTMP}; trap 0; exit $e' 0

X_SCP=/usr/local/bin/scp

src="${1?}"
body="${2?}"
#to="${3?}"
#cc="${4?}"
TO="costing+fyi@cs.cmu.edu"
CC="rburatti+@andrew.cmu.edu"

which=`head -1 <$src | awk '{print $4;}'`

echo "[ Submitting ADJUST batch $which ]"

cp $src $which  \
&& \
${X_SCP} -v -i /usr/costing/fmp-up  $src  transfer@mistral.as.cmu.edu:${which}

if [ $? = "0" ]
then
    cat $body | /usr/bin/mailx -s "NOTICE - SCS Adjustment feeder batch $which submitted" -c $TO $CC
        mv $which /usr/costing/adjustments/feeder_files_old/$which
        mv $body /usr/costing/adjustments/feeder_files_old/${which}_${body}
        mv $src /usr/costing/adjustments/feeder_files_old/${which}_${src}
else
  echo "Feeder file $which transfer failed!" | /usr/bin/mailx -s "Feeder file $which transfer failed!" yangl+@cs.c
mu.edu
fi

e=$?
