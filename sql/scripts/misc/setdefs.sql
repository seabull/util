rem Author:  Longjiang Yang
rem Name:    setdefs.sql
rem Purpose: Restore default SqlPlus sets
rem Usage:   @setdefs
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:
rem SeeAlso: @setup
rem History:
rem          01-feb-02  Initial release

ttitle off
btitle off

clear breaks
clear computes
clear columns

set embedded off
set feedback on
set heading on
set linesize 80
set pagesize 14
set recsep wrap
set space 1
set verify on

set termout on
set echo off

undef 1 2 3 4 5 6 7 8 9
undef o1 n1 o2 n2 o3 n3 o4 n4
undef sqllib cr am qt sysusers sysroles
undef putl ascdate dba dbms ora oru segown indown prvgrt prvown
undef appdevrole appownrole appusrrole appwebrole
undef appdevprof appownprof appusrprof appwebprof
undef defuserts deftempts
undef dbmajor dbminor dbaddns

