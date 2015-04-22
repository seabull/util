-- $Id: run.spb.sql,v 1.11 2008/04/23 18:23:33 yangl Exp $

create or replace PACKAGE BODY hostdb.RUN IS

  FUNCTION busiday(asof DATE) RETURN DATE IS
    basof DATE;
  BEGIN
  	basof := asof;
	  /*
	   *  Advance past weekends and holidays.  Jan01 and Jul04
	   *  are problemtatical as CMU uses no fixed rule to
	   *  determine when they are celebrated if they fall on a
	   *  weekend.	We assume FRIJUL03 and MONJUL05 for
	   *  Independence Day and only MONJAN02 for
	   *  New Year's day (observed in previous year when Sat).
	   *
	   *  N.B.  This table is incomplete for holidays outside
	   *  the first week of the month as it is only used to
	   *  find at most the second business day now.
	   */
    LOOP
    	IF (
    		to_char(basof,'DY') IN ('SAT','SUN')OR
    		to_char(basof,'MONDD') IN (
	  	    'JUL04' /* Independence Day */,
		      'JAN01' /* New Year's Day */
		    ) OR
		    to_char(basof,'DYMONDD') IN (
		      /* New Year's Day */
		      'MONJAN02',
		      /* Independence Day */
		      'FRIJUL03','MONJUL05',
		      /* Labor day */
		      'MONSEP01','MONSEP02','MONSEP03','MONSEP04',
		      'MONSEP05','MONSEP06','MONSEP07'
	)
      ) THEN
	basof := basof+1;
      ELSE
	EXIT;
      END IF;
    END LOOP;
    RETURN basof;
  END;

  PROCEDURE distDefine(
    qname VARCHAR, qsubname VARCHAR, qdist dist_names_x.dist%TYPE,
    qsrc dist_names_x.src%TYPE, qpct pct_t
  ) IS
  BEGIN
  	LOCK TABLE dist_names_x IN EXCLUSIVE MODE;
  	IF qpct IS NULL THEN
	  	UPDATE dist_names_x SET dist=qdist,src=qsrc
	  	 WHERE name=qname AND subname=qsubname;
  	ELSE
	  	UPDATE dist_names_x SET dist=qdist,src=qsrc,pct=qpct
	  	 WHERE name=qname AND subname=qsubname;
  	END IF;
  	IF SQL%ROWCOUNT = 0 THEN
  	  INSERT INTO dist_names_x(name,subname,dist,src,pct)
  	   VALUES (qname,qsubname,qdist,qsrc,qpct);
  	END IF;
  END;

  PROCEDURE ICESRecord IS
  BEGIN
  	/*
  	 *  Make sure all accounts referenced by the loaded data are defined.
  	 */
  	INSERT INTO accounts (
  	  funding,function,activity,org,entity,
  	  project,task,award
  	)
  	  SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task,l.award
			  FROM ices_ldr l,accounts a
			 WHERE (
			    l.funding=a.funding(+) AND l.function=a.function(+) AND
			    l.activity=a.activity(+) AND l.org=a.org(+) AND l.entity=a.entity(+)) AND l.funding IS NOT NULL and a.id IS null

			UNION

			SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task ,l.award
			  FROM ices_ldr l,accounts a
			 WHERE (
			    l.project=a.project(+) AND l.task=a.task(+) AND l.award=a.award(+)
			  ) AND l.project IS NOT NULL and a.id IS null;
	  IF (SQL%ROWCOUNT > 0) THEN
	  	dbms_output.put_line('Inserted '||SQL%ROWCOUNT||' unknown ICES accounts');
	  END IF;

  	INSERT INTO ices_recorded(period_last,princ,name,pct,account)
  	  SELECT param.charge_last,l.princ,l.name,l.pct,a.id
	FROM ices_ldr l,param,accounts a
       WHERE (l.project,l.task,l.award)
	  IN ((a.project,a.task,a.award))

      UNION ALL

      SELECT param.charge_last,l.princ,l.name,l.pct,a.id
	FROM ices_ldr l,param,accounts a
       WHERE (l.funding,l.function,l.activity,l.org,l.entity)
	  IN ((a.funding,a.function,a.activity,a.org,a.entity));

    /*
     *	Advance the recording date to nect month to reflect
     *	that we have loaded this month's data.
     */
    UPDATE param SET ices_dist=busiday(last_day(ices_dist)+1);
  END;


  /*
   *  Load the timecard data from table TMCD_LDR and record it for this
   *  period.  Add the necessary canonical fields to allow common
   *  processing.  Map accounts to their id's first for more
   *  compact storage.	Advance the BIWEEKLY_PAY date to indicate
   *  that this data has been loaded.
   */
  PROCEDURE timecardRecord IS
  BEGIN

  	/*
  	 *  Make sure all accounts referenced by the timcards are defined.
  	 */
  	INSERT INTO accounts (
  	  funding,function,activity,org,entity,
  	  project,task,award
  	)
  	  SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task,l.award
			  FROM tmcd_ldr l,accounts a
			 WHERE (
			    l.funding=a.funding(+) AND l.function=a.function(+) AND
			    l.activity=a.activity(+) AND l.org=a.org(+) AND l.entity=a.entity(+)
			  ) AND l.funding IS NOT NULL and a.id IS null

			UNION

			SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task,l.award
			  FROM tmcd_ldr l,accounts a
			 WHERE (
			    l.project=a.project(+) AND l.task=a.task(+) AND l.award=a.award(+)
			  ) AND l.project IS NOT NULL and a.id IS null;
	  IF (SQL%ROWCOUNT > 0) THEN
	  	dbms_output.put_line('Inserted '||SQL%ROWCOUNT||' unknown timecard accounts');
	  END IF;

  	/*
  	 *  Add current period, principal, charge_src and map to
  	 *  account id
  	 */
    /*	Changed the ssn column to emp_num/appointment,
     *	SSN will be deleted and not used any more, instead,
     *	emp_num is used to do name matching
     */
    INSERT INTO tmcd_recorded (
  	    period_last,princ,charge_src,
  	    batch, trcode, appointment,lname, fname, hours, hours_ot,
  	    hed, paydate,home_org, kind,
	account, exp_org
    )
    select
        charge_last
        ,princ
        ,nvl(chargesrc, 'z')
        ,batch
        ,trcode
        ,emp_num
        ,lname
        ,fname
        ,hours
        ,hours_ot
        ,hed
        ,paydate
        ,home_org
        ,kind
        ,id
        ,exp_org
      from
    (
        SELECT
                param.charge_last
                ,l.princ
                ,(select unique kind from charge_sources where org=ho.org_e and attr like '%p%' and rownum < 2) chargesrc
                ,l.batch
                ,l.trcode
                ,l.emp_num
                ,l.lname
                ,l.fname
                ,l.hours
                ,l.hours_ot
                ,l.hed
                ,l.paydate
                ,l.home_org
                ,l.kind
                ,a.id
                ,l.exp_org
          FROM tmcd_princ l
                , accounting.hris_org ho
                ,accounts a
                ,param
         WHERE l.home_org=ho.org(+)
           AND (l.project,l.task,l.award) IN ((a.project,a.task,a.award))
        UNION ALL
        SELECT
                param.charge_last
                ,l.princ
                ,(select unique kind from charge_sources where org=ho.org_e and attr like '%p%' and rownum < 2) chargesrc
                ,l.batch
                ,l.trcode
                ,l.emp_num
                ,l.lname
                ,l.fname
                ,l.hours
                ,l.hours_ot
                ,l.hed
                ,l.paydate
                ,l.home_org
                ,l.kind
                ,a.id
                ,l.exp_org
          FROM tmcd_princ l
                ,accounting.hris_org ho
                ,accounts a
                ,param
         WHERE l.home_org=ho.org(+)
           AND (l.funding,l.function,l.activity,l.org,l.entity)
                    IN ((a.funding,a.function,a.activity,a.org,a.entity))
    )
    ;

    /*
     *	Make sure the HED code is one we expected (e.g. other codes may reflect
     *	kinds of pay that should not contribute hours towards the calculated
     *	effort per month.  Special classes known to be ignorable are
     *	excluded above.
     */
    DECLARE
      thed tmcd_recorded.hed%TYPE;
    BEGIN
      SELECT min(t.hed) INTO thed FROM tmcd_recorded t
       WHERE NOT (
	t.hed LIKE '1_' OR t.hed LIKE '2_' OR t.hed LIKE '3_' OR
	t.hed LIKE '4_' OR t.hed LIKE '5_' OR t.hed LIKE '6_'
       ) GROUP BY t.hed;
       RAISE TOO_MANY_ROWS;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
	null;
      WHEN OTHERS THEN
     	  raise_application_error(
     	  	X.Oops,'Unexpected HED code '||thed||' in timecardRecord');
    END;

    /*
     *	Advance the biweekly pay date to the next period to
     *	reflect that we have loaded this batch.
     */
    UPDATE param SET biweekly_pay=biweekly_pay+14;
  END;


  /*
   *  Load the labor data from table LABOR_LDR and record it for this
   *  period with the necessary canonical fields added to allow common
   *  processing.
   */

  PROCEDURE laborRecord IS

    CURSOR c(qname labor_recorded.name%TYPE) IS
      /*
	     *	Use of Account_string and ORDER BY below was needed only to
	     *	match the algorithm used for the transition.
       *  Reformatted and added account id and order by account id
       *  --yangl Jul/01/04
	     */
	  	SELECT l.rowid ri
	     ,l.pct_orig
	     ,account_string(a.funding,a.function,a.activity,a.org,a.entity,
			     a.project,a.task,a.award,null,null)
	     ,a.id
	  	  FROM labor_recorded l
	     ,accounts a
	  	 WHERE l.name=qname AND l.account=a.id
	  	   AND l.period_last=(SELECT charge_last FROM param)
	  	 ORDER BY l.pct_orig
		,account_string(a.funding,a.function,a.activity,a.org,a.entity,a.project,a.task,a.award,null,null)
		,a.id;

    CURSOR n IS
	  	SELECT name,sum(pct_orig) tpct
	  	  FROM labor_recorded l
	  	 WHERE period_last=(SELECT charge_last FROM param)
	  	 GROUP BY name HAVING SUM(pct_orig) <> 100;


	  npct labor_ldr.pct%TYPE;
	  apct labor_ldr.pct%TYPE;
  BEGIN
  	/*
  	 *  Make sure all loaded labor data is for the current period.
     */
  	DECLARE
  		mperiod labor_ldr.period%TYPE;
  		lperiod param.charge_last%TYPE;
  		fperiod param.charge_first%TYPE;
  	BEGIN
  	DELETE FROM labor_ldr WHERE pct = 0;
	SELECT min(l.period),p.charge_last,p.charge_first
  		  INTO mperiod,lperiod,fperiod
  		  FROM labor_ldr l,param p WHERE l.period < p.charge_first OR l.period > p.charge_last
  		 GROUP BY p.charge_first,p.charge_last;
  		RAISE TOO_MANY_ROWS;
  	EXCEPTION
  		WHEN NO_DATA_FOUND THEN
  		  null;
  		WHEN OTHERS THEN
  		  raise_application_error(
  		    X.oops, 'labor data period '||mperiod||' outside current period '||fperiod||' to '||lperiod);
  	END;

  	/*
  	 *  Make sure all accounts referenced by the labor schedule are defined.
  	 */
  	INSERT INTO accounts (
  	  funding,function,activity,org,entity,
  	  project,task,award
  	)
  	  SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task,l.award
			  FROM labor_ldr l,accounts a
			 WHERE (
			    l.funding=a.funding(+) AND l.function=a.function(+) AND
			    l.activity=a.activity(+) AND l.org=a.org(+) AND l.entity=a.entity(+)
			  ) AND l.funding IS NOT NULL and a.id IS null

			UNION

			SELECT l.funding,l."FUNCTION",l.activity,l.org,l.entity,l.project,l.task,l.award
			  FROM labor_ldr l,accounts a
			 WHERE (
			    l.project=a.project(+) AND l.task=a.task(+) AND l.award=a.award(+)
			  ) AND l.project IS NOT NULL and a.id IS null;
	  IF (SQL%ROWCOUNT > 0) THEN
	  	dbms_output.put_line('Inserted '||SQL%ROWCOUNT||' unknown labor accounts');
	  END IF;

  	INSERT INTO labor_recorded (
  	    period_last, princ, charge_src,
  	    period, name, appointment, home_org,
	objcode, exporg, exptype, account,
	pct_orig, pct_norm
  	  )
    select
                charge_last
                ,princ
                ,nvl(chargesrc, 'Z')
                ,period
                ,name
                ,appointment
                ,home_org
                ,objcode
                ,exporg
                ,exptype
                ,id
                ,pct
                ,pct
      from
    (
        SELECT
                param.charge_last
                ,l.princ
                ,(select unique kind from hostdb.charge_sources where org=ho.org_e and attr like '%P%' and rownum < 2) chargesrc
                ,l.period
                ,l.name
                ,l.appointment
                ,l.home_org
                ,l.objcode
                ,l.exporg
                ,l.exptype
                ,a.id
                ,l.pct
                --,l.pct
          FROM labor_princ l
                ,accounting.hris_org ho
                ,accounts a
                ,param
         WHERE l.home_org=ho.desc1(+)
           AND (l.project,l.task,l.award) IN ((a.project,a.task,a.award))
        UNION ALL
        SELECT
                param.charge_last
                ,l.princ
                ,(select unique kind from charge_sources where org=ho.org_e and attr like '%P%' and rownum < 2) chargesrc
                ,l.period
                ,l.name
                ,l.appointment
                ,l.home_org
                ,l.objcode
                ,l.exporg
                ,l.exptype
                ,a.id
                ,l.pct
                --,l.pct
          FROM labor_princ l
                ,accounting.hris_org ho
                ,accounts a
                ,param
         WHERE l.home_org=ho.desc1(+)
           AND (l.funding,l.function,l.activity,l.org,l.entity)
                IN ((a.funding,a.function,a.activity,a.org,a.entity))
    )
        ;

  	/*
  	 *  Normalize the percentages to sum to 100% for each name.
  	 *  Payroll sends us data which is both sometimes off by
  	 *  +/-.02% and/or which is multiples of 100% probably because
  	 *  of mishandling of multiple appointments.
  	 */
  	FOR nr IN n LOOP
  		apct := 100;
  		FOR r IN c(nr.name) LOOP
  			npct := (r.pct_orig/nr.tpct)*apct;
  			apct := apct - npct;
  			nr.tpct := nr.tpct - r.pct_orig;
  			UPDATE labor_recorded SET pct_norm=npct WHERE rowid=r.ri;

  		  dbms_output.put_line(nr.name||' '||r.pct_orig||'=>'||npct);

  		END LOOP;
  	END LOOP;

  	DECLARE
  		n INTEGER;
  	BEGIN
  	  SELECT count(*) INTO n FROM labor_recorded WHERE period_last=(SELECT charge_last FROM param)
  	   GROUP BY name HAVING sum(pct_norm) != 100;
  	  RAISE TOO_MANY_ROWS;
  	EXCEPTION
  	  WHEN NO_DATA_FOUND THEN
  	     null;
  	  WHEN OTHERS THEN
	  	  raise_application_error(
	  	    X.Oops, 'Labor did not normalize to 100%'
	  	  );
  	END;

  	/*
  	 *  Advance to the first business day of the next month.
  	 */
		DECLARE
		  asof DATE;
		BEGIN
			SELECT labor_dist INTO asof FROM param;
			/* first business day of next month */
      /* asof := busiday(last_day(asof)+1);*/
		  /* change it to the first day of next month instead of
	 business day due to changes on the campus side. --yangl 4/2004
      */
      asof := last_day(asof)+1;
		  /* second business day of next month
		  * asof := busiday(asof+1);
      */
		  UPDATE param SET labor_dist=asof;
		END;

  END;


  /*
   *  Populate the DIST_NAMES_X table based on the current
   *  people data in LABOR_RECORDED, ICES_RECORDED and
   *  TMCD_RECORDED.
   */
  PROCEDURE peopleDistNames(xprinc princ_t) IS
    /*
     *	ORDER BY ensures that 0% rows come first.
     *	added account and order by account
     *	reformatted
     *	--yangl Jul/01/04
     */
    CURSOR c(qprinc people_dist.princ%TYPE) IS
	  	SELECT rowid ri
	     ,pct
	     ,account
	  	 FROM people_dist WHERE princ=qprinc
	  	 ORDER BY pct, account;

    /*
     *	Cursor used to normalize the #0 prototype distribution before it is
     *	identified.  ORDER BY ensures that any 0% rows come first and the
     *	remaining total never falls to zero until the loop is exhausted.  Initial
     *	total of 0% is handled specially.
     *	Added order by account and reformatted
     *	--yangl, Jul/01/04
     */
    CURSOR d IS
      SELECT d.rowid ri
	     ,d.tpct
	     ,d.account
       FROM dist d WHERE d.dist=0
       ORDER BY d.tpct,d.account;

    /*
     *	N.B.  Normalized people distributions are stored with
     *	precision 3 rather than 2 so that applying the precision
     *	2 multiplier stored with the user will recover the original
     *	precision 2 percentage.
     */
	  npct people_dist.pct%TYPE;
	  apct people_dist.pct%TYPE;
	  tpct people_dist.pct%TYPE;
	  did dist_t;
	  src people_dist.charge_src%TYPE;

	  PROCEDURE laborInsert IS
	  BEGIN
	  	INSERT INTO people_dist(
	  	  princ,pct,charge_src,account
	  	)SELECT
	  	  princ,pct_norm,charge_src,account
	  	FROM labor_recorded
	  	WHERE princ IS NOT NULL
	  	  AND period_last=(SELECT charge_last FROM param);
	  END;

	  PROCEDURE otherInsert IS
	    CURSOR p IS
	      SELECT princ FROM people_dist
	      GROUP BY princ HAVING min(charge_src) != max(charge_src);
	  BEGIN
	  	/*
	  	 *  Fill in any new principal mappings which now apply. This
	  	 *  will be relevant if updates are made to the NAME table.
	  	 */
       /* use emp num match first */
     UPDATE tmcd_recorded tr SET
	      princ = (SELECT UNIQUE tp.princ FROM tmcd_princ_new tp
		       WHERE tr.appointment = tp.emp_num)
       WHERE tr.princ is NULL AND tr.appointment IN (
	     SELECT emp_num FROM tmcd_princ_new
	     WHERE  princ IS NOT NULL);

      /* for those not matched using empnum, try fname and lanme. */
      UPDATE tmcd_recorded tr SET
	princ=(SELECT UNIQUE tp.princ FROM tmcd_princ tp
	       WHERE tr.fname=tp.fname AND tr.lname=tp.lname)
       WHERE tr.princ IS NULL AND (tr.fname,tr.lname) IN (
	 SELECT fname,lname FROM tmcd_princ
	  WHERE princ IS NOT NULL
       );
      IF (SQL%ROWCOUNT > 0) THEN
	Util.log('Mapped '||SQL%ROWCOUNT||' new timcard names');
      END IF;

      /*
       * The above update needs to be changed to use SSN/EMP_NUM
       * which follows
       */
