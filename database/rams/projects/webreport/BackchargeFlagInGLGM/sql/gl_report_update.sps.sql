-- $Id: gl_report_update.sps.sql,v 1.2 2008/07/14 18:35:43 yangl Exp $

create or replace package hostdb.gl_report_update_pkg
is
    type rpt_flag_update_rec is record
        (
            rid                 rowid
            ,charged_acctflag   char(1)
            ,charged_notes      varchar2(50)
        );

    type rpt_flag_update_tbl is table of rpt_flag_update_rec 
            index by binary_integer;

    procedure acctflag_update;

end gl_report_update_pkg;
/
show errors;
