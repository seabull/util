#!/bin/ksh
#------------------------------------------------------------------------------
#$Header: c:\\Repository/shellscript/script_base.ksh,v 1.1 2005/02/08 21:51:56 yangl Exp $
#------------------------------------------------------------------------------

program=`basename $0 .sh`
TMPFILE="/tmp/${program}.$$.tmp"
CLEANUP="$TMPFILE*"

exit_code=1

trap 'exit_code=$?; exit' HUP INT TERM

trap ' rm -f $CLEANUP ; trap 0 ; exit $exit_code ' EXIT

#------------------------------------------------------------------------

usage() {
  sub() {
    if [ "x$2" != "x" ] ; then
      echo "${program}:  $2\n"
    fi
    cat <<EOF_USAGE
Usage: ${program} <options> [ <makefile-target> ... ]

Description:

        Run a RAMS makfile target(s) and optionally submit a journal entry.

Options:
        The options are optional.
        -j <journal_submit_option>
                <journal_submit_option> can be either of the values below.
                submit          Submit the Journal Entry to campus.
                nosubmit        Explicitly turn off submission of the Journal Entry to campus.
                                (This would only be used if the config file was setting it to true.)
        -c <config-file>   Use this configuration file.

        The following options are optional.
        -h                 Display this help information and quit.
        -v                 Provided verbose output.

Arguments:
        <makefile-target>  One or more makefile targets.

EOF_USAGE
t $1
  }

  exit_code=$1
  shift

  sub $exit_code "$@" 1>&2
}

#--------------------------------------------------------------------------

SUMBIT=false

while getopts :vhc:j: OPT ; do
        case $OPT in
        j)      case "$OPTARG" in
                        submit)
                                SUBMIT=true ;
                                ;;
                        nosubmit)
                                SUBMIT=true ;
                                ;;
                        *)      usage 1 "option '-$OPT' - invalid argument '$OPTARG'."
                                ;;
                esac
                ;;
#
        c)      RAMS_CONFIG_FILE="$OPTARG"
                if [ ! -f "$RAMS_CONFIG_FILE" ] ; then
                        usage 1 "configuration file '$RAMS_CONFIG_FILE' does not exist or is not a plain 
file."
                fi
                if [ ! -r "$RAMS_CONFIG_FILE" ] ; then
                        usage 1 "configuration file '$RAMS_CONFIG_FILE' is not accessible."
                fi
                ;;
#
        h)      usage 0
                ;;
#
        v)      VERBOSE=TRUE
                ;;
#
        :)      usage 1 "option '-$OPTARG' - must be followed by an argument."
                ;;
#
        \?)     usage 1 "Invalid option '$OPT'"
                ;;
#
        esac
done
shift `expr $OPTIND - 1`

#------------------------------------------------------------------------------

