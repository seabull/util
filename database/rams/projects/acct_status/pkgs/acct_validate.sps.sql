-- $Id: acct_validate.sps.sql,v 1.1 2008/07/14 19:59:30 yangl Exp $
--
--	$Author: yangl $
--	$Date: 2008/07/14 19:59:30 $
--
create or replace package acct_validate
	authid definer
as
	--
	-- constants
	--
	eInvalidOracleString	varchar2(7)	:= 'Invalid';
	eValidOracleString	varchar2(5)	:= 'Valid';
	eUnknownStatus		varchar2(10)	:= 'UnknownPTA';

	eOracleStringGM		varchar2(2)	:= 'GM';		
	eOracleStringGL		varchar2(2)	:= 'GL';		
	eOracleStringUnknown	varchar2(8)	:= 'Unknown';		

	gMAXDATE	date := to_date('Dec-31-2057','Mon-DD-YYYY');
	gMINDATE	date := to_date('Jan-01-1960','Mon-DD-YYYY');

	--
	-- public functions
	--
    function account_status(p_acct_string   in varchar2
                            ,p_trans_date   in date)
        return varchar2;

	function checkAcctType(p_acct_string	in varchar2)
		return varchar2;

	function is_valid(p_acct_string		in varchar2
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
			)
		return varchar2;

	function is_valid(p_acct_id in number
				,p_trans_date	in date default trunc(sysdate)
				,p_post_date	in date default trunc(sysdate)
			)
		return varchar2;

end acct_validate;
/
show error;

