rem ---------------------------------------------------------------------------
rem Author:  Longjiang Yang, 2001
rem Name:    sure.sql
rem Purpose: Embedded script to prompt user before an action
rem Usage:   @sure
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:   Modifies DUMMY define
rem SeeAlso:
rem History:
rem          12-Dec-01  Initial draft

accept dummy char prompt "Press ENTER to execute or CTRL+C to cancel..." hide
undef dummy

