create table debugtab
(
--
-- This is the table used by DEBUG package
-- Author : Longjiang Yang
--
	userid      varchar2(30),
	filename    varchar2(1024),
	modules     varchar2(4000),
	show_date   varchar2(3),
	date_format varchar2(255),
	name_length number,
	session_id  varchar2(3),
	dlevel       number,	-- added by LJ Yang 
	--
	-- Constraints
	--
	constraint debugtab_pk 
		primary key ( userid, filename ),
	constraint debugtab_show_date_ck 
		check ( show_date in ( 'YES', 'NO' ) ),
	constraint debugtab_session_id_ck 
		check ( session_id in ( 'YES', 'NO' ) )
)
/
