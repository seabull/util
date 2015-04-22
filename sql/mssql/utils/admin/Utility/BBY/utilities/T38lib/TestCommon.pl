#!perl 

#------------------------------------------------------------------------------
# PVCS info
#
# $Archive:   //cs01pvcs/pvcs/cm/Database/archives/Applications/Utilities/T38lib/TestCommon.pv_  $
# $Author: A645276 $
# $Date: 2011/02/08 17:25:26 $ 
# $Revision: 1.1 $
#------------------------------------------------------------------------------

#
# Example to use function in T38lib::Common.pm
#

use T38lib::Common;

$line = "==========================================================================\n";

#goto ASIF;

print "$line";
print "Call \&T38lib::Common::chkPerlVer()\n";
print "No Input Argument\n";
print "Return 1 if we have new version of perl\n";
print "Else return perl version installed.\n";
print "Return values\n\n";
print &T38lib::Common::chkPerlVer() . "\n";

print "$line";

#----------------

print "Call \&T38lib::Common::findDependentService(MSSQLSERVER)\n";
print "Input Argument Service Name\n";
print "Return An array of dependent service names\n";
print "In case of an error return global variable $T38ERROR=__T38ERROR__\n";
print "if no dependent service(s) found return array[0]=zero\n";

print "\nReturn values\n";
@dep = &T38lib::Common::findDependentService(MSSQLSERVER); 

foreach (@dep) {
	print "$_\n";
}

print "$line";

#----------------

print "Call \&T38lib::Common::getDrives()\n";
print "Optional parameter can be\n";
print "ALL:	For all the drives\n";
print "CDR:	For all the CDROM drives\n";
print "FIX:	For all the fix drives\n";
print "RAM:	For All the RAM DISK drives\n";
print "REM:	For all removeable drives\n";
print "RMT:	For all the remote drives\n";
print "Return An array of all the drive letters\n";

print "\nReturn values\n";
@dep = &T38lib::Common::getDrives("ALL"); 

foreach (@dep) {
	print "$_\n";
}

print "$line";

#----------------

print "Call \&T38lib::Common::getDBNames()\n";
print "No Input Argument\n";
print "Return An array of all the database names\n";
print "In case of an error return global variable $T38ERROR=__T38ERROR__\n";

print "\nReturn values\n";
@dep = &T38lib::Common::getDBNames(); 

foreach (@dep) {
	print "$_\n";
}

print "$line";

#----------------

print "Call \&T38lib::Common::getEnvPathVar()\n";
print "No Input Argument\n";
print "Return the full path read from registry\n";
print "In case of an error return $T38ERROR=__T38ERROR__\n";

print "\nReturn values\n";
$path = &T38lib::Common::getEnvPathVar();
print "$path\n";

print "$line";

#----------------

print "Call \&T38lib::Common::getLogFileName($0)\n";
print "Input Argument program name\n";
print "Return file name with the log extension\n";

print "\nReturn values\n";
$logFileName = &T38lib::Common::getLogFileName($0);
print "$logFileName\n";

print "$line";

#----------------

print "Call \&T38lib::Common::getServiceStatus(MSSQLSERVER)\n";
print "Input Argument service name\n";
print "Return an array\n";
print "\t[0] = notfound or found or __T38ERROR__ in case of an error\n";
print "\tIf Found then\n";
print "\t[1] = Running or Stopped or Pause\n";

print "\nReturn values\n";
@dep = &T38lib::Common::getServiceStatus(MSSQLSERVER);

foreach (@dep) {
	print "$_\n";
}

print "$line";

#----------------

print "Call \&T38lib::Common::getSqlCurVer()\n";
print "optional input argument instance name\n";
print "Return a string with the following format\n";
print "SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion\n";
print "or 0 in case of an error.\n";

print "\nReturn values\n";
$path = &T38lib::Common::getSqlCurVer();
print "$path\n";

print "$line";

#----------------

print "Call \&T38lib::Common::getSqlCSDVer()\n";
print "optional input argument instance name\n";
print "No Input Argument\n";
print "Return a string with the following format\n";
print "SQLMajorVersion.SQLMinorVersion.SQLServicepackVersion\n";
print "or 0 in case of an error.\n";

print "\nReturn values\n";
$path = &T38lib::Common::getSqlCSDVer();
print "$path\n";

print "$line";

#----------------

print "Call \&T38lib::Common::globbing(*.pl)\n";
print "Input argument wild character *\n";
print "Expand command line argument and an array of the expanded \n";
print "command line arguments\n";
print "If globbing expand to nothing then return $T38ERROR=__T38ERROR__\n";

print "\nReturn values\n";
@dep = &T38lib::Common::globbing("*.pl");

foreach (@dep) {
	print "$_\n";
}

print "$line";

#----------------

print "Call \&T38lib::Common::logEvent('Info','Testing Common.pm')\n";
print "Input argument one Info, Warn or Error\n";
print "Input argument two message to dispay\n";
print "Optional Input argument three started or done\n";
print "1 for success 0 failer\n";

print "\nReturn values\n";
$res = &T38lib::Common::logEvent("Info", "Testing Common.pm");
print "$res\n";

