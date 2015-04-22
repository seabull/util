
/*
 * This is the script to create the mail package that 
 * serves as a wrapper of UTL_SMTP package. 
 * You can use the package to send email easily. Here is an example usage,
	begin
		mail_pkg.send
			( p_sender_email => 'me@acme.com',
			p_from => 'Oracle Database Account <me@abc.com>',
			p_to => mail_pkg.t_array( 'coyote@abc.com', 'roadrunner@abc.com' ),
			p_cc => mail_pkg.t_array( 'kermit@abc.com' ),
			p_bcc => mail_pkg.t_array( 'noone@dev.null' ),
			p_subject => 'This is a subject',
			p_body => 'Hello, this is the mail you need' );
	end;
 */

create or replace package mail_pkg
as
    type t_array is table of varchar2(255);

    g_emptyarray t_array := t_array();
    g_crlf       char(2) default chr(13)||chr(10);
    g_mailhost   varchar2(255) := 'smtp.cs.cmu.edu';

    procedure send( p_sender_email in varchar2,
                    p_from         in varchar2 default NULL,
                    p_to           in t_array default g_emptyarray,
                    p_cc           in t_array default g_emptyarray,
                    p_bcc          in t_array default g_emptyarray,
                    p_subject      in varchar2 default NULL,
                    p_body         in long default NULL );
end;
/



create or replace package body mail_pkg
as

    g_mail_conn   utl_smtp.connection;

    function address_email( p_string in varchar2,
                            p_recipients in t_array ) return varchar2
    is
        l_recipients long;
    begin
       for i in 1 .. p_recipients.count
       loop
          utl_smtp.rcpt(g_mail_conn, p_recipients(i) );
          if ( l_recipients is null ) 
          then
              l_recipients := p_string || p_recipients(i) ;
          else
              l_recipients := l_recipients || ', ' || p_recipients(i);
          end if;
       end loop;
       return l_recipients;
    end;


    /*
                    p_to           in t_array default g_emptyarray,
                    p_cc           in t_array default g_emptyarray,
                    p_bcc          in t_array default g_emptyarray,
     */
    procedure send( p_sender_email in varchar2,
                    p_from         in varchar2 default NULL,
                    p_to           in t_array default g_emptyarray,
                    p_cc           in t_array default g_emptyarray,
                    p_bcc          in t_array default g_emptyarray,
                    p_subject      in varchar2 default NULL,
                    p_body         in long  default NULL )
    is
        l_to_list   long;
        l_cc_list   long;
        l_bcc_list  long;
        l_date      varchar2(255) default
                    to_char( SYSDATE, 'dd Mon yy hh24:mi:ss' );
    
        procedure writeData( p_text in varchar2 )
        as
        begin
            if ( p_text is not null ) 
            then
                utl_smtp.write_data( g_mail_conn, p_text || g_crlf );
            end if;
        end;
    
        /*
         * send header data
         * name - name of the header including ':' e.g. 'FROM:', 'To: '
         * header - header text
         */
        procedure sendHeader( p_name IN varchar2, p_header IN VARCHAR2 )
        as
        begin
            if (p_header is not null) then
                utl_smtp.write_data( g_mail_conn, p_name || p_header || g_crlf );
            end if;
        end sendHeader;
    
    begin
        g_mail_conn := utl_smtp.open_connection(g_mailhost, 25);
    
        utl_smtp.helo(g_mail_conn, g_mailhost);
        utl_smtp.mail(g_mail_conn, p_sender_email);

        l_to_list  := address_email( 'To: ', p_to );
        l_cc_list  := address_email( 'Cc: ', p_cc );
        l_bcc_list := address_email( 'Bcc: ', p_bcc );
    
        utl_smtp.open_data(g_mail_conn );
    
        writeData( 'Date: ' || l_date );
        writeData( 'From: ' || nvl( p_from, p_sender_email ) );
        writeData( 'Subject: ' || nvl( p_subject, '(no subject)' ) );
    
        writeData( l_to_list );
        writeData( l_cc_list );
    
        utl_smtp.write_data( g_mail_conn, '' || g_crlf ); 
        utl_smtp.write_data(g_mail_conn, p_body );
        utl_smtp.close_data(g_mail_conn );
        utl_smtp.quit(g_mail_conn);
    exception
        when utl_smtp.transient_error OR utl_smtp.permanent_error THEN
            BEGIN
                utl_smtp.quit(g_mail_conn);
            EXCEPTION
                WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
                    NULL; 
                    -- When the SMTP server is down or unavailable, we don't have
                    -- a connection to the server. The quit call will raise an
                    -- exception that we can ignore.
            END;
            raise_application_error(-20000,
                 'Failed to send mail due to the following error: ' || sqlerrm);
    end send;
end;
/

