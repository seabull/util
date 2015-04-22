Create or Replace PACKAGE          "FORM"  IS
  TYPE account_segs_t IS VARRAY(5) OF VARCHAR2(8);

  SUBTYPE account_t IS accounts.id%TYPE;
  PROCEDURE refund(tab VARCHAR2, ri VARCHAR2);
  PROCEDURE transfer(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2);

  FUNCTION account_from_string(s VARCHAR2) RETURN account_t;
  FUNCTION account_from_string2(s VARCHAR2) RETURN account_t;
END;
/
Create or Replace PACKAGE BODY "FORM"   IS

  PROCEDURE charge(
    dist VARCHAR2, j IN OUT INTEGER, a OUT account_t,
    pct OUT NUMBER
  ) IS
    i INTEGER;
    i2 INTEGER;
    d VARCHAR2(31); /* 24(segs) + 1(@) + 6(nnn.nn) */
  BEGIN
  	a:= null;
		i := instr(dist||',',',',j);
    /*Util.log('Form.charge:i='||i||',j='||j||',dist='||dist);*/
		IF (i <= 0) THEN RETURN; END IF;
		/*d := substr(dist,j,i-1);*/
    d := substr(dist,j,i-j);
		/*Util.log('Form.charge:d='||d);*/
    i2 := instr(d, '@', 1);
		IF (i2 <= 0) THEN
			raise_application_error(
				X.Dist_String,'missing @ in distribution string'
			);
		END IF;
		pct := TO_NUMBER(SUBSTR(d,i2+1));
		d := substr(d,1,i2-1);
		a := Account_from_String(d);
		j := i+1;
    /*Util.log('Form.charge:d='||d||',a='||a||',pct='||pct);*/
  END;


  PROCEDURE adjust(tab VARCHAR2, ri VARCHAR2, balanced BOOLEAN, dist VARCHAR2) IS
    i INTEGER;
    i2 INTEGER;
    j INTEGER;
    naccount account_t;
    hc host_charged%ROWTYPE;
    wc who_charged%ROWTYPE;
    pct host_charged.pct%TYPE;
    opct pct%TYPE;
    tpct pct%TYPE;
    npct pct%TYPE;
    namount host_charged.amount%TYPE;
    oamount host_charged.amount%TYPE;
    cnotes host_charged.notes%TYPE;
    dnotes host_charged.notes%TYPE;
    oaccount account_t;
  BEGIN
  	IF (balanced AND dist IS NULL) THEN
  			raise_application_error(
  				X.Dist_String,'distribution string cannot be null on transfer'
  		  );	
  	END IF;
  	
  	IF (tab = 'host_charged') THEN
		  SELECT * INTO hc
		   FROM host_charged hc WHERE hc.rowid=ri;
		  oaccount := hc.account;
  	  opct := hc.pct;
	    oamount := hc.amount;
  	ELSE IF (tab = 'who_charged') THEN
		  SELECT * INTO wc
		   FROM who_charged wc WHERE wc.rowid=ri;
		  oaccount := wc.account;
    	opct := wc.pct;
	    oamount := wc.amount;
  	ELSE
  			raise_application_error(
  				X.Charge_Adjust,'unsupported adjustment table: '||tab
  		  );	
  	END IF; END IF;
  		
  	j := 1;
  	tpct := 100;
  	LOOP
  		Util.log(tab||','||Util.boolToString(balanced));
  		IF (balanced) THEN
	  		charge(dist,j,naccount,pct);
	  	  EXIT WHEN (naccount IS NULL);
	  	  IF (pct = 100) THEN
	  		  SELECT 'Transfer to '||Account_string(a.funding,a.function,a.activity,a.org,a.entity,a.project,a.task,a.award,null,null)
	  		     INTO cnotes FROM accounts a WHERE a.id=naccount;
	  		  dnotes := 'Transfer';
	  	  ELSE
	  	  	cnotes := 'Reallocated';
	  	  	dnotes := 'Reallocation';
	  	  END IF;
		    SELECT dnotes||' from '||Account_string(a.funding,a.function,a.activity,a.org,a.entity,a.project,a.task,a.award,null,null)
		      INTO dnotes FROM accounts a WHERE a.id=oaccount;
  		ELSE
  			tpct := 0;
  			cnotes := 'Refund';
  			EXIT;
  		END IF;
		  npct := pct/tpct*opct;
		  namount := pct/tpct*oamount;
		  opct := opct-npct;
		  oamount := oamount-namount;
		  tpct := tpct-pct;
		  Util.log('Calc '||npct||','||namount||','||tab);
  	  IF (tab = 'host_charged') THEN
			  INSERT INTO host_adjust_charge (
			    hr_id,pct,hpct,charge,amount,trans_date,service_id,
			    account,notes
			  ) VALUES(
			    hc.hr_id,npct,hc.hpct,hc.charge,namount,hc.trans_date,
			    hc.service_id,naccount,dnotes
			  );
  	  ELSE IF (tab = 'who_charged') THEN
			  INSERT INTO who_adjust_charge (
			    wr_id,pct,charge,amount,trans_date,service_id,
			    account,notes
			  ) VALUES(
			    wc.wr_id,npct,wc.charge,namount,wc.trans_date,
			    wc.service_id,naccount,dnotes
			  );
		  ELSE
  			raise_application_error(
  				X.Oops,'no table for adjust debit insert'
  		  );
  	  END IF; END IF;
  	
  	END LOOP;
  	IF (tpct != 0) THEN
  			raise_application_error(
  				X.Dist_String,'distribution percentages summed to '||(100-tpct)||' rather than 100'
  		  );	
	  END IF;
	  IF (tab = 'host_charged') THEN
		  INSERT INTO host_adjust_charge (
		    hr_id,pct,hpct,charge,amount,trans_date,service_id,
		    account,notes
		  ) VALUES(
		    hc.hr_id,hc.pct,hc.hpct,0-hc.charge,0-hc.amount,hc.trans_date,
		    hc.service_id,hc.account,cnotes
		  );
		ELSE IF (tab = 'who_charged') THEN
		  INSERT INTO who_adjust_charge (
		    wr_id,pct,charge,amount,trans_date,service_id,
		    account,notes
		  ) VALUES(
		    wc.wr_id,wc.pct,0-wc.charge,0-wc.amount,wc.trans_date,
		    wc.service_id,wc.account,cnotes
		  );
  	ELSE
  			raise_application_error(
  				X.Oops,'no table for adjust credit insert'
  		  );
		END IF; END IF;
		
  END;


  PROCEDURE transfer(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2) IS
  BEGIN
  	adjust(tab,ri,true,dist);
  END;


  PROCEDURE refund(tab VARCHAR2, ri VARCHAR2) IS
  BEGIN
  	adjust(tab,ri,false,null);
  END;


  /*
   *  Translate an account string to an account ID. This is the old one, obsolete.
   */
  FUNCTION account_from_string2(s VARCHAR2) RETURN account_t IS
    a account_segs_t;
    j INTEGER;
    i INTEGER;
    n INTEGER;
    acct account_t;
  BEGIN
  	j := 1;
  	n := 1;
  	a := account_segs_t(null,null,null,null,null);
  	LOOP
  		i := INSTR(s,'-',j);
  		EXIT WHEN (i <= 0 OR i IS NULL);
  		IF (n > 4) THEN
  			raise_application_error(
  				X.Account_String,'too many segments in account string (max 5)'
  			);
  		END IF;
  		a(n) := SUBSTR(s,j,i-j);
  		n := n+1;
  		j := i+1;
  	END LOOP;
  	a(n) := SUBSTR(s,j);
  	IF (n = 5) THEN
  		SELECT id INTO acct FROM accounts
  		WHERE (funding,function,activity,org,entity) IN
  		      ((a(1),a(2),a(3),a(4),a(5)));
  	ELSE IF (n = 3) THEN
  		SELECT id INTO acct FROM accounts
  		WHERE (project,task,award) IN
  		      ((a(1),a(2),a(3)));
  	ELSE IF (n = 2) THEN
  		SELECT id INTO acct FROM center_map
  		WHERE center=s;
  	ELSE
  		raise_application_error(
  		  X.Account_string,
  		  'unrecognized number of segments('||n||') in account string'
  		);
  	END IF; END IF; END IF;
    RETURN acct;
  END;

