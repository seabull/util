-- $Id: form.sps.sql,v 1.2 2007/09/13 21:59:57 yangl Exp $
create or replace PACKAGE hostdb.FORM  AS
  -- $Id: form.sps.sql,v 1.2 2007/09/13 21:59:57 yangl Exp $
  --
  constLimboFlag	varchar2(1)	:= 'l';
  constInternalFlag	varchar2(1)	:= 'i';
  constBackchargeFlag	varchar2(1)	:= 'b';
  constRefundFlag	varchar2(1)	:= 'r';
  constTransferFlag	varchar2(1)	:= 't';
  constForgiveFlag	varchar2(1)	:= 'f';

  constDEBUG_LEVELA	pls_integer := 2;
  constDEBUG_LEVELB	pls_integer := 4;
  constDEBUG_LEVELC	pls_integer := 8;
  constDEBUG_LEVELD	pls_integer := 16;
  constDEBUG_LEVELE	pls_integer := 32;

  TYPE account_segs_t IS VARRAY(5) OF VARCHAR2(8);

  SUBTYPE account_t IS accounts.id%TYPE;
  PROCEDURE refund(tab VARCHAR2, ri VARCHAR2);
  PROCEDURE transfer(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2);
  PROCEDURE backcharge(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2);
  PROCEDURE forgive(tab VARCHAR2, ri VARCHAR2, undo_flag pls_integer default 0);

  FUNCTION account_from_string(s VARCHAR2) RETURN account_t;
  FUNCTION account_from_string2(s VARCHAR2) RETURN account_t;
  function isForgiveable(tab varchar2, ri varchar2) return boolean;
END;
/
Show Errors
