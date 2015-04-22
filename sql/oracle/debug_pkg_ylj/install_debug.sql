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
REM usage:
REM	In package/procedure/function
REM	traceit.log(16, 'enter PROC, p_arg1=%s, p_arg2=%s',p_arg1, p_arg2);
REM		p_arg1 and p_arg2 can be NULL, do not need to use nvl()!!!!
REM	To Turn on trace,
REM	exec traceit.status;
REM	exec traceit.init(32, ...);
REM	exec traceit.init(32, 'ALL', '/tmp/FOO.dbg');
@debugtab.sql
@biu_fer_debugtab.sql
@debug_def.sql
@debug_body.sql
