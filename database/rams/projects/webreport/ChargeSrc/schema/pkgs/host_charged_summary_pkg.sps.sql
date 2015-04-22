-- $Id: host_charged_summary_pkg.sps.sql,v 1.1 2007/10/18 20:38:18 yangl Exp $
create or replace package hostdb.Host_Charged_Summary_Pkg
is
    -- ------------------------------------------------------------------

    type Service_Code_Table
	is table of varchar2(1)
		index by binary_integer ;

    -- ------------------------------------------------------------------

    Cursor Charges ( c_jid in number ) is
    	--
    	select		hc.journal			journal_id
    		,	trunc(hc.trans_date)		trans_date
    		,	hc.hr_id			hr_id
    		,	hc.account			account_id
    		,	rtrim(nvl(hc.account_flag,'.'))	account_flag
    		,	hc.pct				pct
    		,	rtrim(nvl(hc.notes,'.')) 	notes
    	--
    		,	rtrim(s.WebCode)	service_code
    		,	hc.charge
    		,	hc.amount
    	--
                 from	hostdb.host_charged	hc
		,	hostdb.services		s
    	--
                 where	hc.journal		= c_jid
--		   and	trunc(hc.trans_date)	= to_date('31-May-2004','DD-MON-YYYY')
--		   and	hc.hr_id		= 52561
--		   and	hc.account		= 59343
		   and	hc.service_id		= s.id
    	--
--		   and	rownum			<= 3000
    	--
    	 order by	1, 2, 3, 4, 5, 6, 7, 8
    	;

    -- ------------------------------------------------------------------

    procedure generate ( v_jid in hostdb.journals.id%type ) ;

    procedure insert_row
	( summary		in  Charges%RowType ) ;

    procedure print_comparison
	( summary		in  Charges%RowType
	, current		in  Charges%RowType ) ;

    -- ------------------------------------------------------------------

End Host_Charged_Summary_Pkg ;
/
Show Errors
