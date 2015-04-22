rem Author:  Longjiang Yang
rem Name:    ascii.sql
rem Purpose: Print ascii table
rem Usage:   @ascii
rem Subject: object
rem Attrib:  pls
rem Descr:
rem Notes:   Output determined by character encoding of your terminal
rem SeeAlso:
rem History:
rem          14-feb-02  Initial release

@setup
set serveroutput on size 10240

declare
	i number;
	j number;
	k number;
begin
	for i in 2..15 loop
		for j in 1..16 loop
			k:=i*16+j;
			dbms_output.put((to_char(k,'000'))||':'||chr(k)||'  ');
			if k mod 8 = 0 then
  				dbms_output.put_line(' ');
			end if;
		end loop;
	end loop;
end;
/

@setdefs

