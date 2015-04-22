rem -----------------------------------------------------------
rem Author:  Longjiang Yang, 2001
rem Name:    setup.sql
rem Purpose: Setup environment for all scripts
rem Usage:   @setup
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:
rem SeeAlso:
rem History:
rem          12-Dec-01  Initial Draft
rem -----------------------------------------------------------

set echo off

rem allow report starts anywhere, not only a new page
set embedded on		
set feedback off
set heading on
set linesize 80
set pagesize 9999

rem turn off record sep
set recsep off		
set verify off

define sqllib="lang_util"

rem	define commonly used chars
define cr="chr(10)"
define am="chr(38)"
define qt="chr(39)"

define sysroles="'CONNECT','RESOURCE','DBA','IMP_FULL_DATABASE','EXP_FULL_DATABASE'"
define sysusers="'SYS','SYSTEM'"

define putl="sys.dbms_output.put_line"

rem -----------------------------------------------------------
rem define some roles
rem -----------------------------------------------------------

define appdevrole="APP_DEVELOPER"
define appownrole="APP_OWNER"
define appusrrole="APP_USER"
define appwebrole="APP_WEB_USER"

define appdevprof="APP_DEVELOPER"
define appownprof="APP_OWNER"
define appusrprof="APP_USER"
define appwebprof="APP_WEB_USER"

define defuserts="USERS"
define deftempts="TEMP"

define ascdate="'Dy Mon DD YYYY HH24:MI:SS'"

rem COMMENT THIS LINE OUT TO USE @SETDB FUNCTIONAILITY
define curdb=""

@setusr