/*
     UPDATE tmcd_recorded tr SET
	      princ = (SELECT UNIQUE tp.princ FROM tmcd_princ_new tp
		       WHERE tr.ssn = tp.ssn)
       WHERE tr.princ is NULL AND tr.ssn IN (
	     SELECT ssn FROM tmcd_princ_new
	     WHERE  princ IS NOT NULL);
 */

      IF (SQL%ROWCOUNT > 0) THEN
	Util.log('Mapped '||SQL%ROWCOUNT||' new timcard names');
      END IF;

	  	/*
	  	 *  Add the timecard and ICES people to the people
	  	 *  distribution table.  Any people who already appear in
	  	 *  the table (from labor) take precedence and cause these
	  	 *  entried to be ignored.
	  	 *
	  	 *  Total percentage must be explicitly rounded to precision
	  	 *  2 at this stage since the column is wide enough for
	  	 *  precision 3 normalization that will occur later.
	  	 *
	  	 *  FT = 173.33 hours per month = 100%
         *  FT = 1950 hours per year, according to kzm, July 2007.
	  	 */
	  	INSERT INTO people_dist(
	  	  princ,pct,charge_src,account
	  	)
	  	SELECT /*+ MERGE_AJ*/
	  	  princ,round(sum(hours)/1.625,2),charge_src,account
	  	FROM tmcd_recorded
	  	WHERE princ IS NOT NULL
	  	 AND period_last=(SELECT charge_last FROM param)
	  	 AND princ NOT IN (SELECT princ FROM people_dist)
	  	 GROUP BY princ,charge_src,account;


       --we now get ICES data via labor outload or 3 month interval updates via spreadsheet
	  	/*UNION ALL

	  	SELECT \*+ MERGE_AJ*\
	  	  princ,pct,'e',account
	  	FROM ices_recorded
	  	WHERE period_last=(SELECT charge_last FROM param)
	  	 AND princ NOT IN (SELECT princ FROM people_dist);*/

	  	/*
	  	 *  Adjust the charge source to a composite for any people
	  	 *  coming from multiple sources (min != max).
	  	 */
	  	FOR pr IN p LOOP
		    DECLARE
		      mn people_dist.charge_src%TYPE;
		      mx people_dist.charge_src%TYPE;
		    BEGIN
		    	src := '';
		    	mn:=null;
		    	LOOP
		    		SELECT min(charge_src),max(charge_src) INTO mn,mx
		    		  FROM people_dist
		    		 WHERE princ=pr.princ	AND (
		    		   mn IS NULL OR charge_src > mn
		    		 );
		    		src := src||mn;
		    		EXIT WHEN (mn=mx OR mx IS NULL);
		    	END LOOP;
		    END;
		    BEGIN
		    	UPDATE people_dist SET charge_src=src
		    	 WHERE princ=pr.princ;
		    	Util.log('Composite '||pr.princ||' is '||src);
		    EXCEPTION
		    	WHEN OTHERS THEN
				  	raise_application_error(
				  	  -20198,
				  	  'Composite charge source '''||src||
				  	  ''' must be manually added to charge_sources table for '''||pr.princ
				  	);
		    END;

	  	END LOOP;
	  END;

	BEGIN


		IF (xprinc IS NULL) THEN
			DELETE FROM people_dist;
		  laborInsert;
		  otherInsert;
		END IF;

		/*
		 *  Each user now has exactly one charge source but but we'll
		 *  be paranoid and check anyway since the following loop
		 *  expects one charge source per user.
		 */

		DECLARE
			p people_dist.princ%TYPE;
		BEGIN
			SELECT princ INTO p FROM people_dist
			GROUP BY princ
			 HAVING count(DISTINCT charge_src) > 1;
			RAISE TOO_MANY_ROWS;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			  null;
			WHEN OTHERS THEN
				raise_application_error(
				  X.Oops, 'charge sources not unique in peopleDistNames()'
				);
		END;

	  /*
	   *  This loop can take 4 hours so if anything goes wrong we
	   *  restart where we left off by ignoring any names already
	   *  inserted into dist_names_x.
	   */
	  FOR pr IN (
	    SELECT princ,charge_src,sum(pct) wpct FROM people_dist
       WHERE princ NOT IN (SELECT subname FROM dist_names_x)
	     GROUP BY princ,charge_src HAVING sum(pct) != 0
	  ) LOOP

	  	/*
	  	 *  For testing, we can call this procedure with a specific
	  	 *  prinicipal which will be the only one affected.
	  	 */
			IF (xprinc IS NULL or xprinc =pr.princ) THEN

	      Util.log('Processing '||pr.princ||' '||pr.wpct);

	      /*
	       *  Normalize to 100% before inserting in DIST.
	       */
		  	IF (pr.wpct != 100) THEN
		  	  tpct := pr.wpct;
		  		apct := 100;
		  		FOR r IN c(pr.princ) LOOP
		  			npct := (r.pct/tpct)*apct;
		  			apct := apct - npct;
		  			tpct := tpct - r.pct;
		  			IF (r.pct != npct) THEN
		  			  UPDATE people_dist SET pct=npct WHERE rowid=r.ri;
		  			END IF;
		  			Util.log('Normalize100 '||r.pct||'=>'||npct);
		  		END LOOP;
		  	END IF;

			  /*
	  	   *  Load the distribution table with an initial distribution
	  	   *  based on the people table and with each account appearing
	  	   *  only once.
	  	   *
	  	   *  Use tpct=0 to flag these records at this stage.
	  	   *
	  	   */
	Util.log(to_char(sysdate,'MI:SS')||' before update dist');
	      INSERT INTO dist (dist,account,pct,tpct)
		  	  SELECT 0,l.account,sum(l.pct),0
		  	    FROM people_dist l WHERE l.princ=pr.princ
		GROUP BY l.account
	      ;
	Util.log(to_char(sysdate,'MI:SS')||' after update dist');
		    /*
		     *	Apply account substitutions, first per-user and then
		     *	any user.
		     */
		    IF (true) THEN
	Util.log(to_char(sysdate,'MI:SS')||' before subs dist');
			    UPDATE dist u SET
			account=(SELECT a.dst_account FROM account_subs a
				   WHERE a.princ=pr.princ AND u.account=a.src_account and
 a.src_account IS NOT NULL)
		       WHERE dist=0
			 AND account IN (SELECT a1.src_account FROM account_subs a1
					 WHERE a1.princ=pr.princ AND a1.dst_account IS NOT NULL AND a1.src_account IS NOT NULL);
		      IF (SQL%ROWCOUNT > 0) THEN
		      	Util.log('Substituted '||SQL%ROWCOUNT||' per-user accounts');
		      END IF;


		    	UPDATE dist u SET
		      account=(SELECT a.dst_account FROM account_subs a
				 WHERE a.princ IS NULL AND u.account=a.src_account)
		       WHERE dist=0
			 AND account IN (SELECT src_account FROM account_subs a1
			  WHERE a1.princ IS NULL AND dst_account IS NOT NULL);
		      IF (SQL%ROWCOUNT > 0) THEN
		      	Util.log('Substituted '||SQL%ROWCOUNT||' any user accounts');
		      END IF;
	Util.log(to_char(sysdate,'MI:SS')||' after subs dist');
	      END IF;

	      /*
	       *  Re-insert the new distribution with any new common accounts summed.  The
	       *  real distribution now has column tpct!=0 and pct=0.
	       */
	Util.log(to_char(sysdate,'MI:SS')||' before re-insert');
	      INSERT INTO dist (dist,account,pct,tpct)
	       SELECT 0,account,0,sum(pct)
		FROM dist WHERE dist=0 AND tpct = 0
		GROUP BY account;
	Util.log(to_char(sysdate,'MI:SS')||' after re-insert');

	      /*
	       *  Apply account removals by zeroing tpct as appropriate.  We can't delete
	       *  rows outright since that might violate the sum(pct)=100% invariant.
	       */
	      IF (true) THEN
	Util.log(to_char(sysdate,'MI:SS')||' before subs removals');
			    UPDATE dist SET tpct=0 WHERE dist=0
			     AND account IN (SELECT acs.src_account FROM account_subs acs
					      WHERE acs.dst_account IS NULL and acs.princ =pr.princ );
		      IF (SQL%ROWCOUNT > 0) THEN
			Util.log('Removed '||SQL%ROWCOUNT||' per-user accounts');
		      END IF;


		      UPDATE dist SET tpct=0 WHERE dist=0
			AND account IN (SELECT acs.src_account FROM account_subs acs
					 WHERE acs.dst_account IS NULL AND acs.princ IS NULL);
		    	IF (SQL%ROWCOUNT > 0) THEN
		      	Util.log('Removed '||SQL%ROWCOUNT||' any user accounts');
		    	END IF;
	Util.log(to_char(sysdate,'MI:SS')||' after subs removals');
	    	END IF;
	      /*
	       * Re-normalize the new distribution (in tpct).
	       */
	  		SELECT sum(d.tpct) INTO tpct FROM dist d WHERE d.dist=0;
		    apct := 100;
	  		IF (tpct != 0) THEN
		  		FOR dr IN d LOOP
		  			IF (dr.tpct != 0) THEN
			  			npct := (dr.tpct/tpct)*apct;
			  			/*
			  			 *  Only precision 2 unless this is not a full user
			  			 *  which will need to muliply back out properly.
			  			 */
			  			IF (pr.wpct = 100) THEN
			  				npct := round(npct,2);
			  			END IF;
			  			apct := apct - npct;
			  			tpct := tpct - dr.tpct;
			  			IF (npct != dr.tpct) THEN
				  			UPDATE dist SET tpct=npct WHERE rowid=dr.ri;
			  			END IF;
				  		Util.log('Normalize '||dr.tpct||'=>'||npct);
		  		  END IF;
		  		END LOOP;

		  		/*
		  		 *  Now apply the normalized distribution from tpct to pct in one step
		  		 *  so that the invariant holds and then remove any records set to 0.
		  		 */
		      UPDATE dist SET pct=tpct WHERE dist = 0;
	  		END IF;

	      DELETE FROM dist WHERE dist=0 AND tpct=0;

		    /*
		     *	Remaining actual percentage remains at 100 if total was 0, otherwise is
		     *	decreased to 0 by the normalization.
		     */
	      IF (apct = 0) THEN
			  	did := Integrity.distIdentify;
			  	Util.log(pr.princ||' ('||pr.charge_src||') has distribution '||did);
			  	IF (pr.princ IS NOT NULL) THEN
			  	  distDefine(Integrity.ProjectPseudoEffort,pr.princ,did,pr.charge_src,pr.wpct);
			  	  commit;
			  	END IF;
	      END IF;

			END IF;
	  END LOOP;

	  /*
	   *  No payroll based charging takes effect unless the user
	   *  is currently being charged.  People (especially students)
	   *  sometimes return to payroll without resuming use of their
	   *  computer account and an account not expecting any computer
	   *  support gets charged.
	   *  If they do resume use of their account, then a charge
	   *  will have been set manually to enable it and the
	   *  automatic override from payroll data is then okay.
	   */
	  DECLARE
	  	ppe dist_names.name%TYPE;
	  BEGIN
	  	ppe := Integrity.ProjectPseudoEffort;
		  DELETE /*+ MERGE_AJ*/ FROM dist_names_x
		   WHERE name=ppe AND subname NOT IN (
		SELECT princ FROM who WHERE dist IS NOT NULL);
		Util.log('Purged '||SQL%ROWCOUNT||' effort mappings with no current charging');
	  END;

	  /*
	   *  Advance the processing date to next month.  It  doesn't
	   *  matter exactly which date is used here since
	   *  this procedure is not called unless the Makefile has
	   *  succeeded loading the ICES, labor and timecard
	   *  prerequisites.  We choose to use the same day as labor
	   *  is due (already advanced to next month when we are
	   *  called) since that process can succeed no earlier than
	   *  this.
	   */
		UPDATE param SET dist_named=labor_dist;
  END;


  /*
   *  Apply the distribution names in DIST_NAMES_X to the
   *  db.  Commit on each name since the process
   *  may generate lots of updates and thrash rollback
   *  segments.
   */
  PROCEDURE peopleDistNamesApply IS
    pe dist_names_x.name%TYPE;
  BEGIN
  	pe := Integrity.ProjectPseudoEffort;
  	FOR r IN (
  	  SELECT d.dist odist,d.src osrc,d.pct opct,
  		 x.dist ndist,x.src nsrc,x.pct npct,
  		 x.name,x.subname
  	    FROM dist_names_x x,dist_names d
  	   WHERE x.name=pe
  	     AND x.name=d.name(+) AND x.subname=d.subname(+)
    ) LOOP
    	IF (r.odist=r.ndist AND r.osrc=r.nsrc AND r.opct=r.npct) THEN
    		Util.log('Unchanged '||r.subname);
    	ELSE
		UPDATE dist_names SET
    		  dist=r.ndist,src=r.nsrc,pct=r.npct
    		WHERE (name,subname) IN ((r.name,r.subname));
		IF (SQL%ROWCOUNT = 0) THEN
		    INSERT INTO dist_names(name,subname,src,pct,dist)
		    VALUES (r.name,r.subname,r.nsrc,r.npct,r.ndist);
		    Util.log ('Insert '||r.subname||' to '||r.ndist||','||
		       r.nsrc||',' ||r.npct||'%');
		ELSE
		    Util.log ('Update '||r.subname||' to '||r.ndist||','||
		       r.nsrc||',' ||r.npct||'%');
		END IF;
    	END IF;
    END LOOP;
   COMMIT;

    /*
     *	Remove effort mappings for people no longer defined
     *	or summed to zero.
     */
    FOR r IN (
      SELECT /*+ MERGE_AJ*/ subname FROM dist_names d
       WHERE d.name=pe AND d.subname NOT IN
	 (SELECT subname FROM dist_names_x WHERE name=pe)
      UNION
      SELECT princ FROM people_dist GROUP BY princ
       HAVING sum(pct) =0
    ) LOOP
    	DELETE FROM dist_names WHERE name=pe AND subname=r.subname;
    	Util.log('Purge person '||r.subname||' '||SQL%ROWCOUNT);
    END LOOP;

    /*
     *	Remove distributions for people zeroed in effort who went to
     *	residual status from the above purge.
     */
    -- This does not make sense. comment out.
    -- User accounts should be charged unless it is expired explicitly.
    --FOR r IN (
    --  SELECT princ FROM people_dist GROUP BY princ
    --   HAVING sum(pct) =0

    --) LOOP
    --	UPDATE who SET dist=null,dist_src=null,pct=null
    --	 WHERE princ=r.princ AND dist_src='X';
    --	Util.log('Zero person '||r.princ||' '||SQL%ROWCOUNT);
    --END LOOP;

      /*
       *  Advance the processing date to next month.  It  doesn't
       *  matter exactly which date is used as above.
       */
	UPDATE param SET names_apply=labor_dist;

  END;


  PROCEDURE depreciate(
    qjournal journal_t,qpost_date DATE, monyear VARCHAR2
  ) IS
  /*
    CURSOR d IS
      SELECT amount,trans_date,left,years,description FROM depreciation
      FOR UPDATE;

    until NUMBER;
    asof NUMBER;
    now date;
    already NUMBER;
    installments NUMBER;
    INSTALLMENTS_MAX NUMBER := 4;
    damount depreciation.amount%TYPE;
    jdesc journal.description%TYPE := 'SCS Monthly Computer Equipment Depreciation ';

    FUNCTION toMonths(d DATE) RETURN NUMBER IS
    BEGIN
    	RETURN ((TO_NUMBER(TO_CHAR(d, 'YYYY'))*12)+TO_NUMBER(TO_CHAR(d, 'MM')) -1);
    END;
   */

  BEGIN
    /*
     * credit accumulated depreciation
     * DEC 5/2/02 modified per Jim Gartner (Accounting) request:
     * The offsetting credit needs to hit 87952.090199.510.000.000001.01
     * as opposed to 68200.055000.000.204.270112.01 where it had been
     * being booked...
     * DEC 9/27/02 modified to obtain depreciation from
     * depreciation_rate table rather than calculation
     * based on obsolete data
     *
    until := toMonths(qpost_date);

	  UPDATE depreciation SET amount_deprec=0;
  	FOR dr IN d LOOP
  	   *
       *  Two or more installments the first time since the data comes in at
       *  least a month late.
       *

	    IF (dr.years > 0) THEN
		already := (12*dr.years);
		already := already - dr.left;
	    ELSE
		already := 0;
	    END IF;
	    asof := toMonths(dr.trans_date);
	    installments := until-asof+1;
	    installments := installments - already;
      IF (installments > INSTALLMENTS_MAX) THEN
	raise_application_error(
	   X.TOO_MANY_INSTS,' too many installments calculated for '||
	   dr.description||': '||installments||' > '||INSTALLMENTS_MAX
	);
      END IF;
      DBMS_OUTPUT.put_line('date '||to_char(dr.trans_date,'dd-mon-yyyy')||'
 already '||already||', left '||dr.left||', asof '||asof||', until '||until||', insts '||installments);

      damount := dr.amount*installments/dr.left;
      dr.amount := dr.amount - damount;
      dr.left := dr.left-installments;

      *
      Util.log('Deprec '||damount||', already '||already||', left '||dr.left||', asof '||asof||', until '||until||', insts '||installments);
      *

      UPDATE depreciation SET
	left_next=dr.left,amount_next=dr.amount,
	amount_deprec=damount
       WHERE CURRENT OF d;
  	END LOOP;
    *
    *
		INSERT INTO journal(journal,objcode,account,post_date,amount,description)
		 SELECT qjournal,'87952',5039,qpost_date,0-sum(d.amount_deprec),
		 jdesc||monyear
		  FROM depreciation d;
		Util.log('Journaled accumulated depreciation credit');

		INSERT INTO journal(journal,objcode,account,post_date,amount,description)
		 SELECT qjournal,'87952',4796,qpost_date,sum(d.amount_deprec),
		 jdesc||monyear
		  FROM depreciation d;
		Util.log('Journaled depreciation expense');
     *
		 *  These two entries log a net 0 expense to breakdown
		 *  depreciation by category for future expense analysis
		 *  just as with the host and user services.

		* log GL credit to offset debit we have just posted *
		INSERT INTO expense(journal,objcode,post_date,amount,category,description,catbyprinc)
     SELECT qjournal,'87952',qpost_date,
		       0-sum(d.amount_deprec), 'CO',
		       jdesc||monyear,
		       'costing'
		  FROM depreciation d;
		Util.log('Logged depreciation credit');
		 log depreciation expenses by category
		INSERT INTO expense(journal,objcode,post_date,amount,category,description,catbyprinc)
		 SELECT qjournal,'87952',qpost_date, sum(d.amount_deprec),
			c.name,c.description,'costing'
		   FROM depreciation d,categories c
		  WHERE d.category =c.name
		  GROUP BY c.name,c.description;
		Util.log('Logged depreciation expenses by category');
  END;
     */

    INSERT INTO journal(journal,objcode,account,post_date,amount,description)
		 SELECT qjournal,d.objcode,d.account_cr,qpost_date,0-sum(d.amount_deprec),
		 d.description||monyear
		  FROM depreciation_rate d
      where period_begin <= qpost_date
      and period_end is null
      group by d.objcode,d.account_cr,d.description;
		Util.log('Journaled accumulated depreciation credit');

    /* debit depreciation expense */
    INSERT INTO journal(journal,objcode,account,post_date,amount,description)
		 SELECT qjournal,d.objcode,d.account_dr,qpost_date,sum(d.amount_deprec),
		 d.description||monyear
		  FROM depreciation_rate d
      where period_begin <= qpost_date
      and period_end is null
      group by d.objcode,d.account_dr,d.description;
		Util.log('Journaled depreciation expense');
		/*
		 *  These two entries log a net 0 expense to breakdown
		 *  depreciation by category for future expense analysis
		 *  just as with the host and user services.
		 */

		/* log GL credit to offset debit we have just posted */
		INSERT INTO expense(journal,objcode,post_date,amount,category,description,catbyprinc)
     SELECT qjournal,d.objcode,qpost_date,
		       0-sum(d.amount_deprec), 'CO',
		       d.description||monyear,
		       'costing'
		  FROM depreciation_rate d
      where period_begin <= qpost_date
      and period_end is null
      group by d.objcode,d.description;
		Util.log('Logged depreciation credit');
		/* log depreciation expenses by category
     *
     * as of 27-SEP-2002 only category is network support
     * depreciation_rate table can be updated to breakdown
     * depreciation by more categories if needed
     */
		INSERT INTO expense(journal,objcode,post_date,amount,category,description,catbyprinc)
		 SELECT qjournal,d.objcode,qpost_date, sum(d.amount_deprec),
			c.name,c.description,'costing'
		   FROM depreciation_rate d,categories c
		  WHERE d.category =c.name
      and period_begin <= qpost_date
      and period_end is null
		  GROUP BY d.objcode,c.name,c.description;
		Util.log('Logged depreciation expenses by category');
  END;


  PROCEDURE journalRecord(recapture BOOLEAN, qjournal journal_t) IS
    monyear VARCHAR2(8);
  	qpost_date DATE;
    -- Use new object code starting from FY08.
    l_rev_objcode hostdb.journal.objcode%TYPE := '88280';
    l_exp_objcode hostdb.journal.objcode%TYPE := '68280';

    PROCEDURE capture_purge(qjournal journal_t) IS
    BEGIN
    /*
     *	Purge the staging dist_names_x table now that we know they have
     *	all been applied.
     */
    DELETE FROM dist_names_x;
    Util.log('Purged '||SQL%ROWCOUNT||' dist_names_x records');
	  	DELETE from host_charged
	  	 WHERE journal=qjournal;
	  	Util.log('Purged '||SQL%ROWCOUNT||' obsolete host_charged records');
	  	DELETE FROM who_charged
	  	 WHERE journal=qjournal;
	  	Util.log('Purged '||SQL%ROWCOUNT||' obsolete who_charged records');
	  END;

  	PROCEDURE capture (qjournal journal_t) IS
  	BEGIN
	    LOCK TABLE who IN SHARE MODE;
	    LOCK TABLE name IN SHARE MODE;
	    LOCK TABLE principal IN SHARE MODE;
	    LOCK TABLE hoststab IN SHARE MODE;
	    LOCK TABLE machtab IN SHARE MODE;
	    LOCK TABLE capequip IN SHARE MODE;
	    LOCK TABLE host_service IN SHARE MODE;
	    LOCK TABLE host_service_charge IN SHARE MODE;
	    LOCK TABLE who_service IN SHARE MODE;
	    LOCK TABLE who_service_charge IN SHARE MODE;
	    /* DEC 05/31/02 commented out obsolete code:
      LOCK TABLE who_adjust_charge IN SHARE MODE;
      LOCK TABLE host_adjust_charge IN SHARE MODE;
	    */

        unlimbo_all_sc;

      /*
	     *	Synchronize the host_recorded table with current
	     *	state of machines, creating new records for any
	     *	missing combinations.
	     */
	    INSERT INTO host_recorded (
	       assetno,hostname,cpu,qual,charge_src,os,location,
	       project,subproject,prjprinc,usrprinc,princ
	     ) SELECT UNIQUE
		 h.assetno,h.hostname,h.cpu,h.qual,h.charge_src,
		 h.os,h.location,h.project,h.subproject,
	   h.prjprinc,h.usrprinc,h.princ
	 FROM hostsrec h
	 WHERE h.assetno IN (select assetno FROM host_service)
	   AND h.hr_id IS NULL;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' new host_recorded records');

		  /*
		   *  Update host record id's in the host_service table to
		   *  reflect the current state of machines.  Priority
		   *  999999 is for pass through charges and will match
		   *  no priority in hostsrec so we allow it specially.  It
		   *  will get assigned to the minimum id for the host among
		   *  all its priorities.
		   */
		  Util.log('Begin host_service ID updates');
      FOR r IN (
	SELECT min(hr.hr_id) nid,hs.assetno,hs.pri,hs.hr_id oid
	FROM hostsrec hr,host_service hs
	WHERE hs.assetno=hr.assetno
	AND (hs.pri=hr.pri OR hs.pri=999999)
	GROUP BY hs.assetno,hs.pri,hs.hr_id
	HAVING min(hr.hr_id) != nvl(hs.hr_id,-1)
      ) LOOP
	UPDATE host_service SET hr_id=r.nid WHERE assetno=r.assetno AND pri=r.pri;
	Util.log('ID '||r.nid||' from '||r.oid||' for '||r.assetno||','||r.pri||' ('||SQL%ROWCOUNT||')');
      END LOOP;
		  Util.log('End host_service ID updates');

	    /*
	     *	Capture host services and mark any which were non-monthly
	     *	as belonging to this journal.
	     */
	  	INSERT INTO host_charged (
			    hr_id,pct,hpct,charge,amount, trans_date,
			    service_id,account,account_flag,journal
	  ,creation_date,created_by
			)	SELECT hs.hr_id,hsc.pct,hs.pct hpct,
			       hsc.charge,hsc.amount,nvl(hs.trans_date,j.post_date),
			       hs.service_id,hsc.account
                    ,a.flag account_flag
                    ,qjournal
	                ,sysdate, 'Monthly JE'
			 FROM host_service hs,host_service_charge hsc,accounts a,
			      journals j
			WHERE hs.assetno=hsc.assetno AND hs.pri=hsc.pri
			  AND hs.service_id=hsc.service_id
			  AND hsc.account=a.id AND j.id=qjournal;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' host_charged service records');

	  	UPDATE host_service SET journal=qjournal
	  	 WHERE service_id IN (SELECT id FROM services WHERE monthly IS NULL);
	  	Util.log('Logged '||SQL%ROWCOUNT||' non-monthly host services');

	    /*
	     *	Capture host adjustments and mark as belonging to this journal.
	     *	DEC 5/31/02 commented out obsolete code

	    INSERT INTO host_charged (
			    hr_id,pct,hpct,charge,amount, trans_date,
			    service_id,account,account_flag,notes,journal
			)	SELECT c.hr_id,c.pct,c.hpct,
			       c.charge,c.amount,c.trans_date,
			       c.service_id,c.account,a.flag,c.notes,
			       qjournal
			 FROM host_adjust_charge c,accounts a
			 WHERE c.account=a.id;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' host_charged adjustment records');

	    UPDATE host_adjust_charge SET journal=qjournal;
	  	Util.log('Logged '||SQL%ROWCOUNT||' host adjustments');
     */
			/*
			 *  Flag any accounts in LIMBO so that they do not generate
			 *  host charges.
       *  DEC 05/2/02 - commented out as "l" qualifier means
       *  loaner equipment rather than "LIMBO"

			UPDATE host_charged SET account_flag='l'
			 WHERE hr_id IN (
			   SELECT hr.id FROM host_recorded hr,capequip c
			    WHERE hr.assetno=c.assetnum AND c.qual='l'
			   )
			 AND account_flag IS NULL AND journal=qjournal;
	  	Util.log('Adjusted '||SQL%ROWCOUNT||' hosts in limbo');
      */
			/*
	     *	Synchronize the who_recorded table with current
	     *	state of users, creating new records for any
	     *	missing combinations.
	     */
	    INSERT INTO who_recorded (
	       princ,name,charge_src,project,subproject,sponsor
	     ) SELECT UNIQUE
		 w.princ,w.name,w.charge_src,w.project,w.subproject,
		 w.sponsor
	 FROM whorec w
	 WHERE w.princ IN (select princ FROM who_service)
	   AND w.wr_id IS NULL;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' new who_recorded records');

	    /*
		   *  Update person record id's in the who_service table to
		   *  reflect the current state of machines.
		   */
		  Util.log('Begin who_service ID updates');
      FOR r IN (
	SELECT min(wr.wr_id) nid,ws.princ,ws.wr_id oid
	FROM whorec wr,who_service ws
	WHERE ws.princ=wr.princ
	GROUP BY ws.princ,ws.wr_id
	HAVING min(wr.wr_id) != nvl(ws.wr_id,-1)
      ) LOOP
	UPDATE who_service SET wr_id=r.nid WHERE princ=r.princ;
	Util.log('ID '||r.nid||' from '||r.oid||' for '||r.princ||' ('||SQL%ROWCOUNT||')');
      END LOOP;
		  Util.log('End who_service ID updates');

	    /*
	     *	Capture user services and mark any which were non-monthly
	     *	as belonging to this journal.
	     */
	    INSERT INTO who_charged (
			    wr_id,pct,charge,amount,trans_date,
			    service_id,account,account_flag,journal
	  ,creation_date,created_by
			)	SELECT
			       ws.wr_id,sc.pct,sc.charge,sc.amount,nvl(ws.trans_date,j.post_date),
			       ws.service_id,sc.account
                    ,a.flag account_flag
                    ,qjournal
	                ,sysdate,'Monthly JE'
			 FROM who_service ws,who_service_charge sc, accounts a,
			      journals j
			WHERE  ws.princ=sc.princ AND ws.service_id=sc.service_id
			  AND sc.account=a.id AND j.id=qjournal;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' who_charged records');

	  	UPDATE who_service SET journal=qjournal
	  	 WHERE service_id IN (SELECT id FROM services WHERE monthly IS NULL);
	  	Util.log('Logged '||SQL%ROWCOUNT||' non-monthly user services');

	    /*
	     *	Capture user adjustments and mark as belonging to this journal.
	     *	DEC 5/31/02 commented out obsolete code

	  	INSERT INTO who_charged (
			    wr_id,pct,charge,amount, trans_date,
			    service_id,account,account_flag,notes,journal
			)	SELECT c.wr_id,c.pct,
			       c.charge,c.amount,c.trans_date,
			       c.service_id,c.account,a.flag,c.notes,
			       qjournal
			 FROM who_adjust_charge c,accounts a
			 WHERE c.account=a.id;
	  	Util.log('Inserted '||SQL%ROWCOUNT||' who_charged adjustment records');

	    UPDATE who_adjust_charge SET journal=qjournal;
	  	Util.log('Logged '||SQL%ROWCOUNT||' user adjustments');
      */
	  	/*
	  	 *  Release all those locks as soon as we have a consistent
	  	 *  capture.
	  	 */

      /*
       *  Advance the processing date to next month.  It  doesn't
       *  matter exactly which date is used as above.
       */
	UPDATE param SET journal_entry=labor_dist;
	  	COMMIT;
  	END;

  BEGIN
  	/*
  	 *  Just in case two processes try to generate a journal at once.  Shouldn't
  	 *  happen.
  	 */

  	LOCK TABLE param IN SHARE MODE;

  	IF (recapture) THEN
  		capture_purge(qjournal);
  	END IF;


  	DELETE FROM journal WHERE journal = qjournal;
    Util.log('Purged '||SQL%ROWCOUNT||' obsolete journal records');
    DELETE FROM expense WHERE journal =	qjournal;
    Util.log('Purged '||SQL%ROWCOUNT||' obsolete expense records');
  	/*
  	 *  All references to the current working journal are now purged
  	 *  (assuming recapture).
  	 */

  	IF (recapture) THEN
		  /*
		   *  Capture the charging information for hosts and users.
		   */
	  Util.log('recapture journal='||qjournal);
  	  capture(qjournal);
	ELSE
	    /*
	     *	Update any account flags in the charge records to reflect
	     *	accounts now in limbo (i.e. as a result of the journal
	     *	being rejected).
	     */
	    UPDATE host_charged hc SET
		hc.account_flag=(SELECT a.flag FROM accounts a WHERE a.id=hc.account)
	    WHERE hc.journal=qjournal AND account_flag IS NULL
	    AND hc.account IN (select a.id FROM accounts a WHERE a.flag is NOT NULL);
	    Util.log('Adjusted '||SQL%ROWCOUNT||' account flags in host_charged');
	    UPDATE who_charged wc SET
		wc.account_flag=(SELECT a.flag FROM accounts a WHERE a.id=wc.account)
	    WHERE wc.journal=qjournal AND account_flag IS NULL
	    AND wc.account IN (select a.id FROM accounts a WHERE a.flag is NOT NULL);
	    Util.log('Adjusted '||SQL%ROWCOUNT||' account flags in who_charged');
  	END IF;

  	/*
  	 *  Just in case two processes try to generate a journal at once.  Shouldn't
  	 *  happen.  The capture processes commits and releases locks so
  	 *  they must be reobtained here.
  	 */
  	LOCK TABLE param IN SHARE MODE NOWAIT;
  	LOCK TABLE host_charged IN SHARE MODE NOWAIT;
  	LOCK TABLE who_charged IN SHARE MODE NOWAIT;

  	SELECT to_char(post_date,'Mon-YYYY'),post_date
  	  INTO monyear,qpost_date
  	  FROM journals j WHERE j.id=qjournal;

  	insert into journal(
  	  journal,objcode,account,amount,post_date,description
      ,creation_date,created_by
  	)select qjournal,l_rev_objcode,c.account,sum(c.amount),qpost_date,
		       count(distinct hr.assetno)||' machines'
	   ,sysdate,'Monthly JE'
		 from host_charged c,host_recorded hr
		 WHERE c.journal=qjournal AND c.account_flag IS NULL
		   AND hr.id=c.hr_id
		 group by c.account;
    Util.log('Journaled '||SQL%ROWCOUNT||' machine records');
		UPDATE journal SET description='1 machine'
		 WHERE journal = qjournal AND description='1 machines';

		insert into journal(
		  journal,objcode,account,amount,post_date,description
      ,creation_date,created_by
		)	select qjournal,l_rev_objcode,c.account,sum(c.amount),qpost_date,
		       count(distinct wr.princ)||' users'
	   ,sysdate,'Monthly JE'
		 from who_charged c,who_recorded wr
		 where c.journal=qjournal and c.account_flag is null
		   AND wr.id=c.wr_id
		 group by c.account;
    Util.log('Journaled '||SQL%ROWCOUNT||' user records');

		UPDATE journal SET description='1 user'
		 WHERE journal = qjournal AND description='1 users';

		/*
		 *  Augment descriptions with commin prefix for the month.
		 */

		UPDATE journal SET description='SCS Monthly Computer Maintenance '||monyear||': '||description
		 WHERE journal=qjournal;

	  /*
	   *  The following 4 statements add a net 0 amount to the expense
	   *  table.  The logged expenses will be offset by the credits this
	   *  journal is posting when the GL expense data for this journal
	   *  is loaded into the expense table.  This leaves the amount of the
	   *  revenue credits reflected in the totals by category
	   *  breakdown (what we need for rate analysis) rather than just
	   *  a lump sum.
	   */

		/* log GL expense to offset credit we have just posted */
		INSERT INTO expense(
		  journal,objcode,post_date,amount,category,description,catbyprinc
		) SELECT qjournal,l_exp_objcode,qpost_date,
		       sum(j.amount), 'CO',
		       'SCS Monthly Computer Maintenance '||monyear|| ' (GL)',
		       'costing'
		  FROM journal j,accounts a,param p
		  WHERE j.journal=qjournal AND j.account=a.id
		    AND a.funding IS NOT NULL;
		Util.log('Logged GL expense');
		/* log GM expense to offset credit that will be implicitly posted back */
		INSERT INTO expense(journal,objcode,post_date,amount,category,description ,catbyprinc)
		 SELECT qjournal,l_exp_objcode,qpost_date,
		       sum(j.amount), 'CO',
		       'SCS Monthly Computer Maintenance '||monyear|| ' (GM)',
		       'costing'
		  FROM journal j,accounts a
		  WHERE j.journal=qjournal AND j.account=a.id
		    AND a.funding IS NULL;
		Util.log('Logged GM expense');

		/* log user revenue by category */
		INSERT INTO expense(journal,objcode,post_date,amount,category,description ,catbyprinc)
		 SELECT qjournal,l_exp_objcode,qpost_date, 0-sum(wc.amount),
			c.name,c.description||' (users)','costing'
		   FROM who_charged wc,categories c,services s
		  WHERE wc.service_id = s.id AND s.category=c.name
		    AND wc.journal = qjournal
		    AND wc.account_flag IS NULL
		  GROUP BY c.name,c.description ;
		Util.log('Logged user revenue by category');
		/* log host revenue by category */
		INSERT INTO expense(journal,objcode,post_date,amount,category,description ,catbyprinc)
		 SELECT qjournal,l_exp_objcode,qpost_date, 0-sum(hc.amount),
			c.name,c.description||' (machines)','costing'
		   FROM host_charged hc,categories c,services s
		  WHERE hc.service_id = s.id AND s.category=c.name
		    AND hc.journal = qjournal
		    AND hc.account_flag IS NULL
		  GROUP BY c.name,c.description;
		Util.log('Logged host revenue by category');

		/*
		 *  Journal the equipment depreciation
		 */

		depreciate(qjournal,qpost_date,monyear);

		/*
		 *  credit GL revenue
		 *
		 *  this must follow the summaries above since it produces a
		 *  net zero GL sum.  Since depreciation doesn't currently
		 *  affect any GM accounts and is net zero to GL, it doesn't
		 *  have to follow that but it seems best for the future.
		 */
		INSERT INTO journal(
		  journal,objcode,account,post_date,amount,description
      ,creation_date,created_by
		)
		 SELECT qjournal,l_exp_objcode,11685,qpost_date,0-sum(j.amount),
		 'SCS Monthly Computer Maintenance '||monyear
     ,sysdate,'Monthly JE'
		  FROM journal j,accounts a
		  WHERE j.journal=qjournal AND j.account=a.id AND funding IS NOT NULL;
    Util.log('Journaled GL revenue');

  END;


  PROCEDURE journalRecord(recapture BOOLEAN) IS
    journal journal_t;
  BEGIN
  	/*
     * DEC 04.10.2003
     * former query  "SELECT journal INTO journal FROM param"
     * couldn't guarantee an an available journal id so a
     * view is used to retrieve a more reliable id
  	 */
    /*
     * SELECT journal INTO journal FROM param;
  	 * DEC 04.10.2003
     * Update journals
     * couldn't guarantee an an available journal id so a
     * view is used to retrieve a more reliable id
  	 */
    journal := get_open_je;
    UPDATE JOURNALS
    SET Journal_Type_Flag = 'M'
    , JE_IN_PROCESS_FLAG = 'Y'
    WHERE  id = journal;
    /* Commit here to mark this journal id as in process: */
    Commit;
    /* pass journal id to overloaded journalRecord proc: */
  	journalRecord(recapture, journal);
  END;


  PROCEDURE journalRecord IS
  BEGIN
  	journalRecord(true);
  END;

  /*
   *  Confirm that the pending journal entry has been accepted
   *  by accounting.
   */

  PROCEDURE journalAccepted IS
    n NUMBER(4);
    jnum journal_t;
    errdesc	   varchar2(50);
    retcode	   varchar2(50);
  BEGIN
	/*
	 *  Make sure we actually have a journal entry to accept.
   *  DEC 04.10.2003 - use view rather than param journal
   *  which may not yield an available journal id.
   *
   */
	jnum := get_open_je;
  SELECT COUNT(*) INTO n FROM journal
  WHERE journal = jnum;
	IF (n = 0) THEN
     	  raise_application_error(
     	  	X.Oops,'No journal entry has been recorded to accept'
	  );
	END IF;

  	/*
  	 *  Purge pass-thru host and user services and adjustments
  	 *  that were booked this month in this journal.
  	 */
  	DELETE FROM host_service
  	 WHERE journal IN (SELECT journal FROM param);
	  Util.log('Removed '||SQL%ROWCOUNT||' non-monthly host_service records');
  	DELETE FROM who_service
  	 WHERE journal IN (SELECT journal FROM param);
	  Util.log('Removed '||SQL%ROWCOUNT||' non-monthly who_service records');
    /* DEC 05/31/02 commented out obsolete code
  	DELETE FROM host_adjust_charge
  	 WHERE journal IN (SELECT journal FROM param);
	  Util.log('Removed '||SQL%ROWCOUNT||' host_adjust_charge records');
	  DELETE FROM who_adjust_charge
  	 WHERE journal IN (SELECT journal FROM param);
	  Util.log('Removed '||SQL%ROWCOUNT||' who_adjust_charge records');
    */
	  /*
	   *  Advance the depreciation schedule to reflect depreciation
	   *  booked this month.
	   */
	  UPDATE depreciation SET amount=amount_next,left=left_next;

    /* Set the journal type flag and null in_process flag
     * to indicate an accepted and posted monthly batch
     */
    UPDATE JOURNALS
    SET JOURNAL_TYPE_FLAG = 'M',
	JE_IN_PROCESS_FLAG = NULL
    WHERE  id = jnum;

	  /*
	   *  Remove the 0% labor entries from the ICES distribution
	   *  schedule used to flag an immediate account termination
	   *  rather than the normal residual processing.
	   */
	  DELETE FROM ices_ldr WHERE pct=0;
	  Util.log('Purged '||SQL%ROWCOUNT||' zero ICES records');

	  /*
	   *  Advance the journal number and period start and end dates.
	   *  DEC 04.10.2003 - increment max id from journals rather
     *	than journal in param which is less reliable given different
     *	types of journals (e.g., monthly vs ad hoc adjustments
     */
	  UPDATE param SET
	    journal=(select max(id)+1 FROM journals),
	    charge_first=last_day(charge_first)+1,
	    charge_last=last_day(charge_last+1);

    /*
     *	Create the journal parameters for next month
     */
	  INSERT INTO journals (id, post_date)
		  SELECT p.journal,p.charge_last FROM param p;

    /*
     *	Revise the warranty services for any equipment which is
     *	now out of warranty based on the new charge period just
     *	established by forcing the service trigger to
     *	fire.
     */
    UPDATE capequip SET warranty_expire=warranty_expire
     WHERE assetnum IN (
       SELECT assetnum FROM capequip,param,host_service
	WHERE warranty_expire <= charge_last AND assetnum=assetno
	  AND service_id IN (
	     SELECT id FROM services
	      WHERE type='M' AND subtype='R' AND other ='warranty'
	   )
	);
	  Util.log('Updated '||SQL%ROWCOUNT||' now non-warranted assets');

    /*
     * Update the GL_REPORT table to insert new journal charges
     *   including service codes.
     */
     hostdb.gl_report_add_charges ( jnum ) ;

  END;

  /* Unmark accounts marked as limbo yet appear
     in valid account tables */
  PROCEDURE unLimbo IS
  BEGIN
    -- not unlimbo GM strings to keep the month-end status during the month. 200804
    --update hostdb.accounts
	-- set flag = NULL
	-- where (project,task,award) in (
	-- select project, task, award
	-- from accounting.gm_combos)
	-- and flag = 'l';

    update hostdb.accounts
	 set flag = NULL
	 where (funding,function,org,activity,entity) in (
	 select funding, function, org,activity,entity from accounting.gl_combos)
	 and flag = 'l'
     and nvl(function,'111')!='000';
   END unLimbo;

    procedure unlimbo_all_sc is
    begin
        update accounts
           set flag=null
         where flag='l'
           and nvl(function, '111') != '000'
           and id in (select account from host_service_charge);

	    Util.log('unlimbo-ed '||SQL%ROWCOUNT||' host charge accounts');
        update accounts
           set flag=null
         where flag='l'
           and nvl(function, '111') != '000'
           and id in (select account from who_service_charge);

	    Util.log('unlimbo-ed '||SQL%ROWCOUNT||' who charge accounts');
    end unlimbo_all_sc;

   FUNCTION get_open_je
   RETURN journal_t IS
	  jnum journal_t;
   BEGIN
   select min(journal) into jnum
   from open_journals_v
   where owner = 'M'
   or owner is null;
   if jnum is null then
      select max(id)+1 into jnum from journals;
      update param
      set journal = jnum;
      commit;
      insert into journals
      (id, post_date)
      select journal, charge_last from param;
      commit;
   end if;
   RETURN jnum;
END get_open_je;

END Run ;
/
Show Errors
