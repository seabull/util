REM $Id: utility.sql,v 1.4 2005/05/10 20:44:15 yangl Exp $
REM Create utility user
REM and install the debug package by calling install_debug.sql

@connect '/ as sysdba'
prompt create user utility
create user utility identified by "hjkbnm";
grant create session, create procedure, create table, create trigger to utility;
alter user utility default tablespace apps quota unlimited on apps;

@connect utility/hjkbnm

prompt run install_debug in schema utility
@./install_debug.sql
grant execute on traceit to public;
grant insert,update,delete on debugtab to public;

prompt connect as sysdba
@connect '/ as sysdba'
prompt create public synonym traceit
create public synonym traceit for utility.traceit ;
prompt revoke create session from utility
revoke create session,  create procedure,create trigger from utility;
