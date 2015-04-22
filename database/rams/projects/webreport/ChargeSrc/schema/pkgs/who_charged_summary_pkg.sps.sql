-- $Id: who_charged_summary_pkg.sps.sql,v 1.1 2007/10/18 20:38:18 yangl Exp $
create or replace package hostdb.Who_Charged_Summary_Pkg
is
    -- ------------------------------------------------------------------

    type Service_Code_Table
	is table of varchar2(1)
		index by binary_integer ;

    -- ------------------------------------------------------------------

    Cursor Charges ( c_jid in number ) is
    	--
    	select		wc.journal			journal_id
    		,	trunc(wc.trans_date)		trans_date
    		,	wc.wr_id			wr_id
    		,	wc.account			account_id
    		,	rtrim(nvl(wc.account_flag,'.'))	account_flag
    		,	wc.pct				pct
    		,	rtrim(nvl(wc.notes,'.')) 	notes
    	--
    		,	rtrim(s.WebCode)	service_code
    		,	wc.charge
    		,	wc.amount
    	--
                 from	hostdb.who_charged	wc
		,	hostdb.services		s
    	--
                 where	wc.journal		= c_jid
--		   and	trunc(wc.trans_date)	= to_date('31-May-2004','DD-MON-YYYY')
--		   and	wc.wr_id		= 52561
--		   and	wc.account		= 59343
		   and	wc.service_id		= s.id
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

End Who_Charged_Summary_Pkg ;
/
Show Errors
