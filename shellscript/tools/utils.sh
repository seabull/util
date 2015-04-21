#!/bin/sh

#---------------------------------------------------------
#$Header: c:\\Repository/shellscript/tools/utils.sh,v 1.2 2004/07/14 15:49:44 yangl Exp $
#---------------------------------------------------------

tolower() {
     #
     # NAME
     #    tolower - downshift the characters in a string
     #
     # SYNOPSIS
     #    tolower string
     #
     # DESCRIPTION
     #    This function will downshift the alphabetic
     #    characters in the string.  Nonalphabetic
     #    characters will not be affected.  The downshifted
     #    string will be written to the standard output.
     #    

     echo "$@" | tr '[A-Z]' '[a-z]'
}

#---------------------------------------------------------
CheckHostname() {
     #
     # NAME
     #    CheckHostname - determine if a host name is valid
     #
     # SYNOPSIS
     #    CheckHostname [hostname]
     #
     # DESCRIPTION
     #    This function will return true (0) if the host
     #    name is valid; otherwise, it will return
     #    false (1).  If the host name is omitted, the
     #    current host is checked.
     #
     _PING=                   # Customized ping command
     _HOST=${1:-`hostname`}   # Name of the host to check

     case `uname -s` in
          OSF1 )    _PING="ping -c1 $_HOST"  ;; # DEC OSF
          HP-UX )   _PING="ping $_HOST 64 1" ;;
          IRIX )    _PING="ping -c1 $_HOST"  ;; # SGI
          SunOS )   _PING="ping $_HOST"      ;; # BSD and
                                                # Solaris
          * )       return 1                 ;;
     esac

     if [ `$_PING 2>&1 | grep -ci "Unknown host"` -eq 0 ]
     then
          return 0
     else
          return 1
     fi
}

#---------------------------------------------------------
FullName() {
     #
     # NAME
     #    FullName - return full name of a file or directory
     #
     # SYNOPSIS
     #    FullName filename | directory
     #
     # DESCRIPTION
     #    This function will return the full name of the
     #    file or directory (the full name begins at the
     #    root directory).  The full name will be written
     #    to the standard output.  If the file or directory
     #    does not exist, the name will be returned
     #    unchanged.
     #    
     _CWD=`pwd`          # Save the current directory

     if [ $# -ne 1 ]; then
          echo "Usage: FullName filename | directory" 1>&2
          exit 1
     fi

     if [ -d $1 ]; then
          cd $1
          echo `pwd`
     elif [ -f $1 ]; then
          cd `dirname $1`
          echo `pwd`/`basename $1`
     else
          echo $1
     fi

     cd $_CWD
}

#---------------------------------------------------------
GetYesNo() {
     #
     # NAME
     #    GetYesNo - ask a yes or no question
     #
     # SYNOPSIS
     #    GetYesNo "message"
     #
     # DESCRIPTION
     #    This function will prompt the user with the
     #    message and wait for the user to answer "yes" or
     #    "no".  This function will return true (0) if the
     #    user answers yes; otherwise, it will return
     #    false (1).
     #
     #    This function will accept y, yes, n, or no, and it
     #    is reasonably tolerant of upper and lower case
     #    letters; any other answer will cause the question
     #    to be repeated.
     #
     _ANSWER=            # Answer read from user

     if [ $# -eq 0 ]; then
          echo "Usage: GetYesNo message" 1>&2
          exit 1
     fi

     while :
     do
          if [ "`echo -n`" = "-n" ]; then
               echo "$@\c"
          else
               echo -n "$@"
          fi
          read _ANSWER
          case "$_ANSWER" in
               [yY] | yes | YES | Yes ) return 0       ;;
               [nN] | no  | NO  | No  ) return 1       ;;
               * ) echo "Please enter y or n."         ;;
          esac
     done
}

