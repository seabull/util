#!/bin/csh -f
#------------------------------------------------------------------------------

if ( "$1" != "-a" ) then

svrmgrl <<--Done--
--
  connect internal
--
  shutdown abort
--
--Done--

else

svrmgrl <<--Done--
--
  connect internal
--
  shutdown immediate
--
--Done--

endif

  exit $status

#------------------------------------------------------------------------------
