-- $Id: host_charged_summary_pkg.spb.sql,v 1.1 2007/10/18 20:38:18 yangl Exp $
create or replace package body hostdb.Host_Charged_Summary_Pkg
is

    -- ----------------------------------------------------------------------

    procedure output_header ;

    procedure output_line
	( summary		Charges%RowType
	, services_string	hostdb.gl_report.services%type ) ;

    -- ----------------------------------------------------------------------

    procedure generate ( v_jid in hostdb.journals.id%type )
    is
        -- ------------------------------------------------------------------

        current		charges%RowType ;

        summary		charges%RowType ;

	inserts		integer := 0 ;

	svcs		integer ;

        -- ------------------------------------------------------------------
    begin

	-- output_header() ;

        open Charges ( v_jid ) ;

        fetch Charges into summary ;

        if ( Charges%NotFound ) then
		raise No_Data_Found ;
        end if ;

	Service_Codes.first ( summary.service_code ) ;

	svcs := 1 ;

        fetch Charges into current ;

        while ( Charges%Found ) loop

	    svcs := svcs + 1 ;

--	    print_comparison ( summary, current ) ;

            if (   ( summary.journal_id     =  current.journal_id	)
	       and ( summary.trans_date     =  current.trans_date	)
	       and ( summary.hr_id          =  current.hr_id		)
	       and ( summary.account_id     =  current.account_id	)
	       and ( summary.account_flag   =  current.account_flag	)
	       and ( summary.pct            =  current.pct		)
	       and ( summary.notes          =  current.notes		)
	     ) then
		summary.charge	:= summary.charge + current.charge ;
		summary.amount	:= summary.amount + current.amount ;
		Service_Codes.add ( current.service_code ) ;
	    else
		insert_row ( summary ) ;
		inserts := inserts + 1 ;
                summary := current ;
		Service_Codes.first ( summary.service_code ) ;
	    end if ;

            fetch Charges into current ;

        end loop ;

	insert_row ( summary ) ;

	inserts := inserts + 1 ;

	dbms_output.put_line('- - -') ;

	dbms_output.put_line('Services rendered  = '||to_char(svcs)) ;
	dbms_output.put_line('Summary rows       = '||to_char(inserts)) ;

	dbms_output.put_line('- - -') ;

        close Charges ;

    exception

   	when No_Data_Found then

		close Charges ;

		dbms_output.put_line('- - -') ;
		dbms_output.put_line('Services rendered  = '||to_char(0)) ;
		dbms_output.put_line('Summary rows       = '||to_char(0)) ;
		dbms_output.put_line('- - -') ;

    end generate ;

    -- ----------------------------------------------------------------------

    procedure print_comparison ( summary in Charges%RowType, current in Charges%RowType )
    is
    begin

	    dbms_output.put_line('- - -') ;
	    dbms_output.put_line(rpad('hr_id:',15)
		|| rpad(to_char(summary.hr_id),15)||'  =  '||to_char(current.hr_id) ) ;
	    dbms_output.put_line(rpad('journal_id:',15)
		|| rpad(to_char(summary.journal_id),15)||'  =  '||to_char(current.journal_id) ) ;
	    dbms_output.put_line(rpad('trans_date:',15)
		|| rpad(to_char(summary.trans_date),15)||'  =  '||to_char(current.trans_date) ) ;
	    dbms_output.put_line(rpad('account_id:',15)
		|| rpad(to_char(summary.account_id),15)||'  =  '||to_char(current.account_id) ) ;
	    dbms_output.put_line(rpad('account_flag:',15)
		|| rpad(summary.account_flag,15)||'  =  '||current.account_flag ) ;
	    dbms_output.put_line(rpad('pct:',15)
		|| rpad(to_char(summary.pct),15)||'  =  '||to_char(current.pct) ) ;
	    dbms_output.put_line(rpad('notes:',15)
		|| rpad(summary.notes,15)||'  =  '||current.notes ) ;

    end print_comparison ;

    -- ----------------------------------------------------------------------

    procedure insert_row
	( summary		Charges%RowType )
    is
	services_string		hostdb.gl_report.services%type ;
    begin

	services_string := Service_Codes.to_string ;

	-- output_line ( summary, services_string ) ;

	insert into host_charged_summary
		( hr_id
		, journal_id
		, trans_date
		, account_id
		, account_flag
		, pct
		, notes
		, charge
		, amount
		, services
		) values
		( summary.hr_id
		, summary.journal_id
		, summary.trans_date
		, summary.account_id
		, decode(summary.account_flag,'.',null,summary.account_flag)
		, summary.pct
		, decode(summary.notes,'.',null,summary.notes)
		, summary.charge
		, summary.amount
		, services_string
		) ;

    end insert_row ;

    -- ----------------------------------------------------------------------

    procedure output_header
    is
    begin
	dbms_output.put_line
		(  rpad('Journal_Id',14)
		|| rpad('Trans_Date',14)
		|| rpad('HR_Id',8)
		|| rpad('Account Id',12)
		|| rpad('Flag',6)
		|| rpad('Pct',8)
		|| rpad('Services',10)
		|| 'Notes'
		) ;
    end ;

    -- ----------------------------------------------------------------------

    procedure output_line
	( summary		Charges%RowType
	, services_string	hostdb.gl_report.services%type )
    is
    begin

	dbms_output.put_line
		(  /* rpad('Journal_Id',14)	*/ rpad(to_char(summary.journal_id),14)
		|| /* rpad('Trans_Date',14)	*/ rpad(to_char(summary.trans_date),14)
		|| /* rpad('HR_Id',8)		*/ rpad(to_char(summary.hr_id),8)
		|| /* rpad('Account Id',12)	*/ rpad(to_char(summary.account_id),12)
		|| /* rpad('Flag',6)		*/ rpad(summary.account_flag,6)
		|| /* rpad('Pct',8)		*/ rpad(to_char(summary.pct),8)
		|| /* rpad('Services',10)	*/ rpad(services_string,10)
		|| /* 'Notes'			*/ summary.notes
		) ;

    end output_line ;

    -- ----------------------------------------------------------------------

end Host_Charged_Summary_Pkg ;
/
Show Errors
