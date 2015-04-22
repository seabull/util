REM --- This is the installation script to install DEBUG.LOG which is 
REM --- similiar to printf() or log() in other languages
REM --- Usage: DEBUG.LOG(12, 'Entering, arg1=%s',arg1);
REM Create utility user
REM create user utility identified by utility;
REM grant create session, create procedure, create table, create trigger to utility;
REM alter user utility default tablespace users quota unlimited on users;
REM run install_debug in that schema
REM create a public synonym for debug 
REM
@debugtab.sql
@biu_fer_debugtab.sql
@debug_def.sql
@debug_body.sql
