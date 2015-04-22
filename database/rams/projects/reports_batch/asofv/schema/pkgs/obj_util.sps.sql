-- $Id: obj_util.sps.sql,v 1.1 2006/08/03 19:06:18 yangl Exp $
--
create or replace package utility.obj_util
	authid current_user
is
	function is_table(
			pOwner in varchar2
			,pName in varchar2
		) return boolean;

	function is_view(
			pOwner in varchar2
			,pName in varchar2
		) return boolean;
end obj_util;
/
Show errors
