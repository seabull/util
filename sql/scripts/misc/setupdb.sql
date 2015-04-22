rem Author:  Longjiang Yang
rem Name:    setupdb.sql
rem Purpose: Accept parameter as database; ?=local
rem Usage:   @@setupdb
rem Subject: sqlplus
rem Attrib:  sql nst
rem Descr:
rem Notes:   Places database in "db" define
rem SeeAlso:
rem History:
rem           01-feb-02 Initial release

define tmp="&&1"
set termout off
column name__ new_value db
select decode('&&tmp','?','','@&&tmp') name__ from v$database;
set termout on
