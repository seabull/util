-- $Id: form.spb.sql,v 1.2 2007/09/13 21:59:57 yangl Exp $
create or replace PACKAGE BODY hostdb.FORM   AS
  -- $Id: form.spb.sql,v 1.2 2007/09/13 21:59:57 yangl Exp $
  --

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

	IF (i <= 0) THEN
		RETURN;
	END IF;

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

  -------------------------------------------------------------------------------
  -- process row-by-row.
  -- This should be improved to use collections which were not
  -- available in Oracle 8.
  -------------------------------------------------------------------------------
  PROCEDURE adjust(tab VARCHAR2, ri VARCHAR2, balanced BOOLEAN, dist VARCHAR2, p_flag IN VARCHAR2) IS
    i INTEGER;
    i2 INTEGER;
    j INTEGER;
    naccount	account_t;
    hc		host_charged%ROWTYPE;
    wc		who_charged%ROWTYPE;
    pct		host_charged.pct%TYPE;
    opct	pct%TYPE;
    tpct	pct%TYPE;
    npct	pct%TYPE;
    namount	host_charged.amount%TYPE;
    oamount	host_charged.amount%TYPE;
    cnotes	host_charged.notes%TYPE;
    dnotes	host_charged.notes%TYPE;
    oaflag	host_charged.account_flag%TYPE;
    oaccount	account_t;
  BEGIN
	traceit.log(constDEBUG_LEVELA, 'Enter adjust (%s,%s,%s,%s,%s)',tab,ri,Util.boolToString(balanced),dist,p_flag);
  	IF (balanced AND dist IS NULL) THEN
			traceit.log(constDEBUG_LEVELA, 'distribution string cannot be null on transfer or backcharge');
  			raise_application_error(
  				X.Dist_String,'distribution string cannot be null on transfer or backcharge'
  		  );
  	END IF;

	---------------------------------------------------------------------------------------

  	IF (tab = 'host_charged') THEN
		SELECT *
		  INTO hc
		  FROM host_charged hc
		 WHERE hc.rowid=ri;

		oaccount := hc.account;
  		opct := hc.pct;
		oamount := hc.amount;
		oaflag := hc.account_flag;

  	ELSE	IF (tab = 'who_charged') THEN
			  SELECT *
			    INTO wc
			    FROM who_charged wc
			   WHERE wc.rowid=ri;

			oaccount := wc.account;
    			opct := wc.pct;
			oamount := wc.amount;
			oaflag := wc.account_flag;
  		ELSE
  			raise_application_error(
  				X.Charge_Adjust,'unsupported adjustment table: '||tab
  					);
  		END IF;
	END IF;
	traceit.log(constDEBUG_LEVELD, 'charge line:acct=%s,pct=%s,amt=%s,aflag=%s',oaccount,pct,oamount,oaflag);

	---------------------------------------------------------------------------------------
	-- This should be verified by the client, but double check anyway.
	if (oaflag is null or oaflag = constInternalFlag) then
		if (p_flag = constRefundFlag or p_flag = constTransferFlag) then
			null;
		else
			-- only transfer or refund is allowed
			traceit.log(constDEBUG_LEVELA, 'Operation other than Transfer or Refund is not allowed for account_flag=%s',oaflag);
  			raise_application_error(
  				X.Charge_Adjust
				,'Operation other than Transfer or Refund is not allowed for Limbo or Backcharged charges: '||oaflag
  					);
		end if;
	else	if (p_flag = constTransferFlag or p_flag = constRefundFlag) then
			-- account_flag is Limbo ('l')  or Backcharge ('b')
			-- transfer or refund is not allowed
			traceit.log(constDEBUG_LEVELA, 'Transfer or Refund is not allowed for account_flag=%s',oaflag);
  			raise_application_error(
  				X.Charge_Adjust
				,'Transfer or Refund is not allowed for Limbo or Backcharged charges: '||oaflag
  					);
		end if;
	end if;

	---------------------------------------------------------------------------------------

  	j := 1;
  	tpct := 100;
  	LOOP
  		Util.log(tab||','||Util.boolToString(balanced));
		traceit.log(constDEBUG_LEVELD, '%s,%s',tab,Util.boolToString(balanced));
  		IF (balanced) THEN
			-- Transfer or Backcharge goes here
	  		charge(dist,j,naccount,pct);
	  	  	EXIT WHEN (naccount IS NULL);

	  		IF (pct = 100) THEN
				IF (lower(rtrim(oaflag)) = constLimboFlag) then
					IF (lower(rtrim(p_flag)) = constBackchargeFlag) then
						-- cnotes := 'Backcharged';
			  			SELECT 'Backcharged to '
							||Account_string(a.funding,a.function,a.activity,a.org,a.entity
									,a.project,a.task,a.award,null,null)
	  				 	  INTO cnotes
						  FROM accounts a
						 WHERE a.id=naccount;

		  				dnotes := 'Backcharge';
					ELSE
						traceit.log(constDEBUG_LEVELA
							, 'Unknown Operation %s  for limbo charges.',p_flag);
  						raise_application_error(
  							X.Charge_Adjust
							,'Unknown Operation for Limbo charges: '||p_flag
  						);
					END IF;
				ELSE
					IF (lower(rtrim(p_flag)) = constTransferFlag) then
			  			SELECT 'Transfer to '
							||Account_string(a.funding,a.function,a.activity,a.org,a.entity
									,a.project,a.task,a.award,null,null)
	  				 	  INTO cnotes
						  FROM accounts a
						 WHERE a.id=naccount;

		  				dnotes := 'Transfer';
					ELSE
						traceit.log(constDEBUG_LEVELA
							, 'Unknown Operation %s  for valid charges.',p_flag);
  						raise_application_error(
  							X.Charge_Adjust
							,'Unknown Operation for valid charges: '||p_flag
  						);
					END IF;
				END IF;

	  	  	ELSE
				IF (lower(rtrim(oaflag)) = constLimboFlag) then
					IF (lower(rtrim(p_flag)) = constBackchargeFlag) then
						cnotes := 'Backcharge allocated';
						dnotes := 'Backcharge allocation';
					ELSE
						traceit.log(constDEBUG_LEVELA
							, 'Unknown Operation %s  for limbo charges.',p_flag);
  						raise_application_error(
  							X.Charge_Adjust
							,'Unknown Operation for Limbo charges: '||p_flag
  						);
					END IF;
				ELSE
					IF (lower(rtrim(p_flag)) = constTransferFlag) then
	  	  				cnotes := 'Reallocated';
	  	  				dnotes := 'Reallocation';
					ELSE
						traceit.log(constDEBUG_LEVELA
							, 'Unknown Operation %s  for valid charges.',p_flag);
  						raise_application_error(
  							X.Charge_Adjust
							,'Unknown Operation for valid charges: '||p_flag
  						);
					END IF;
				END IF;
	  	  	END IF;

	 		SELECT dnotes||' from '||Account_string(a.funding,a.function,a.activity,a.org,a.entity,a.project,a.task,a.award,null,null)
	 		  INTO dnotes
			  FROM accounts a
			 WHERE a.id=oaccount;

  		ELSE
			-- Refund goes here
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
		traceit.log(constDEBUG_LEVELD,'Calc %s,%s,%s',npct,namount,tab);

		-- Charge to new account(s)
  		IF (tab = 'host_charged') THEN
			  INSERT INTO host_adjust_charge (
			    	hr_id
				,pct
				,hpct
				,charge
				,amount
				,trans_date
				,service_id
				,account,notes
			  ) VALUES(
				hc
				.hr_id
				,npct
				,hc.hpct
				,hc.charge
				,namount
				,hc.trans_date
				,hc.service_id
				,naccount
				,dnotes
			  );
  		ELSE IF (tab = 'who_charged') THEN
			  INSERT INTO who_adjust_charge (
			  	wr_id
				,pct
				,charge
				,amount
				,trans_date
				,service_id
				,account,notes
			  ) VALUES(
			  	wc.wr_id
				,npct
				,wc.charge
				,namount
				,wc.trans_date
				,wc.service_id
				,naccount
				,dnotes
			  );
			ELSE
  				raise_application_error(
  					X.Oops,'no table for adjust debit insert'
  		  			);
  			END IF;
		END IF;

  	END LOOP;

	---------------------------------------------------------------------------------------

  	IF (tpct != 0) THEN
  			raise_application_error(
  				X.Dist_String,'distribution percentages summed to '||(100-tpct)||' rather than 100'
  		  );
	END IF;

	IF (lower(rtrim(p_flag)) = constBackchargeFlag) then
		IF (lower(rtrim(oaflag)) = constLimboFlag) THEN
			-- Backcharge, no need to undo the original charge since it did not go thru any way.
			IF (tab = 'host_charged') THEN
				update host_charged
				   set account_flag=constBackchargeFlag
				       ,notes=substr(concat(rtrim(nvl(notes,'')),cnotes),1,50)
				 where rowid=ri
				   and account_flag=oaflag;
			ELSE	IF (tab = 'who_charged') THEN
				update who_charged
				   set account_flag=constBackchargeFlag
				       ,notes=substr(concat(rtrim(nvl(notes,'')),cnotes),1,50)
				 where rowid=ri
				   and account_flag=oaflag;
  				ELSE
  					raise_application_error(
  						X.Oops,'no table for adjust credit insert'
  					  );
				END IF;
			END IF;

			-- should check %ROWCOUNT here
			IF (SQL%ROWCOUNT != 1) THEN
				-- something is wrong, only 1 row should be updated
				insert into backcharge_error_log (
					ID
					,TBL_NAME
					,ROW_ID
					,Error_Date
				)
				select
					backchg_error_seq.nextval
					,tab
					,ri
					,sysdate
				  from dual;
  				raise_application_error(
  						X.Oops,'Error Updating *_charged table row'||ri
  				  );
			END IF;
		ELSE
			-- for Backcharge, account_flag has to be limbo
			-- error out if not.
			traceit.log(constDEBUG_LEVELA
				, 'Backcharge is not allowed for valid charges.');
  			raise_application_error(
  				X.Charge_Adjust
				,'Backcharge not allowed for valid charges.'
  			);

		END IF;

	ELSE	IF (lower(p_flag) = constTransferFlag or lower(p_flag) = constRefundFlag) THEN
			IF (lower(rtrim(oaflag)) = constLimboFlag) THEN
				traceit.log(constDEBUG_LEVELA
					, 'Transfer is not allowed for limbo charges.');
  				raise_application_error(
  					X.Charge_Adjust
					,'Transfer not allowed for limbo charges.'
  				);

			ELSE	IF (tab = 'host_charged') THEN
					-- undo the original charge
					INSERT INTO host_adjust_charge (
						hr_id
						,pct
						,hpct
						,charge
						,amount
						,trans_date
						,service_id
						,account
						,notes
					) VALUES(
						hc.hr_id
						,hc.pct
						,hc.hpct
						,0-hc.charge
						,0-hc.amount
						,hc.trans_date
						,hc.service_id
						,hc.account
						,cnotes
					  );
				ELSE IF (tab = 'who_charged') THEN
					  INSERT INTO who_adjust_charge (
					  	wr_id
						,pct
						,charge
						,amount
						,trans_date
						,service_id
						,account
						,notes
					  ) VALUES(
						 wc.wr_id
						,wc.pct
						,0-wc.charge
						,0-wc.amount
						,wc.trans_date
						,wc.service_id
						,wc.account
						,cnotes
					  );
  					ELSE
  						raise_application_error(
  							X.Oops,'no table for adjust credit insert'
  						  );
					END IF;
				END IF;
			END IF;
		ELSE
				traceit.log(constDEBUG_LEVELA
					, 'Unknown operation flag %s.',p_flag);
  				raise_application_error(
  					X.Charge_Adjust
					,'Unknown operation flag '||p_flag
  				);
		END IF;
	END IF;

	traceit.log(constDEBUG_LEVELA, 'Exit adjust');
  END adjust;

  PROCEDURE adjust(tab VARCHAR2, ri VARCHAR2, balanced BOOLEAN, dist VARCHAR2) IS
  BEGIN
	if ((not balanced) AND dist is null) then
		-- Refund
		adjust(tab, ri, balanced, dist, constRefundFlag);
	else
		-- By default, Transfer if no flag is specified
		adjust(tab, ri, balanced, dist, constTransferFlag);
	end if;
  END adjust;

  PROCEDURE transfer(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2) IS
  BEGIN
	traceit.log(constDEBUG_LEVELA, 'Enter transfer');
  	adjust(tab,ri,true,dist,constTransferFlag);
	traceit.log(constDEBUG_LEVELA, 'Exit transfer');
  END;


  PROCEDURE refund(tab VARCHAR2, ri VARCHAR2) IS
  BEGIN
	traceit.log(constDEBUG_LEVELA, 'Enter refund');
  	adjust(tab,ri,false,null,constRefundFlag);
	traceit.log(constDEBUG_LEVELA, 'Exit refund');
  END;

  PROCEDURE backcharge(tab VARCHAR2, ri VARCHAR2, dist VARCHAR2) IS
  BEGIN
	traceit.log(constDEBUG_LEVELA, 'Enter backcharge');
  	adjust(tab,ri,true,dist,constBackchargeFlag);
	traceit.log(constDEBUG_LEVELA, 'Exit backcharge');
  END;

  procedure forgive_save(tab varchar2, ri varchar2, undo_flag pls_integer) ;

  PROCEDURE forgive(tab VARCHAR2, ri VARCHAR2, undo_flag pls_integer default 0) 
  IS
  BEGIN
	traceit.log(constDEBUG_LEVELA
                , 'Enter forgive, undo_flag=%s, tab=%s, ri=%s'
                , undo_flag, tab, ri);
  	--adjust(tab,ri,false,dist,constForgiveFlag);
    if isForgiveable(tab , ri ) then
        null;
    else
        traceit.log(constDEBUG_LEVELA, 'Cannot forgive valid charges, tab=%s, ri=%s', tab, ri);
        raise_application_error(
  				X.Charge_Adjust
				,'Forgive is not allowed for valid charges: '||tab||':'||ri
  					);
    end if;
    
  	IF (tab = 'host_charged') THEN
        if (undo_flag is null or undo_flag = 0) then
            update host_charged 
               set account_flag = constForgiveFlag
                    ,notes = 'Forgiven charge'
		     WHERE rowid=ri;
        else
            -- assumption: forgiven charges must have been limbo charges
            update host_charged 
               set account_flag = constLimboFlag
                    ,notes = null
		     WHERE rowid=ri;
        end if;
  	ELSE
        IF (tab = 'who_charged') THEN
            if (undo_flag is null or undo_flag = 0) then
                update who_charged 
                   set account_flag = constForgiveFlag
                    ,notes = 'Forgiven charge'
    		     WHERE rowid=ri;
            else
                update who_charged 
                   set account_flag = constLimboFlag
                    ,notes = null
    		     WHERE rowid=ri;
            end if;
  		ELSE
  			raise_application_error(
  				X.Charge_Adjust,'unsupported adjustment table: '||tab
  					);
  		END IF;
	END IF;
    
	traceit.log(constDEBUG_LEVELB, '%s rows updated in %s', SQL%ROWCOUNT, tab);

    forgive_save(tab, ri, undo_flag);

	traceit.log(constDEBUG_LEVELA, 'Exit forgive');
  END;

    function isForgiveable(tab varchar2, ri varchar2) return boolean
    is
        hc      host_charged%ROWTYPE;
        wc      who_charged%ROWTYPE;
        rtn     boolean := false;
    begin
	    traceit.log(constDEBUG_LEVELA, 'Enter isForgive');
      	IF (tab = 'host_charged') THEN
    		SELECT *
    		  INTO hc
    		  FROM host_charged hc
    		 WHERE hc.rowid=ri;
            rtn := (hc.account_flag = constLimboFlag) or (hc.account_flag = constForgiveFlag);
      	ELSE
            IF (tab = 'who_charged') THEN
    			  SELECT *
    			    INTO wc
    			    FROM who_charged wc
    			   WHERE wc.rowid=ri;
                rtn := (wc.account_flag = constLimboFlag) or (wc.account_flag = constForgiveFlag);
      		ELSE
      			raise_application_error(
      				X.Charge_Adjust,'unsupported adjustment table: '||tab
      					);
      		END IF;
    	END IF;
	    traceit.log(constDEBUG_LEVELA, 'Exit isForgive');
        return rtn;
    end isForgiveable;

    -- Do we need to save it?
    procedure forgive_save(tab varchar2, ri varchar2, undo_flag pls_integer) 
    is
        --hc      host_charged%ROWTYPE;
        --wc      who_charged%ROWTYPE;
        l_opr  hostdb.hc_forgiven.operation%TYPE;
    begin
	    traceit.log(constDEBUG_LEVELA, 'Enter forgive_save, tab=%s, ri=%s', tab, ri);
        if (undo_flag is null or undo_flag = 0) then
            l_opr := 'f';
        else
            l_opr := 'u';
        end if;

      	IF (tab = 'host_charged') THEN
    		--SELECT *
    		--  INTO hc
    		--  FROM host_charged hc
    		-- WHERE hc.rowid=ri;
                --(ri, hr_id, account, charge_flag, service_id, journal)
            insert into hc_forgiven
                (hf_id, hc_rowid, operation, op_date)
            select
                hostdb.hf_seq.nextval
                ,ri
                ,l_opr
                ,sysdate
              from dual
            ;
      	ELSE
            IF (tab = 'who_charged') THEN
    			  --SELECT *
    			  --  INTO wc
    			  --  FROM who_charged wc
    			  -- WHERE wc.rowid=ri;
                  -- (ri, wr_id, account, charge_flag, service_id, journal)
                insert into wc_forgiven
                    (wf_id, wc_rowid, operation, op_date)
                    select
                        hostdb.wf_seq.nextval
                        ,ri
                        ,l_opr
                        ,sysdate
                      from dual
                ;
      		ELSE
      			raise_application_error(
      				X.Charge_Adjust,'unsupported adjustment table: '||tab
      					);
      		END IF;
    	END IF;
	    traceit.log(constDEBUG_LEVELA, 'Exit forgive_save');
    end forgive_save;

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
Show Errors
