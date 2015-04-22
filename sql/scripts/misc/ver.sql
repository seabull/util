rem Author:  Longjiang Yang
rem Name:    ver.sql
rem Purpose: Show product version information and installed options
rem Usage:   @ver
rem Subject: database
rem Attrib:  sql
rem Descr:
rem Notes:
rem SeeAlso:
rem History:
rem          14-feb-02  Initial release

@setup
set heading off

column banner format a60 wrap

SELECT banner FROM v$version;

SELECT 'With '||parameter||' option'
FROM v$option
WHERE value = 'TRUE';

SELECT '('||parameter||' option not installed'||')'
FROM v$option
WHERE value <> 'TRUE';

@setdefs
