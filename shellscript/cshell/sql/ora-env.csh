#!/bin/csh -f
#------------------------------------------------------------------------------

  set tmp = /tmp/.ora-env.tmp.$$

  unset xshell		; unsetenv xshell

  while ( "$1" =~ -* )
    if ( "$1" == "-c" ) then
      if ( $?xshell != 0 ) then
        set msg = "Option '$1' - shell already specified - please specify only once."
        set 
      endif
      set xshell = .../csh
    endif
    if ( "$1" == "-s" ) then
      if ( $?xshell != 0 ) then
        set msg = "Option '$1' - shell already specified - please specify only once."
        set 
      endif
      set xshell = .../sh
    endif
    shift
  end

  if ( $#argv > 1 ) then
    set msg = "too many arguments - expected zero or one after options."
    goto usage
  endif

#------------------------------------------------------------------------------

  if ( $?xshell == 0 ) then
    if ( $?SHELL == 1 ) then
      set xshell = "$SHELL"
    else
      set xshell = .../sh
    endif
  endif

#------------------------------------------------------------------------------

  if ( $#argv == 0 ) then
    if ( $?TWO_TASK    != 0 ) goto use_two_task
    if ( $?ORACLE_SID  != 0 ) goto use_oracle_sid
    set msg = "<oracle-instance> not provided and neither TWO_TASK nor ORACLE_SID defined."
    goto usage
  else
    if ( "$1" == "" ) goto clear_ora_environment
    set instance = "$1"
    goto process_instance
  endif

#------------------------------------------------------------------------------

use_two_task:

  

#------------------------------------------------------------------------------

process_instance:

#------------------------------------------------------------------------------

# remove all ORACLE_HOMEs from the executable search path (PATH/path)

  ora-homes | awk '{ printf ( NR > 1 ? "|" : "" ) $2 "/.*" }' > $tmp

  set constraint = "` cat $tmp `"

  args $path | egrep -v "($constraint)" > $tmp

  set path = ( ` cat $tmp ` )

#------------------------------------------------------------------------------

# locate the instance's oracle 

  ora-home $ORACLE_SID > $tmp
  if ( $status == 0 ) then
    set oracle_home = "` cat $tmp `"
  endif

  if ( "$oracle_home" != "" ) then
    setenv ORACLE_HOME "$oracle_home"
    set path = ( $ORACLE_HOME/bin $path )
    unset oracle_home
  else
      echo "Warning:  '$ORACLE_SID' not found in oratab" | tee -a $warn
    endif
    rm -f $tmp
    source .cshrc


  set orx_sid   = ' echo $ORACLE_SID '
  set orx_user  = ' echo $CXAPPS '

  alias ora_sid   ' if ( $?ORACLE_SID ) eval "$orx_sid" | tr A-Z a-z '
  alias ora_user  ' if ( $?CXAPPS )	eval "$orx_user" | sed "s,/..*,,g" '
  alias ora_cx    ' set OraCx="< `ora_user` `ora_sid` >" '
  alias ora_home  ' setenv ORACLE_HOME `ora-home $ORACLE_SID` '
  alias ora_set   ' ora_cx ; ora_home ; cd . '

# alias app_set   ' set base=`pwd` ; cd ~ ; eval `.set-apps-env` ; cd $base '

  alias ora-cx    ' setenv CXAPPS \!:1		; ora_set '
  alias cx        ' ora-cx '
# alias ora       ' setenv ORACLE_SID \!:1	; ora_set ; app_set '
  alias ora       ' setenv ORACLE_SID \!:1	; ora_set '


  rm -f $tmp

  exit 0

#------------------------------------------------------------------------------

usage:

  e-echo ""
  e-echo "Error:  $msg"
  e-echo ""
  e-echo "Usage:  ora-env [ -s | -c ] [ <oracle-instance> ]"
  e-echo ""
  e-echo "- Generate commands to set one's environment for the Oracle instance specified.  Uses"
  e-echo '  $SHELL to determine whether to generate Bourne/Korn shell or C shell commands.'
  e-echo ""
  e-echo "- Uses tnsnames.ora or oratab to 
  e-echo ""
  e-echo "- Sets TWO_TASK or ORACLE_SID as appropriate."
  e-echo ""
  e-echo "- Adds $ORACLE_HOME/bin to one's path after clearing previous entries."
  e-echo ""
  e-echo "- If <oracle-instance> is not provided then TWO_TASK or ORACLE_SID will be used."
  e-echo ""
  e-echo "- Empty string for <oracle-instance> simply removes the Oracle environment variables."
  e-echo ""
  e-echo "Options:"
  e-echo ""
  e-echo "  -c    Generate C shell commands."
  e-echo ""
  e-echo "  -s    Generate Bourne/Korn shell commands."
  e-echo ""

  rm -f $tmp

  exit -1

#------------------------------------------------------------------------------
