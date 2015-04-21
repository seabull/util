#!/bin/sh

e=1
#-----------------------------------------------------------------------------
#set -x

# catch 0, SIGHUP(1), SIGINT(2), SIGTERM(15)
trap 'e=$?; exit' 1 2 15
trap 'rm -f /tmp/${prog}$$T*; trap 0; exit $e' 0

prog=`basename $0 .sh`
T="/tmp/${prog}$$T"

#TT="/tmp/${prog}$$TT"
#cmd ${@+"$@"}
#-----------------------------------------------------------------------------
usage()
{
	echo $2
	cat << EOF_USAGE
Usage: ${prog} [options] <object name>
Options:
	-c<connection string>	Connection String used to connect to Oracle
	-v			verbose.
	-h			help

	You can specify only one of the following options. They are mutually exclusive. If more than one
	are specified, only the first will be used.
	-b			package body
	-s			package specification
	-p			procedure
	-f			function
	-t			trigger
EOF_USAGE
	exit $1
}
#------------------------------------------------------------------------------
CONN=/
VERBOSE=
SQLPLUS=sqlplus
SQLPLUSOPT=-s
TYPE=
OBJECT_NAME=
CMD_PREFIX=

# packages
# procedures
#functions
#triggers
#------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
	usage 1 "Empty argument list" 1>&2
fi

# The first option take precedence, i.e. only the first option is used
if [ "$OPTIND" = 1 ]; then
	while getopts c:sbpftvh OPT
	do
		case $OPT in
		b)	
			TYPE=${TYPE:-"PACKAGE BODY"}		# : consider empty variable as undefined
			;;
		c)	CONN=$OPTARG
			;;
		f)	
			TYPE=${TYPE:-"FUNCTION"}		# : consider empty variable as undefined
			;;
		p)	
			TYPE=${TYPE:-"PROCEDURE"}		# : consider empty variable as undefined
			;;
		s)	
			TYPE=${TYPE:-"PACKAGE"}		# : consider empty variable as undefined
			;;
		t)	
			TYPE=${TYPE:-"TRIGGER"}		# : consider empty variable as undefined
			;;
		v)	VERBOSE=TRUE
			;;
		h)	usage 1 "----------" 1>&2
			;;
		\?)	usage 1 "Wrong arguments." 1>&2
			;;
		esac
	done
	shift `expr $OPTIND - 1`
else
	while [ $# -gt 0 ]; do
		case "$1" in 
		-b)
			TYPE=${TYPE:-"PACKAGE BODY"}		# : consider empty variable as undefined
			shift
			;;
		-c)
			CONN=$2
			shift 2
			;;
		-c*)
			CONN=`echo "$1" | sed 's/^..//'`
			shift
			;;
		-f)
			TYPE=${TYPE:-"FUNCTION"}		# : consider empty variable as undefined
			shift
			;;
		-p)
			TYPE=${TYPE:-"PROCEDURE"}		# : consider empty variable as undefined
			shift
			;;
		-s)
			TYPE=${TYPE:-"PACKAGE"}		# : consider empty variable as undefined
			shift
			;;
		-t)
			TYPE=${TYPE:-"TRIGGER"}		# : consider empty variable as undefined
			shift
			;;
		-v)	VERBOSE=TRUE
			shift
			;;
		-h)
			usage 0 "------------" 1>&2
			;;
		-*)	usage 1 "Not supported option $1" 1>&2
			;;
		*)
			break
			;;
		esac
	done
fi

if [ $# -lt 1 ]; then
	usage 1 "Empty argument." 1>&2
fi

if [ $# -gt 1 ]; then
	usage 1 "Single object expected." 1>&2
fi
#------------------------------------------------------------------------------
#NAME=`echo $1 | tr "[:lower:]" "[:upper:]"`
NAME=`echo $1 | tr "[a-z]" "[A-Z]"`
TYPE=${TYPE:-"PACKAGE BODY"}		#default type is package body.

if [ x"${VERBOSE}" = "xTRUE" ]; then
	echo "${prog} ${TYPE} ${NAME}"
fi

#------------------------------------------------------------------------------
#cat << _SQL_DONE_

${CMD_PREFIX} ${SQLPLUS} ${SQLPLUSOPT} $CONN <<_SQL_DONE_ | tr -d '\014'
--
SET SERVEROUTPUT ON SIZE 100000 FEEDBACK OFF LINESIZE 300 ;
--
DECLARE
	cursor csr_object ( obj_name VARCHAR2, obj_type VARCHAR2 ) IS
		SELECT	Distinct(us.Name)
		FROM	all_source us
		WHERE	us.name like obj_name
		AND	us.type = obj_type
		ORDER BY 1 
		;
	obj_name	VARCHAR2(30);
	cursor csr_source ( obj_name VARCHAR2, obj_type VARCHAR2 ) IS
		SELECT   us.line
			, us.text
		FROM	all_Source us
		WHERE	us.name = obj_name 
		AND	us.type = obj_type
		ORDER BY 1
		;
	source	csr_source%ROWTYPE;
  --
--
  BEGIN

    OPEN csr_object( '$NAME', '$TYPE' );
    FETCH csr_object into obj_name ;

    IF ( csr_object%NOTFOUND ) THEN
      DBMS_OUTPUT.PUT_LINE('* no objects found matching "$NAME"') ;
      GOTO done ;
    END IF ;

    DBMS_OUTPUT.PUT_LINE('--') ;

    WHILE ( NOT csr_object%NOTFOUND )
    LOOP

      OPEN csr_source ( obj_name, '$TYPE' ) ;

      FETCH csr_source INTO source ;

      IF ( csr_Source%NOTFOUND ) THEN
        DBMS_OUTPUT.PUT_LINE('* no source lines found matching "'||obj_name||'"') ;
        GOTO done ;
      END IF ;

      WHILE ( NOT csr_source%NOTFOUND )
      LOOP
        IF ( substr(source.text,length(source.text),1) = CHR(10) ) THEN
          source.text := RTRIM(SUBSTR(source.text,1,LENGTH(source.text)-1)) ;
        END IF ;
        --DBMS_OUTPUT.PUT('.'||lpad(source.line,5,' ')||'  ') ;
        DBMS_OUTPUT.PUT(lpad(source.line,5,' ')||'  ') ;
        DBMS_OUTPUT.PUT_LINE(rtrim(source.text)) ;
        FETCH csr_source INTO source ;
      END LOOP ;

      CLOSE csr_source ;

      DBMS_OUTPUT.PUT_LINE('--') ;

      FETCH csr_object INTO obj_name ;

    END LOOP ;

  <<done>>

    CLOSE csr_object ;

  END ;
/
--
_SQL_DONE_

e=$?
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

  #if ( $?CXAPPS == 0 ) then
    #set connect = "/"
  #else
    #set connect = "$CXAPPS"
  #endif

#------------------------------------------------------------------------------