#---------------------------------------------------------
IsNumeric() {
     #
     # NAME
     #    IsNumeric - determine if a string is numeric
     #
     # SYNOPSIS
     #    IsNumeric string
     #
     # DESCRIPTION
     #    This function will return true (0) if the string
     #    contains all numeric characters; otherwise, it
     #    will return false (1).
     #    
     if [ $# -ne 1 ]; then
          return 1
     fi

     expr "$1" + 1 >/dev/null 2>&1
     if [ $? -ge 2 ]; then
          return 1
     fi

     return 0
}

#---------------------------------------------------------
IsNewer() {
     #
     # NAME
     #    IsNewer - compare the dates of two files
     #
     # SYNOPSIS
     #    IsNewer file1 file2
     #
     # DESCRIPTION
     #    This function will return true (0) if file1 has
     #    been modified more recently that file2; otherwise,
     #    it will return false (1).
     #    
     if [ $# -ne 2 ]; then
          echo "Usage: IsNewer file1 file2" 1>&2
          exit 1
     fi

     if [ ! -f $1 -o ! -f $2 ]; then
          return 1       # No
     fi

     if [ -n "`find $1 -newer $2 -print`" ]; then
          return 0       # Yes
     else
          return 1       # No
     fi
}

#---------------------------------------------------------
IsSystemType() {
     #
     # NAME
     #    IsSystemType - compare string with current system
     #
     # SYNOPSIS
     #    IsSystemType string
     #
     # DESCRIPTION
     #    This function will return true (0) if the string
     #    matches one of the values returned by the uname
     #    command; otherwise, it will return false (1).
     #
     if [ $# -ne 1 ]; then
          echo "Usage: IsSystemType string" 1>&2
          exit 1
     fi

     if [ "$1" = "`uname -s`" ]; then
          return 0
     elif [ "$1" = "`uname -m`" ]; then
          return 0
     else
          case `uname -r` in
               "$1"* ) return 0 ;;
          esac
     fi
     return 1
}

#---------------------------------------------------------
Prompt() {
     #
     # NAME
     #    Prompt - print a message without a newline
     #
     # SYNOPSIS
     #    Prompt [message]
     #
     # DESCRIPTION
     #    This function prints the message to the standard
     #    output without a newline at the end of the line.
     #
     #    If the message is not passed, "> " will be
     #    printed.
     #
     if [ "`echo -n`" = "-n" ]; then
          echo "${@-> }\c"
     else
          echo -n "${@-> }"
     fi
}

#---------------------------------------------------------
Question() {
     #
     # NAME
     #    Question - ask a question
     #
     # SYNOPSIS
     #    Question question default helpmessage
     #
     # DESCRIPTION
     #    This function will print a question and return the
     #    answer entered by the user in the global variable
     #    ANSWER.  The question will be printed to the
     #    standard output.  If a default answer is supplied,
     #    it will be enclosed in square brackets and
     #    appended to the question.  The question will then
     #    be followed with a question mark and printed
     #    without a newline.
     #
     #    The default answer and the help message may be
     #    omitted, but an empty parameter (i.e., "") must
     #    be passed in their place.
     #
     #    The user may press enter without entering an
     #    answer to accept the default answer.
     #
     #    The user may enter "quit" or "q" to exit the
     #    command file.  This answer is not case sensitive.
     #
     #    The user may enter a question mark to receive a
     #    help message if one is available.  After the help
     #    message is printed, the question will be printed
     #    again.
     #
     #    The user may enter !command to cause the UNIX
     #    command to be executed.  After the command is
     #    executed, the question will be repeated.
     #
     #    The answers -x and +x cause the debugging option
     #    in the shell to be turned on and off respectively.
     #
     #    For "yes and no" questions, "yes", "y", "no", or,
     #    "n" can be entered.  This response is not case
     #    sensitive.
     #
     #    The answer will be returned exactly as the user
     #    entered it except "yes" or "no" will be returned
     #    for yes or no questions, and the default answer
     #    will be returned if the user enters a return.
     #    
     if [ $# -lt 3 ]; then
          echo "Usage: Question question" \
               "default helpmessage" 1>&2
          exit 1
     fi
     ANSWER=             # Global variable for answer
     _DEFAULT=$2         # Default answer
     _QUESTION=          # Question as it will be printed
     _HELPMSG=$3         # Text of the help message

     if [ "$_DEFAULT" = "" ]; then
          _QUESTION="$1? "
     else
          _QUESTION="$1 [$_DEFAULT]? "
     fi

     while :
     do
          if [ "`echo -n" = "-n" ]; then
               echo "$_QUESTION\c"
          else
               echo -n "$_QUESTION"
          fi
          read ANSWER
          case `echo "$ANSWER" | tr [A-Z] [a-z]` in
               "" ) if [ "$_DEFAULT" != "" ]; then
                         ANSWER=$_DEFAULT
                         break
                    fi
                    ;;

               yes | y )
                    ANSWER=yes
                    break
                    ;;

               no | n )
                    ANSWER=no
                    break
                    ;;

               quit | q )
                    exit 1
                    ;;

               +x | -x )
                    set $ANSWER
                    ;;

               !* ) eval `expr "$ANSWER" : "!\(.*\)"`
                    ;;

               "?" )echo ""
                    if [ "$_HELPMSG" = "" ]; then
                         echo "No help available."
                    else
                         echo "$_HELPMSG"
                    fi
                    echo ""
                    ;;

               * )  break
                    ;;
          esac
     done
}

#---------------------------------------------------------
StrCmp() {
     #
     # NAME
     #    StrCmp - compare two strings
     #
     # SYNOPSIS
     #    StrCmp string1 string2
     #
     # DESCRIPTION
     #    This function returns -1, 0, or 1 to indicate
     #    whether string1 is lexicographically less than,
     #    equal to, or greater than string2.  The return
     #    value is written to the standard output, not the
     #    exit status.
     #
     if [ $# -ne 2 ]; then
          echo "Usage: StrCmp string1 string2" 1>&2
          exit 1
     fi
     
     if [ "$1" = "$2" ]; then
          echo "0"
     else
          _TMP=`{ echo "$1"; echo "$2"; }|sort|sed -n '1p'`

          if [ "$_TMP" = "$1" ]; then
               echo "-1"
          else
               echo "1"
          fi
     fi
}

#---------------------------------------------------------
decimal2hex() {
    echo 16o $1 p | dc
}

#---------------------------------------------------------
hex2decimal() {
    NUM=`echo $1 | tr '[a-f]' '[A-F]'`
    echo 16i $NUM p | dc
}
#---------------------------------------------------------


