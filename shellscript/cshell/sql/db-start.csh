#!/bin/csh -f
#------------------------------------------------------------------------------

if ( "$1" == "-r" ) then

svrmgrl <<--Done--
--
  connect internal
--
  startup nomount
--
  recover database ;
--
  alter database open ;
--
--
--Done--

else

svrmgrl <<--Done--
--
  connect internal
--
  startup
--
--Done--

endif

  exit $status

#------------------------------------------------------------------------------