print "$line";

#----------------

print "Call \&T38lib::Common::notifyMe('Testing Common.pm')\n";
print "Input argument message to dispay\n";
print "Write the message to programName.log file\n";

print "\nReturn values\n";
print "Check TestCommon.log file in the current directory for the results\n";
&T38lib::Common::notifyMe('Testing Common.pm');

print "$line";

#----------------

print "Call \&T38lib::Common::notifyWSub('Testing Common.pm')\n";
print "Input argument message to dispay\n";
print "optional argument subroutine level\n";

print "\nReturn values\n";
print "Check TestCommon.log file in the current directory for the results\n";
&T38lib::Common::notifyWSub('Testing Common.pm');

print "$line";

#----------------

print "Call \&T38lib::Common::logme('Testing Common.pm')\n";
print "Input argument message to dispay\n";
print "Optional argument eventcode values started or done\n";
print "Write to event log \n";

print "\nReturn values\n";
print "Check the application evnet log\n";
&T38lib::Common::logme("logme Testing Common.pm");

print "$line";

#----------------

print "Call \&T38lib::Common::warnme('Testing Common.pm')\n";
print "Input argument message to dispay\n";
print "Optional argument eventcode values started or done\n";
print "Write to event log \n";

print "\nReturn values\n";
print "Check the application evnet log\n";
&T38lib::Common::warnme("Testing Common.pm");

print "$line";

#----------------

print "Call \&T38lib::Common::errme('Testing Common.pm')\n";
print "Input argument message to dispay\n";
print "Optional argument eventcode values started or done\n";
print "Write to event log \n";

print "\nReturn values\n";
print "Check the application evnet log\n";
&T38lib::Common::errme("Testing Common.pm");

print "$line";

#----------------

print "Call \&T38lib::Common::parseProgramName()\n";
print "Input argument NONE \n";
print "Output argument program path, Program Name, Program Suffix\n";

print "\nReturn values\n";
($pp, $pn, $ps) =  &T38lib::Common::parseProgramName();

print "$pp\n$pn\n$ps\n";

print "$line";

#----------------


print "Call \&T38lib::Common::readINI('inifilename', 'sectionName', 'Key')\n";
print "Input argument one is INI File Name \n";
print "Input argument two is section name with in the ini filename\n";
print "Input argument three is key with in the above section name in the ini filename\n";
print "Output argument return value of the key if no error\n";
print "In case of an ERROR\n";
print "Return section name if section name is not found in the ini file\n";
print "Return key if the key is not found in the ini file\n";
print "Return key if the key is there but there no value assign to the key\n";

print "\nReturn values\n";
$key =  &T38lib::Common::readINI('abc.ini', 'Software', 'Status');

print "$key\n";

print "$line";

#----------------

print "Call \&T38lib::Common::rebootLocalMachine()\n";
print "Input argument NONE \n";
print "Output argument None\n";
print "Reboot the local machine.\n";

print "\nReturn values\n";
print "Check the code to see how to call this function\n";
print "I did not call the function because it will reboot your machine\n"; 
#--&T38lib::Common::rebootLocalMachine();

print "$line";

#----------------

print "Call \&T38lib::Common::startService(MSSQLSERVER)\n";
print "Input argument one Service Name \n";
print "Output argument 1 successfully started, 0 failed\n";

print "\nReturn values\n";
$res = &T38lib::Common::startService('MSSQLSERVER');

print "$res";

print "$line";

#----------------

print "Call \&T38lib::Common::stopService(MSSQLSERVER)\n";
print "Input argument one Service Name \n";
print "Output argument 1 successfully stopped, 0 failed\n";

print "\nReturn values\n";
$res = &T38lib::Common::stopService('MSSQLSERVER');

print "$res";

print "$line";

#----------------

print "Call \&T38lib::Common::stripFileExt('abc.ini')\n";
print "Input argument one string with path and file name information \n";
print "Output return the string after removing the file extension\n";

print "\nReturn values\n";
$str = &T38lib::Common::stripFileExt("abc.ini");

print "$str\n";

print "$line";

#----------------

print "Call \&T38lib::Common::stripPath($0)\n";
print "Input argument one string with path and file name information \n";
print "Output return the string after removing the path information\n";

print "\nReturn values\n";
$str = &T38lib::Common::stripPath("$0");

print "$str\n";

print "$line";

#----------------

print "Call \&T38lib::Common::stripWhitespace('   Asif    ')\n";
print "Input argument one string with spaces at front and at the end\n";
print "Output return the string after removing the spaces from front and at the end\n";

print "\nReturn values\n";
$str = &T38lib::Common::stripWhitespace("   Asif   ");

print "$str\n";

print "$line";

#----------------

#ASIF:

print "Call \&T38lib::Common::whence('rmtshare.exe')\n";
print "Input argument one file name, check to see if that file can be found via path variable\n";
print "Output return full file name, 0 in case of failure \n";

print "\nReturn values\n";
$str = &T38lib::Common::whence("rmtshare.exe");

print "$str\n";

print "$line";

#----------------
