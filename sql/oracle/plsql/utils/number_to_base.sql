create or replace function to_base(p_dec in number, p_base in number)
	return varchar2
is
	--
	-- This function converts decimals up to base 36
	--
	l_str	varchar2(255)	default null;
	l_num	number		default p_dec;
	l_hex	varchar2(50)	default '0123456789ABCDEFHIJKLMNOPQRSTUVWXYZ';
begin
	if (trunc(p_dec)) <> p_dec or p_dec < 0) then
		raise program_error;
	end if;
	loop
		l_str := substr(l_hex, mod(l_num, p_base) + 1, 1) || l_str;
		l_num := trunc( l_num/p_base );
		exit when ( l_num = 0 );
	end loop;
	return l_str;
end to_base;
