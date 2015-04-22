create user ramstest identified by "ramstest now"
	default tablespace apps
	quota 128M on apps
	temporary tablespace temp
	quota 128M on temp
	account unlock;

grant create session
	, create table
	, create view
	, create procedure
	, create sequence 
to ramstest;

grant select on v_$parameter
to ramstest;

grant costing_view to ramstest;
alter user ramstest default role all;
