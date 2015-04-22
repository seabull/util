set showmode off echo off
set heading off pagesize 0 linesize 80 timing off feedback off
set termout off verify off
rem
rem Script: userlocks.sql
rem Purpose: List locks on tables and other objects currently held
rem   by user sessions, including session information and commands
rem   to kill those sessions.
rem
rem Author: Stephen Rea
rem Released: March 22, 1999
rem
column object_name format a10
column username format a10
column owner format a10
column sid format 9999
set heading on pagesize 60 termout on
select username,v$session.sid,serial#,owner,object_id,object_name,
object_type,v$lock.type
from dba_objects,v$lock,v$session where object_id = v$lock.id1
and v$lock.sid = v$session.sid and owner != 'SYS';
set heading off pagesize 0
!echo
!echo To kill locking sessions:
select 'alter system kill session ''' || v$session.sid || ',' ||
serial# || ''';' 
from dba_objects,v$lock,v$session where object_id = v$lock.id1
and v$lock.sid = v$session.sid and owner != 'SYS';
!echo
set linesize 80 termout on heading on pagesize 24 timing on feedback 6
set termout on verify on echo on showmode both