/*
 *   translate an account string with seperator of either '.' or '-'
 *   to an account id
 */
FUNCTION account_from_string(s VARCHAR2) RETURN account_t IS
    a account_segs_t;
    j INTEGER;
    i INTEGER;
    n INTEGER;
    acct account_t;
    sep VARCHAR2(1);
BEGIN
        /* assume either '-' or '.' as seperator but not both */
        /* Only '-' can be used since '.' may show up in task */
        /* e.g. 9575-5.4-1010334 */
        IF (INSTR(s, '-') > 0) THEN
                sep := '-';
        ELSE IF (INSTR(s, '.') > 0) THEN
                sep := '.';
        ELSE
                raise_application_error(
                        X.Account_String, 'seperator of account string should be either . or -, but not both'
                        );
        END IF; END IF;
        j := 1;
        n := 1;
        a := account_segs_t(null,null,null,null,null);
        LOOP
                i := INSTR(s,sep,j);
                EXIT WHEN (i <= 0 OR i IS NULL);
                IF (n > 4) THEN
                        raise_application_error(
                                X.Account_String,'too many segments in account string (max 5)'
                        );
                END IF;
                /*Takes care of leading and trainling blanks, --yangl*/
                a(n) := LTRIM(RTRIM(SUBSTR(s,j,i-j)));
                n := n+1;
                j := i+1;
        END LOOP;
        a(n) := LTRIM(RTRIM(SUBSTR(s,j)));
        IF (n = 5) THEN
                SELECT id INTO acct FROM accounts
                WHERE (funding,function,activity,org,entity) IN
                      ((a(1),a(2),a(3),a(4),a(5)));
        ELSE IF (n = 3) THEN
                SELECT id INTO acct FROM accounts
                WHERE (project,task,award) IN
                      ((a(1),a(2),a(3)));
        ELSE IF (n = 2) THEN
                SELECT id INTO acct FROM center_map
                WHERE center=s;
        ELSE
                raise_application_error(
                  X.Account_string,
                  'unrecognized number of segments('||n||') in account string'
                );
        END IF; END IF; END IF;
    RETURN acct;
 EXCEPTION
      WHEN NO_DATA_FOUND THEN
           raise_application_error(
              X.Account_string,
              'unrecognized account '||s
           );
      WHEN OTHERS THEN
           NULL;
END;

END;
/
