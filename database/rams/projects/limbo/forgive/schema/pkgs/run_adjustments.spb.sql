-- $Id: run_adjustments.spb.sql,v 1.4 2007/09/24 17:31:43 yangl Exp $
create or replace PACKAGE BODY hostdb.RUN_ADJUSTMENTS IS
   errbuf             VARCHAR2 (10000);
   retcode            VARCHAR2 (1);
   adj_journal        NUMBER;
   adj_post_date      DATE             := trunc( SysDate ) ;
-- adj_post_date      DATE             := to_date( 'Jun-30-2007', 'Mon-DD-YYYY');
-- adj_post_date      DATE             := to_date('JUN-30-'||to_char(add_months(sysdate, -6), 'YYYY'),'MON-DD-YYYY');
   today              DATE             := Sysdate ;
   exc_nodata_error   EXCEPTION;

   --
   -- retcode key
   -- 'P' = Passed
   -- 'E' = Error
   --

   ----------------------------------------------------
--Uses accounts table for GL validation and pta_status table for GMS validation
   PROCEDURE journalchecklimbo (retcode OUT VARCHAR2, errdesc OUT VARCHAR2)
   IS
      l_host_gl_limbo_count   NUMBER := NULL;
      l_who_gl_limbo_count    NUMBER := NULL;
      l_error_count           NUMBER := NULL;
      l_host_exist            NUMBER := NULL;
      l_who_exist             NUMBER := NULL;

      CURSOR c_who_exist
      IS
         SELECT COUNT (*)
           FROM who_adjust_charge
          WHERE NVL (hold_flag, 'N') != 'Y';

      CURSOR c_host_exist
      IS
         SELECT COUNT (*)
           FROM host_adjust_charge
          WHERE NVL (hold_flag, 'N') != 'Y';

      CURSOR c_limbo
      IS
         SELECT COUNT (*)
           FROM run_adjust_failed_accts;

      CURSOR c_who_gl_limbo
      IS
         SELECT COUNT (*)
           FROM hostdb.accounts, hostdb.who_adjust_charge who
          WHERE accounts.ID = who.ACCOUNT
            AND accounts.flag = 'l'
            AND accounts.funding IS NOT NULL
            AND NVL (who.hold_flag, 'N') != 'Y';

      CURSOR c_host_gl_limbo
      IS
         SELECT COUNT (*)
           FROM hostdb.accounts, hostdb.host_adjust_charge HOST
          WHERE accounts.ID = HOST.ACCOUNT
            AND accounts.flag = 'l'
            AND accounts.funding IS NOT NULL
            AND NVL (HOST.hold_flag, 'N') != 'Y';
   BEGIN
      --initialize variables
      errdesc := NULL;
      retcode := NULL;

      --prepare transactions to be revalidated
      UPDATE who_adjust_charge
         SET hold_flag = NULL,
             limbo_flag = NULL;

      UPDATE host_adjust_charge
         SET hold_flag = NULL,
             limbo_flag = NULL;

      --clear out old error records
      DELETE FROM run_adjust_failed_accts;

      COMMIT;

      /* Test for existance of records to validate*/
      IF NOT c_who_exist%ISOPEN
      THEN
         OPEN c_who_exist;
      END IF;

      FETCH c_who_exist
       INTO l_who_exist;

      CLOSE c_who_exist;

      IF NOT c_host_exist%ISOPEN
      THEN
         OPEN c_host_exist;
      END IF;

      FETCH c_host_exist
       INTO l_host_exist;

      CLOSE c_host_exist;

      IF (NVL (l_who_exist, 0) = 0)
      THEN
         IF (NVL (l_host_exist, 0) = 0)
         THEN
            RAISE exc_nodata_error;
         END IF;
      END IF;

      /* TEST FOR EXISTANCE THEN INSERT summary HOST GL limbo records INTO error TABLE FOR END USER reporting*/
      IF NOT c_host_gl_limbo%ISOPEN
      THEN
         OPEN c_host_gl_limbo;
      END IF;

      FETCH c_host_gl_limbo
       INTO l_host_gl_limbo_count;

      CLOSE c_host_gl_limbo;

      --  IF l_host_gl_limbo_count > 0 THEN
      INSERT INTO run_adjust_failed_accts
                  (amount, num_recs, TYPE, acct, creation_date, created_by,
                   last_update_date, last_updated_by, trans_date, acct_id,
                   notes, trans_id)
         SELECT   SUM (HOST.amount), LPAD (COUNT (HOST.hr_id), 3, '0'),
                  'HOST',
                  (   acct.funding
                   || '-'
                   || acct.FUNCTION
                   || '-'
                   || acct.activity
                   || '-'
                   || acct.org
                   || '-'
                   || acct.entity
                  ),
                  today, 'Run_Adjustments.JournalCheckLimbo',
                  today, 'Run_Adjustments.JournalCheckLimbo', HOST.trans_date,
                  HOST.ACCOUNT, HOST.notes, hr_id
             FROM hostdb.host_adjust_charge HOST, hostdb.accounts acct
            WHERE acct.ID = HOST.ACCOUNT
              AND acct.flag = 'l'
              AND acct.funding IS NOT NULL
         --  AND NVL(HOST.HOLD_FLAG,'N')!='Y'
         GROUP BY (   acct.funding
                   || '-'
                   || acct.FUNCTION
                   || '-'
                   || acct.activity
                   || '-'
                   || acct.org
                   || '-'
                   || acct.entity
                  ),
                  HOST.trans_date,
                  HOST.ACCOUNT,
                  HOST.notes,
                  hr_id;

      -- END IF;  -- host gl limbo accounts exist

      /* TEST FOR EXISTANCE THEN INSERT summary gms limbo records INTO error TABLE FOR END USER reporting*/
      INSERT INTO run_adjust_failed_accts
                  (amount, num_recs, TYPE, acct, proj_start_date,
                   proj_completion_date, proj_closed_date, proj_status_code,
                   task_completion_date, task_charge_flag,
                   award_start_date_active, award_end_date_active,
                   award_closed_date, award_status, creation_date, created_by,
                   last_update_date, last_updated_by, trans_date, acct_id,
                   notes, trans_id)
     SELECT
         SUM(host.AMOUNT)
        ,LPAD(COUNT(host.HR_ID),3,'0')
       ,'HOST'
        ,PTA.PTA
        ,PTA.PROJ_START_DATE
       ,PTA.PROJ_COMPLETION_DATE
       ,PTA.PROJ_CLOSED_DATE
       ,PTA.PROJ_STATUS_CODE
       ,PTA.TASK_COMPLETION_DATE
       ,PTA.TASK_CHARGE_FLAG
       ,PTA.AWARD_START_DATE_ACTIVE
       ,PTA.AWARD_END_DATE_ACTIVE
       ,PTA.AWARD_CLOSED_DATE
       ,PTA.AWARD_STATUS
       ,today
       ,'Run_Adjustments.JournalCheckLimbo'
       ,today
       ,'Run_Adjustments.JournalCheckLimbo'
       ,HOST.TRANS_DATE
       ,HOST.ACCOUNT
       ,HOST.NOTES
       ,HOST.HR_ID
    FROM pta_status_v pta, hostdb.host_adjust_charge host
   WHERE pta.account_id=host.account
     AND (pta.TASK_CHARGE_FLAG = 'N'
     or pta.Award_Status in ('CLOSED','ON_HOLD')
     or pta.proj_status_code IN ('CLOSED','PENDING_CLOSE','SUBMITTED','UNAPPROVED')
     OR NVL(PTA.PROJ_CLOSED_DATE,'31-DEC-2057') <= TO_CHAR(adj_post_date,'DD-MON-YYYY')
     OR NVL(PTA.TASK_COMPLETION_DATE,'31-DEC-2057') < HOST.TRANS_DATE
     OR NVL(PTA.AWARD_END_DATE_ACTIVE,'31-DEC-2057') <  HOST.TRANS_DATE
     OR NVL(PTA.AWARD_CLOSED_DATE,'31-DEC-2057') <= TO_CHAR(adj_post_date,'DD-MON-YYYY')
     or NVL(pta.proj_completion_date,'31-DEC-2057') < HOST.TRANS_DATE
     OR NVL(PTA.PROJ_START_DATE,'31-DEC-1900') >  HOST.TRANS_DATE
     OR NVL(PTA.AWARD_START_DATE_ACTIVE,'31-DEC-1900') >  HOST.TRANS_DATE)
   --  AND NVL(HOST.HOLD_FLAG,'N')!='Y'
   GROUP BY PTA.PTA
   ,HOST.TRANS_DATE
   ,HOST.ACCOUNT
   ,HOST.NOTES
   ,PTA.PROJ_START_DATE
   ,PTA.PROJ_COMPLETION_DATE
   ,PTA.PROJ_CLOSED_DATE
   ,PTA.PROJ_STATUS_CODE
   ,PTA.TASK_COMPLETION_DATE
   ,PTA.TASK_CHARGE_FLAG
   ,PTA.AWARD_START_DATE_ACTIVE
   ,PTA.AWARD_END_DATE_ACTIVE
   ,PTA.AWARD_CLOSED_DATE
   ,PTA.AWARD_STATUS
   ,HOST.HR_ID        ;

      COMMIT;
      retcode := 'E';

      /* TEST FOR EXISTANCE THEN INSERT summary WHO GL limbo records INTO error TABLE FOR END USER reporting*/
      IF NOT c_who_gl_limbo%ISOPEN
      THEN
         OPEN c_who_gl_limbo;
      END IF;

      FETCH c_who_gl_limbo
       INTO l_who_gl_limbo_count;

      CLOSE c_who_gl_limbo;

      IF l_who_gl_limbo_count > 0
      THEN
         /* INSERT FAILED WHO GL records INTO error TABLE FOR END USER reporting*/
         INSERT INTO run_adjust_failed_accts
                     (amount, num_recs, TYPE, acct, creation_date,
                      created_by, last_update_date, last_updated_by,
                      trans_date, acct_id, notes, trans_id)
            SELECT   SUM (who.amount), LPAD (COUNT (who.wr_id), 3, '0'),
                     'WHO',
                     (   acct.funding
                      || '-'
                      || acct.FUNCTION
                      || '-'
                      || acct.activity
                      || '-'
                      || acct.org
                      || '-'
                      || acct.entity
                     ),
                     today, 'Run_Adjustments.JournalCheckLimbo',
                     today, 'Run_Adjustments.JournalCheckLimbo', who.trans_date,
                     who.ACCOUNT, who.notes, who.wr_id
                FROM hostdb.accounts acct, hostdb.who_adjust_charge who
               WHERE acct.ID = who.ACCOUNT
                 AND acct.flag = 'l'
                 AND acct.funding IS NOT NULL
            -- AND NVL(WHO.HOLD_FLAG,'N')!='Y'
            GROUP BY (   acct.funding
                      || '-'
                      || acct.FUNCTION
                      || '-'
                      || acct.activity
                      || '-'
                      || acct.org
                      || '-'
                      || acct.entity
                     ),
                     who.trans_date,
                     who.ACCOUNT,
                     who.notes,
                     who.wr_id;
      END IF;                                   -- who gl limbo accounts exist

      /* TEST FOR EXISTANCE THEN INSERT summary gms WHO limbo records INTO error TABLE FOR END USER reporting*/
      INSERT INTO run_adjust_failed_accts
                  (amount, num_recs, TYPE, acct, proj_start_date,
                   proj_completion_date, proj_closed_date, proj_status_code,
                   task_completion_date, task_charge_flag,
                   award_start_date_active, award_end_date_active,
                   award_closed_date, award_status, creation_date, created_by,
                   last_update_date, last_updated_by, trans_date, acct_id,
                   notes, trans_id)
         SELECT   SUM (who.amount), LPAD (COUNT (who.wr_id), 3, '0'), 'WHO',
                  pta.pta, pta.proj_start_date, pta.proj_completion_date,
                  pta.proj_closed_date, pta.proj_status_code,
                  pta.task_completion_date, pta.task_charge_flag,
                  pta.award_start_date_active, pta.award_end_date_active,
                  pta.award_closed_date, pta.award_status,
                  today, 'Run_Adjustments.JournalCheckLimbo',
                  today, 'Run_Adjustments.JournalCheckLimbo', who.trans_date,
                  who.ACCOUNT, who.notes, who.wr_id
             FROM pta_status_v pta, hostdb.who_adjust_charge who
            WHERE pta.account_id = who.ACCOUNT
              AND (   pta.task_charge_flag = 'N'
                   OR pta.award_status IN ('CLOSED', 'ON_HOLD')
                   OR pta.proj_status_code IN
                         ('CLOSED', 'PENDING_CLOSE', 'SUBMITTED',
                          'UNAPPROVED')
                   OR NVL (pta.proj_closed_date, '31-DEC-2057') <=
                                              TO_CHAR (adj_post_date, 'DD-MON-YYYY')
                   OR NVL (pta.task_completion_date, '31-DEC-2057') <
                                                                who.trans_date
                   OR NVL (pta.award_end_date_active, '31-DEC-2057') <
                                                                who.trans_date
                   OR NVL (pta.award_closed_date, '31-DEC-2057') <=
                                              TO_CHAR (adj_post_date, 'DD-MON-YYYY')
                   OR NVL (pta.proj_completion_date, '31-DEC-2057') <
                                                                who.trans_date
                   OR NVL (pta.proj_start_date, '31-DEC-1900') >
                                                                who.trans_date
                   OR NVL (pta.award_start_date_active, '31-DEC-1900') >
                                                                who.trans_date
                  )
         -- AND NVL(WHO.HOLD_FLAG,'N')!='Y'
         GROUP BY pta.pta,
                  who.trans_date,
                  who.ACCOUNT,
                  who.notes,
                  pta.proj_start_date,
                  pta.proj_completion_date,
                  pta.proj_closed_date,
                  pta.proj_status_code,
                  pta.task_completion_date,
                  pta.task_charge_flag,
                  pta.award_start_date_active,
                  pta.award_end_date_active,
                  pta.award_closed_date,
                  pta.award_status,
                  who.wr_id;

      COMMIT;

      IF NOT c_limbo%ISOPEN
      THEN
         OPEN c_limbo;
      END IF;

      LOOP
         FETCH c_limbo
          INTO l_error_count;

         EXIT WHEN c_limbo%NOTFOUND;

         IF (NVL (l_error_count, 0) > 0)
         THEN
            errdesc := 'Account(s) Failed Validation ';
            retcode := 'E';
         ELSE
            errdesc := 'Account(s) Passed Validation ';
            retcode := 'P';
         END IF;
      END LOOP;
   EXCEPTION
      WHEN exc_nodata_error
      THEN
         retcode := 'E';
         errdesc := 'No Adjustments Exist to Validate';
      WHEN OTHERS
      THEN
         errdesc := (SQLCODE || ' -**- ' || SQLERRM);
         retcode := 'E';
   END journalchecklimbo;

------------------------------------------------------
--Mark failed (limbo) accounts as hold accounts along with the associated transfer
   PROCEDURE journalholdadjust (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      v_check_holds         NUMBER;

      CURSOR c_who_failed
      IS
         SELECT acct_id, TO_CHAR (trans_date, 'DD-MON-YYYY') trans_date,
                notes
           FROM run_adjust_failed_accts
          WHERE TYPE = 'WHO';

      v_failed_who_acct     NUMBER;
      v_failed_who_date     DATE;
      v_failed_who_notes    VARCHAR2 (50);

      CURSOR c_host_failed
      IS
         SELECT acct_id, TO_CHAR (trans_date, 'DD-MON-YYYY') trans_date,
                notes
           FROM run_adjust_failed_accts
          WHERE TYPE = 'HOST';

      v_failed_host_acct    NUMBER;
      v_failed_host_date    DATE;
      v_failed_host_notes   VARCHAR2 (50);

      CURSOR c_who_hold
      IS
         SELECT DISTINCT wr_id
                    FROM who_adjust_charge
                   WHERE wr_id IN (
                            SELECT DISTINCT wr_id
                                       FROM who_adjust_charge
                                      WHERE ACCOUNT = (v_failed_who_acct)
                                        AND TO_CHAR (trans_date,
                                                     'DD-MON-YYYY') =
                                                             v_failed_who_date);

      CURSOR c_host_hold
      IS
         SELECT DISTINCT hr_id
                    FROM host_adjust_charge
                   WHERE hr_id IN (
                            SELECT DISTINCT hr_id
                                       FROM host_adjust_charge
                                      WHERE ACCOUNT = (v_failed_host_acct)
                                        AND TO_CHAR (trans_date,
                                                     'DD-MON-YYYY') =
                                                            v_failed_host_date);
   BEGIN
      SELECT COUNT (*)
        INTO v_check_holds
        FROM run_adjust_failed_accts;

      --SELECT WHO TRX FROM RUN_ADJUST_FAILED_ACCTS TABLE
      FOR c_who_failed_rec IN c_who_failed
      LOOP
         v_failed_who_acct := c_who_failed_rec.acct_id;
         v_failed_who_date := c_who_failed_rec.trans_date;
         v_failed_who_notes := c_who_failed_rec.notes;

         UPDATE who_adjust_charge wac
            SET wac.limbo_flag = 'Y',
                wac.last_updated_by = 'SET HOLDS',
                wac.last_update_date = today
          WHERE wac.ACCOUNT = v_failed_who_acct
            AND TO_CHAR (wac.trans_date, 'DD-MON-YYYY') =
                   c_who_failed_rec.trans_date
                                    --to_char(v_failed_WHO_date,'DD-MON-YYYY')
            AND wac.notes = v_failed_who_notes;

         --LOOP THROUGH AND MARK EACH FAILED TRX (TO AND FROM) ON WHO_ADJUST_CHARGE
         FOR c_who_hold_rec IN c_who_hold
         LOOP
            UPDATE who_adjust_charge
               SET hold_flag = 'Y',
                   last_updated_by = 'SET HOLDS',
                   last_update_date = today
             WHERE wr_id = c_who_hold_rec.wr_id
               AND TO_CHAR (trans_date, 'DD-MON-YYYY') = v_failed_who_date;
         END LOOP;
      END LOOP;

      COMMIT;

      --SELECT HOST TRX FROM RUN_ADJUST_FAILED_ACCTS TABLE
      FOR c_host_failed_rec IN c_host_failed
      LOOP
         v_failed_host_acct := c_host_failed_rec.acct_id;
         v_failed_host_date := c_host_failed_rec.trans_date;
         v_failed_host_notes := c_host_failed_rec.notes;

         UPDATE host_adjust_charge hac
            SET hac.limbo_flag = 'Y',
                hac.last_updated_by = 'SET HOLDS',
                hac.last_update_date = today
          WHERE hac.ACCOUNT = v_failed_host_acct
            AND TO_CHAR (hac.trans_date, 'DD-MON-YYYY') =
                                                  c_host_failed_rec.trans_date
            AND hac.notes = v_failed_host_notes;

         COMMIT;

         --LOOP THROUGH AND MARK EACH FAILED TRX (TO AND FROM) ON HOST ADJUST_CHARGE
         FOR c_host_hold_rec IN c_host_hold
         LOOP
            UPDATE host_adjust_charge
               SET hold_flag = 'Y',
                   last_updated_by = 'SET HOLDS',
                   last_update_date = today
             WHERE hr_id = c_host_hold_rec.hr_id
               AND TO_CHAR (trans_date, 'DD-MON-YYYY') = v_failed_host_date;
         END LOOP;
      END LOOP;

      COMMIT;

      IF NVL (v_check_holds, 0) > 0
      THEN
         retcode := 'P';
         errbuf :=
                ('The Following Adjust/Refund entries where marked ON-HOLD'
                );
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         retcode := 'P';
         errbuf := ('No Adjustments Marked ON-HOLD');
      WHEN OTHERS
      THEN
         errbuf := (SQLCODE || ' -- ' || SQLERRM);
         retcode := 'E';
   END journalholdadjust;

------------------------------------------------------------------------------------------------
   PROCEDURE testjournalleftover (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      l_hostcount      NUMBER;
      l_whocount       NUMBER;
      l_journalcount   NUMBER;
   BEGIN
      DBMS_OUTPUT.ENABLE (10000);

	if(run_utils.existOpenJournal) then
		errbuf := 'An Open Journal exists, please accept/reject the previous journal first.';
		retcode := 'E';
	else

	      BEGIN
	         /* get the journal number */
	         SELECT journal
	           INTO adj_journal
	           FROM param;
	      EXCEPTION
	         WHEN NO_DATA_FOUND
	         THEN
	            errbuf :=
	                     'Journal identifier not found for this adjustment batch';
	            retcode := 'E';
	      END;

	      BEGIN
	         SELECT COUNT (*)
	           INTO l_hostcount
	           FROM hostdb.host_charged
	          WHERE host_charged.journal = adj_journal;

	         SELECT COUNT (*)
	           INTO l_whocount
	           FROM hostdb.who_charged
	          WHERE journal = adj_journal;

	         SELECT COUNT (*)
	           INTO l_journalcount
	           FROM hostdb.journal
	          WHERE journal = adj_journal;

	         IF (l_hostcount > 0 OR l_whocount > 0 OR l_journalcount > 0)
	         THEN
	            errbuf :=
	                  l_hostcount
	               || ','
	               || l_whocount
	               || ','
	               || l_journalcount
	               || ' Leftover Journal entries for journal '
	               || adj_journal
	               || ' found in host_charged, who_charged or journal tables respectively';
	            retcode := 'E';
	         END IF;
	      END;
	end if;
   END testjournalleftover;

-----------------------------------------------------
 /*selects THE NEXT journal number FROM param AND IF each OF host adjustments AND who
adjustments exist, host_charged AND who_charged are updated with */
   PROCEDURE journalrecordadjust (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      l_hostcount         NUMBER;
      l_whocount          NUMBER;
      l_prefy08_count     pls_integer := 0;
      -- date after FY07 second close, i.e. jnl 325 on Jul-11-2007
      l_fy08_firstdate    date  := to_date('Jul-12-2007','Mon-DD-YYYY');
      l_exp_objcode       hostdb.journal.objcode%TYPE := '68200';
      l_rev_objcode       hostdb.journal.objcode%TYPE := '88200';
      l_new_exp_objcode   hostdb.journal.objcode%TYPE := '68280';
      l_new_rev_objcode   hostdb.journal.objcode%TYPE := '88280';
      --l_des               varchar2(1000);
      v_gl_bal            NUMBER;
      id_test             NUMBER;
      too_many_journals   EXCEPTION;

      CURSOR gl_bal_entry_needed
      IS
         SELECT 0 - SUM (j.amount)
           FROM journal j, accounts a
          WHERE j.journal = adj_journal
            AND j.ACCOUNT = a.ID
            AND funding IS NOT NULL;
   BEGIN
      DBMS_OUTPUT.ENABLE (10000);

	if(run_utils.existOpenJournal) then
		errbuf := 'An Open Journal exists, please accept/reject the previous journal first.';
		retcode := 'E';
		raise_application_error (-20100, 'Open Journal Exists!!');
	end if;

      BEGIN
         /*get the journal identifier for this batch */
         SELECT journal
           INTO adj_journal
           FROM param;

         SELECT COUNT (*)
           INTO id_test
           FROM journals j
          WHERE j.ID = adj_journal AND j.je_in_process_flag = 'Y';

         /*  IF id_test = 0 THEN
           RAISE no_data_found;
           END IF;*/
         DBMS_OUTPUT.put_line ('Journal' || ' ' || adj_journal);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errbuf :=
                     'Journal identifier not found for this adjustment batch';
            retcode := 'E';
         WHEN TOO_MANY_ROWS
         THEN
            errbuf :=
               'Param table has not been incremented. There is an existing batch to accept';
            retcode := 'E';
            raise_application_error (-20104, 'PARAM Table not incremented');
      END;

      /* check for existance and capture host adjustments then mark belonging to this journal. */
      BEGIN
         IF retcode IS NULL
         THEN
            BEGIN
               SELECT COUNT (*)
                 INTO l_hostcount
                 FROM hostdb.host_adjust_charge
                WHERE NVL (host_adjust_charge.hold_flag, 'N') != 'Y'
                  AND (   host_adjust_charge.journal IS NULL
                       OR host_adjust_charge.journal = 1
                      );

               IF (l_hostcount > 0)
               THEN
                  /*copy adjust records TO historical TABLE FROM adjust TABLE*/
                  INSERT INTO hostdb.host_charged
                              (hr_id, pct, hpct, charge, amount, trans_date,
                               service_id, ACCOUNT, account_flag, notes,
                               journal, creation_date, created_by,
                               last_update_date, last_updated_by)
                     SELECT c.hr_id, c.pct, c.hpct, c.charge, c.amount,
                            SUBSTR (c.trans_date, 1, 9), c.service_id,
                            c.ACCOUNT, NULL, c.notes, adj_journal,
                            today, 'Run_Adjustments.JournalRecordAdjust',
                            today, 'Run_Adjustments.JournalRecordAdjust'
                       FROM hostdb.host_adjust_charge c, hostdb.accounts a
                      WHERE c.ACCOUNT = a.ID
                        AND NVL (c.hold_flag, 'N') != 'Y'
                        AND (c.journal IS NULL OR c.journal = 1);

                  UPDATE hostdb.host_adjust_charge
                     SET journal = adj_journal,
                         last_update_date = today,
                         last_updated_by =
                                         'Run_Adjustments.JournalRecordAdjust'
                   WHERE NVL (hold_flag, 'N') != 'Y'
                     AND (   host_adjust_charge.journal IS NULL
                          OR host_adjust_charge.journal = 1
                         );

                  DBMS_OUTPUT.put_line (   'Inserted '
                                        || SQL%ROWCOUNT
                                        || ' host_charged adjustment records'
                                       );

                  /* INSERT records belonging TO this journal FROM charged TABLE*/
                  INSERT INTO journal
                              (journal, objcode, ACCOUNT, amount, post_date,
                               trans_date, description, creation_date,
                               created_by, last_update_date, last_updated_by)
                     SELECT   adj_journal, l_new_rev_objcode, c.ACCOUNT,
                              SUM (NVL (c.amount, 0)), adj_post_date,
                              SUBSTR (c.trans_date, 1, 9),
                              COUNT (DISTINCT hr.assetno) || ' machine(s) ',
                              today, 'Run_Adjustments.JournalRecordAdjust',
                              today, 'Run_Adjustments.JournalRecordAdjust'
                         FROM host_charged c, host_recorded hr
                        WHERE c.journal = adj_journal
                          AND c.account_flag IS NULL
                          AND hr.ID = c.hr_id
                          and c.trans_date >= l_fy08_firstdate
                     GROUP BY c.ACCOUNT, trans_date;

                  DBMS_OUTPUT.put_line (   'Journaled '
                                        || SQL%ROWCOUNT
                                        || ' host records'
                                       );

                  select count(*)
                    into l_prefy08_count
                    from host_charged c
                   where c.journal = adj_journal
                     and c.account_flag IS NULL
                     and c.trans_date < l_fy08_firstdate
                    ;

                  if l_prefy08_count > 0 then
                      INSERT INTO journal
                                  (journal, objcode, ACCOUNT, amount, post_date,
                                   trans_date, description, creation_date,
                                   created_by, last_update_date, last_updated_by)
                         SELECT   adj_journal, l_rev_objcode, c.ACCOUNT,
                                  SUM (NVL (c.amount, 0)), adj_post_date,
                                  SUBSTR (c.trans_date, 1, 9),
                                  COUNT (DISTINCT hr.assetno) || ' machine(s) ',
                                  today, 'Run_Adjustments.JournalRecordAdjust',
                                  today, 'Run_Adjustments.JournalRecordAdjust'
                             FROM host_charged c, host_recorded hr
                            WHERE c.journal = adj_journal
                              AND c.account_flag IS NULL
                              AND hr.ID = c.hr_id
                              and c.trans_date < l_fy08_firstdate
                         GROUP BY c.ACCOUNT, trans_date;
                      --Util.log('Journaled ' || SQL%ROWCOUNT || ' machine records');
                      DBMS_OUTPUT.put_line (   'Journaled '
                                            || SQL%ROWCOUNT
                                            || ' pre-FY08 host records'
                                           );
                 end if;
               ELSE
                   --l_hostcount > 0  there are no host adjustments to process
                  NULL;
               END IF;
            END;

            --check for existance of user adjustments then Capture user adjustments
            --and mark as belonging to this journal. Update who_adjust_charge with
            --adj_journal so that these trx can be deleted after the journal entry is accepted
            BEGIN
               SELECT COUNT (*)
                 INTO l_whocount
                 FROM hostdb.who_adjust_charge w
                WHERE NVL (w.hold_flag, 'N') != 'Y'
                  AND (w.journal IS NULL OR w.journal = 1);

               IF (l_whocount > 0)
               THEN
                  INSERT INTO hostdb.who_charged
                              (wr_id, pct, charge, amount, trans_date,
                               service_id, ACCOUNT, account_flag, notes,
                               journal, creation_date, created_by,
                               last_update_date, last_updated_by)
                     SELECT c.wr_id, c.pct, c.charge, c.amount,
                            SUBSTR (c.trans_date, 1, 9), c.service_id,
                            c.ACCOUNT, NULL, c.notes, adj_journal,
                            today, 'Run_Adjustments.JournalRecordAdjust',
                            today, 'Run_Adjustments.JournalRecordAdjust'
                       FROM hostdb.who_adjust_charge c, hostdb.accounts a
                      WHERE c.ACCOUNT = a.ID
                        AND NVL (c.hold_flag, 'N') != 'Y'
                        AND (c.journal IS NULL OR c.journal = 1);

                  DBMS_OUTPUT.put_line (   'Inserted '
                                        || SQL%ROWCOUNT
                                        || ' who_charged adjustment records'
                                       );

                  UPDATE hostdb.who_adjust_charge
                     SET journal = adj_journal,
                         last_update_date = today,
                         last_updated_by =
                                         'Run_Adjustments.JournalRecordAdjust'
                   WHERE NVL (hold_flag, 'N') != 'Y'
                     AND (journal IS NULL OR journal = 1);

                  /*update journal table to include transaction for this entry*/
                  INSERT INTO journal
                              (journal, objcode, ACCOUNT, amount, post_date,
                               trans_date, description, creation_date,
                               created_by, last_update_date, last_updated_by)
                     SELECT   adj_journal, l_new_rev_objcode, c.ACCOUNT,
                              SUM (NVL (c.amount, 0)), adj_post_date,
                              SUBSTR (c.trans_date, 1, 9),
                              COUNT (DISTINCT wr.princ) || ' user(s)',
                              today, 'Run_Adjustments.JournalRecordAdjust',
                              today, 'Run_Adjustments.JournalRecordAdjust'
                         FROM who_charged c, who_recorded wr
                        WHERE c.journal = adj_journal
                          AND c.account_flag IS NULL
                          AND wr.ID = c.wr_id
                          and c.trans_date >= l_fy08_firstdate
                     GROUP BY c.ACCOUNT, c.trans_date;

                  --Util.log('Journaled ' || SQL%ROWCOUNT || ' user records');
                  DBMS_OUTPUT.put_line (   'Journaled '
                                        || SQL%ROWCOUNT
                                        || ' user records'
                                       );

                  l_prefy08_count := 0;
                  select count(*)
                    into l_prefy08_count
                    from who_charged c
                   where c.journal = adj_journal
                     and c.account_flag IS NULL
                     and c.trans_date < l_fy08_firstdate
                    ;

                  if l_prefy08_count > 0 then
                        INSERT INTO journal
                                    (journal, objcode, ACCOUNT, amount, post_date,
                                     trans_date, description, creation_date,
                                     created_by, last_update_date, last_updated_by)
                           SELECT   adj_journal, l_rev_objcode, c.ACCOUNT,
                                    SUM (NVL (c.amount, 0)), adj_post_date,
                                    SUBSTR (c.trans_date, 1, 9),
                                    COUNT (DISTINCT wr.princ) || ' user(s)',
                                    today, 'Run_Adjustments.JournalRecordAdjust',
                                    today, 'Run_Adjustments.JournalRecordAdjust'
                               FROM who_charged c, who_recorded wr
                              WHERE c.journal = adj_journal
                                AND c.account_flag IS NULL
                                AND wr.ID = c.wr_id
                                and c.trans_date < l_fy08_firstdate
                           GROUP BY c.ACCOUNT, c.trans_date;

                        --Util.log('Journaled ' || SQL%ROWCOUNT || ' user records');
                        DBMS_OUTPUT.put_line (   'Journaled '
                                              || SQL%ROWCOUNT
                                              || ' pre-FY08 user records'
                                             );
                  end if;
               END IF;
            END;

            UPDATE journal
               SET description =
                         'SCS Adjust/Refund Batch '
                      || adj_post_date
                      || ': '
                      || description
             WHERE journal = adj_journal;

            COMMIT;

            /*  credit GL revenue  this must follow the summaries above since it produces a
            *   net zero GL sum.  First test to see if a gl entry is needed.
            */
            OPEN gl_bal_entry_needed;

            FETCH gl_bal_entry_needed
             INTO v_gl_bal;

            CLOSE gl_bal_entry_needed;

            IF (v_gl_bal IS NOT NULL)
            THEN
               INSERT INTO journal
                           (journal, objcode, ACCOUNT, post_date, amount,
                            description, creation_date, created_by,
                            last_update_date, last_updated_by)
                  SELECT adj_journal, l_exp_objcode, 11685, adj_post_date,
                         0 - SUM (NVL (j.amount, 0)),
                            'SCS Computer Maintenance Adjust/Refund Entry '
                         || adj_post_date,
                         today, 'Run_Adjustments.JournalRecordAdjust',
                         today, 'Run_Adjustments.JournalRecordAdjust'
                    FROM journal j, accounts a
                   WHERE j.journal = adj_journal
                     AND j.ACCOUNT = a.ID
                     AND funding IS NOT NULL;

               DBMS_OUTPUT.put_line (   'Logged '
                                     || SQL%ROWCOUNT
                                     || ' journal balancing entries'
                                    );
               COMMIT;
            END IF;

            --flag this batch as being in process
            UPDATE journals
               SET je_in_process_flag = 'Y',
                   journal_type_flag = 'A'
             WHERE ID = adj_journal;

            COMMIT;
         ELSE
            NULL;                                   --there has been an error
         END IF;
      END;
   EXCEPTION
      WHEN exc_nodata_error
      THEN
         NULL;
      WHEN OTHERS
      THEN
         errbuf := (SQLCODE || ' -- ' || SQLERRM);
         retcode := 'E';
   END journalrecordadjust;

--------------------------------------------------------------------
/*This PROCEDURE increments THE param TABLE journal VALUE AND THE journal
TABLE TO reflect THE adjustment batch we just created. Table hostdb.gl_report
is updated so that web reports will display this batch*/
   PROCEDURE journalacceptadjust (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
      n               NUMBER;
      l_rows          NUMBER;
      adj_journal     NUMBER;
      j_journal       NUMBER;
      ret             VARCHAR2 (50);
      err             VARCHAR2 (50);

      CURSOR j_recs
      IS
         SELECT COUNT (*)
           FROM journal
          WHERE journal IN (SELECT journal
                              FROM param);

      CURSOR p_num
      IS
         SELECT journal
           FROM param;

      CURSOR j_num
      IS
         SELECT ID
           FROM journals j
          WHERE j.journal_type_flag = 'A' AND j.je_in_process_flag = 'Y';
   BEGIN
      --initialize variables
      n := 0;
      l_rows := 0;
      adj_journal := NULL;

      -- Make sure we actually have a journal entry to accept.
      IF (NOT j_recs%ISOPEN)
      THEN
         OPEN j_recs;

         FETCH j_recs
          INTO n;
      END IF;

      CLOSE j_recs;

      IF (NOT p_num%ISOPEN)
      THEN
         OPEN p_num;

         FETCH p_num
          INTO adj_journal;
      END IF;

      CLOSE p_num;

      IF (NOT j_num%ISOPEN)
      THEN
         OPEN j_num;

         FETCH j_num
          INTO j_journal;
      END IF;

      CLOSE j_num;

      IF adj_journal = j_journal
      THEN
         IF (n > 0)
         THEN
	    insert into host_adjust_charge_hist
		(	ID, HR_ID , PCT , HPCT, CHARGE , AMOUNT , TRANS_DATE
			, SERVICE_ID , ACCOUNT , JOURNAL , NOTES , CREATION_DATE
			, CREATED_BY , LAST_UPDATE_DATE , LAST_UPDATED_BY
			, HOLD_FLAG , LIMBO_FLAG
		)
		select
			adjust_item_seq.nextval
			, HR_ID
			, PCT
			, HPCT
			, CHARGE
			, AMOUNT
			, TRANS_DATE
			, SERVICE_ID
			, ACCOUNT
			, JOURNAL
			, NOTES
			, CREATION_DATE
			, CREATED_BY
			, LAST_UPDATE_DATE
			, LAST_UPDATED_BY
			, HOLD_FLAG
			, LIMBO_FLAG
		  from host_adjust_charge
		 WHERE journal = adj_journal AND NVL (hold_flag, 'N') != 'Y';

            /*Remove posted adjustments from tables*/
            DELETE FROM host_adjust_charge
                  WHERE journal = adj_journal AND NVL (hold_flag, 'N') != 'Y';

            l_rows := SQL%ROWCOUNT;

            INSERT INTO run_adjust_log
                        (run_date, journal, processed, limbo,
                         error_message
                        )
                 VALUES (today, adj_journal, NULL, NULL,
                         'Removed ' || l_rows || ' host_adjust_charge records'
                        );

            COMMIT;

	    insert into who_adjust_charge_hist
		(
			ID, WR_ID , PCT , CHARGE , AMOUNT , TRANS_DATE , SERVICE_ID , ACCOUNT
			, JOURNAL , NOTES , CREATION_DATE , CREATED_BY , LAST_UPDATE_DATE
			, LAST_UPDATED_BY , HOLD_FLAG , LIMBO_FLAG
		)
		select
			adjust_item_seq.nextval
			, WR_ID
			, PCT
			, CHARGE
			, AMOUNT
			, TRANS_DATE
			, SERVICE_ID
			, ACCOUNT
			, JOURNAL
			, NOTES
			, CREATION_DATE
			, CREATED_BY
			, LAST_UPDATE_DATE
			, LAST_UPDATED_BY
			, HOLD_FLAG
			, LIMBO_FLAG
		  from who_adjust_charge
		 WHERE journal = adj_journal AND NVL (hold_flag, 'N') != 'Y';

            DELETE FROM who_adjust_charge
                  WHERE journal = adj_journal AND NVL (hold_flag, 'N') != 'Y';

            l_rows := SQL%ROWCOUNT;

            INSERT INTO run_adjust_log
                        (run_date, journal, processed, limbo,
                         error_message
                        )
                 VALUES (today, adj_journal, NULL, NULL,
                         'Removed ' || l_rows || ' who_adjust_charge records'
                        );

            COMMIT;

            /*For an adjustment journal entry we increment the journal number
            on param, journal_id on journals and mark this journal as an adjustment ('A')    */
            UPDATE param
               SET journal = (SELECT MAX (journal) + 1
                                FROM param);

            /*RECORD THE adjustment batch IN journals table*/
            UPDATE journals
               SET journal_type_flag = 'A',
                   post_date = adj_post_date,
                   je_in_process_flag = NULL
             WHERE ID = adj_journal;

            /*Create the journal parameters assuming the next run is monthly*/
            INSERT INTO journals
                        (ID, post_date)
               SELECT p.journal, p.charge_last
                 FROM param p;

            COMMIT;
            /* update the gl_report table for web access */
            -- hostdb.report_autoupdate;
            /* update the gl_report table services column
            hostdb.update_gl_report_services.SWITCH (adj_journal,
                                                     'A',
                                                     ret,
                                                     err
                                                    );
             */
            hostdb.gl_report_add_charges ( adj_journal ) ;
         END IF;
      ELSE
         errbuf :=
            'Proc JournalAcceptAdjust -- PARAM.journal out of synch with JOURNALS.id';
         retcode := 'E';
      END IF;

      errbuf :=
              errbuf || 'journal =' || j_journal || ' param = ' || adj_journal;
      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         errbuf := 'Proc JournalAcceptAdjust -- NO DATA FOUND';
         retcode := 'E';
      WHEN TOO_MANY_ROWS
      THEN
         errbuf := 'Proc JournalAcceptAdjust -- TOO MANY ROWS';
         retcode := 'E';
      --RAISE_APPLICATION_ERROR(-20104,'JOURNAL_ID not found for this batch');
      WHEN OTHERS
      THEN
         errbuf := (SQLCODE || ' -- ' || SQLERRM);
         retcode := 'E';
   END journalacceptadjust;

---------------------------------------------------------------------
--completely reverses the batch created by JournalRecordAdjust. This procedure should
--only be used to reverse a batch if the batch has not been accepted JournalAcceptAdjust
-- procedure has not been run
   PROCEDURE journalrejectadjust (
      batchno   IN       NUMBER,
      errbuf    OUT      VARCHAR2,
      retcode   OUT      VARCHAR2
   )
   IS
      l_chk_who               NUMBER;
      l_chk_host              NUMBER;
      l_rows                  NUMBER;
      l_current_adj_journal   NUMBER    := batchno;
      no_je_batch             EXCEPTION;

      CURSOR chk_who
      IS
         SELECT COUNT (*)
           FROM who_adjust_charge
          WHERE NVL (who_adjust_charge.hold_flag, 'N') != 'Y'
            AND journal = l_current_adj_journal;

      CURSOR chk_host
      IS
         SELECT COUNT (*)
           FROM host_adjust_charge
          WHERE NVL (host_adjust_charge.hold_flag, 'N') != 'Y'
            AND journal = l_current_adj_journal;
   BEGIN
      IF l_current_adj_journal IS NULL
      THEN
         errbuf := 'You MUST enter the batch number you wish to reverse';
         retcode := 'E';
         RAISE no_je_batch;
      END IF;

      --obsolete since batchno is a parameter

      /* SELECT max(journal)
       INTO l_current_adj_journal
       FROM journal;*/

      -- IF NOT %ISOPEN THEN
      OPEN chk_who;

      --END IF;
      FETCH chk_who
       INTO l_chk_who;

      CLOSE chk_who;

      -- IF NOT%ISOPEN THEN
      OPEN chk_host;

      -- END IF;
      FETCH chk_host
       INTO l_chk_host;

      CLOSE chk_host;

      IF (l_chk_who IS NOT NULL OR l_chk_host IS NOT NULL)
      THEN
         --do not have to touch journals table because it has not been changed
         DELETE FROM journal
               WHERE journal = l_current_adj_journal;

         l_rows := SQL%ROWCOUNT;
         DBMS_OUTPUT.put_line (   'Journal '
                               || l_current_adj_journal
                               || ' Reversed '
                               || l_rows
                               || ' journal entries'
                              );
         COMMIT;

         DELETE FROM who_charged
               WHERE journal = l_current_adj_journal;

         l_rows := SQL%ROWCOUNT;
         DBMS_OUTPUT.put_line (   'Journal '
                               || l_current_adj_journal
                               || ' Reversed '
                               || l_rows
                               || ' who_charged'
                              );
         COMMIT;

         DELETE FROM host_charged
               WHERE journal = l_current_adj_journal;

         l_rows := SQL%ROWCOUNT;
         DBMS_OUTPUT.put_line (   'Journal '
                               || l_current_adj_journal
                               || ' Reversed '
                               || l_rows
                               || ' host_charged'
                              );
         COMMIT;

         UPDATE journals
            SET je_in_process_flag = NULL,
                journal_type_flag = NULL
          WHERE ID = l_current_adj_journal;

         UPDATE who_adjust_charge
            SET journal = 1
          WHERE journal = l_current_adj_journal;

         UPDATE host_adjust_charge
            SET journal = 1
          WHERE journal = l_current_adj_journal;

         COMMIT;
      ELSE
         retcode := 'E';
         errbuf :=
            'This batch has been removed from the adjust tables and cannot be recreated';
      END IF;
   EXCEPTION
      WHEN no_je_batch
      THEN
         raise_application_error (-20104, 'No Batch Number');
   END journalrejectadjust;
-----------------------------------------------------------------------
    PROCEDURE GLReportSync(pFromDate IN date, pUntilDate IN date default sysdate)
    is
    begin
        GLReportSyncForgive(pFromDate, pUntilDate);
    end GLReportSync;

    PROCEDURE GLReportSyncForgive(pFromDate IN date, pUntilDate IN date default sysdate)
    is
        l_FromDate  date    := pFromDate;
        l_UntilDate date    := pUntilDate;
    begin
        if l_FromDate is null then
            --l_FromDate := trunc(sysdate - 1);
            select trunc(post_date)
              into l_FromDate
              from hostdb.journals
             where journal_type_flag='A'
               and id=(select max(id) from hostdb.journals where journal_type_flag='A')
            ;
        end if;

        if l_UntilDate is null then
            l_UntilDate := trunc(sysdate);
        end if;

        --update ( 
        --    select
        --            wf.journal
        --            ,wf.wr_id
        --            ,wf.name
        --            ,wf.trans_date
        --            ,wf.acct_string
        --            ,wf.account_flag
        --            ,g.limbo_flag
        --            ,g.name
        --            ,g.jid
        --            ,g.charge
        --            ,g.amount
        --            ,g.pct
        --            ,g.notes  old_notes
        --            ,wf.notes new_notes
        --      from hostdb.wc_forgiven_details_v wf
        --            ,hostdb.gl_report g
        --     where NVL(wf.name, 'UNKNOWN')=nvl(g.name, 'UNKNOWN')
        --       and wf.journal=g.jid
        --       and trunc(wf.trans_date)=trunc(g.trans_date)
        --       and wf.op_date >= l_FromDate
        --       and wf.op_date <= l_UntilDate
        --       and wf.acct_string=decode(g.proj, null, g.fund||'-'||g.func||g.act||'-'||g.org||'-'||g.ent, g.proj||'-'||g.task||'-'||g.award)
        --    )
        --    set limbo_flag=account_flag
        --  where nvl(limbo_flag, 'v')!=nvl(account_flag,'v')
        --;
        
        update hostdb.gl_report g
           set limbo_flag='f'
         where limbo_flag!='f'
           and (name, trunc(trans_date), jid
                    , decode(g.proj, null
                                , g.fund||'-'||g.func||g.act||'-'||g.org||'-'||g.ent
                                , g.proj||'-'||g.task||'-'||g.award)
                )
                in (select 
                        name, trunc(trans_date), journal, acct_string 
                      from hostdb.wc_forgiven_details_v wf1
                     where operation='f'
                       and op_date >= l_FromDate
                       and op_date <= l_UntilDate
                       and not exists ( select 'X' from hostdb.wc_forgiven wf2
                                         where wf1.wc_rowid=wf2.wc_rowid
                                           and wf2.operation='u'
                                           and op_date >= l_FromDate
                                           and op_date <= l_UntilDate
                                           and wf2.op_date > wf1.op_date
                                        )
                    )
        ;

        update hostdb.gl_report g
           set limbo_flag='l'
         where limbo_flag!='l'
           and (name, trunc(trans_date), jid
                    , decode(g.proj, null
                                , g.fund||'-'||g.func||g.act||'-'||g.org||'-'||g.ent
                                , g.proj||'-'||g.task||'-'||g.award)
                )
                in (select 
                        name, trunc(trans_date), journal, acct_string 
                      from hostdb.wc_forgiven_details_v wf1
                     where operation='u'
                       and op_date >= l_FromDate
                       and op_date <= l_UntilDate
                       and not exists ( select 'X' from hostdb.wc_forgiven wf2
                                         where wf1.wc_rowid=wf2.wc_rowid
                                           and wf2.operation='f'
                                           and op_date >= l_FromDate
                                           and op_date <= l_UntilDate
                                           and wf2.op_date > wf1.op_date
                                        )
                    )
        ;

        update hostdb.gl_report g
           set limbo_flag='f'
         where limbo_flag!='f'
           and (name, trunc(trans_date), jid
                    , decode(g.proj, null
                                , g.fund||'-'||g.func||g.act||'-'||g.org||'-'||g.ent
                                , g.proj||'-'||g.task||'-'||g.award)
                )
                in (select 
                        name, trunc(trans_date), journal, acct_string 
                      from hostdb.hc_forgiven_details_v hf1
                     where operation='f'
                       and op_date >= l_FromDate
                       and op_date <= l_UntilDate
                       and not exists ( select 'X' from hostdb.hc_forgiven hf2
                                         where hf1.hc_rowid=hf2.hc_rowid
                                           and hf2.operation='u'
                                           and op_date >= l_FromDate
                                           and op_date <= l_UntilDate
                                           and hf2.op_date > hf1.op_date
                                        )
                    )
        ;

        update hostdb.gl_report g
           set limbo_flag='l'
         where limbo_flag!='l'
           and (name, trunc(trans_date), jid
                    , decode(g.proj, null
                                , g.fund||'-'||g.func||g.act||'-'||g.org||'-'||g.ent
                                , g.proj||'-'||g.task||'-'||g.award)
                )
                in (select 
                        name, trunc(trans_date), journal, acct_string 
                      from hostdb.hc_forgiven_details_v hf1
                     where operation='u'
                       and op_date >= l_FromDate
                       and op_date <= l_UntilDate
                       and not exists ( select 'X' from hostdb.hc_forgiven hf2
                                         where hf1.hc_rowid=hf2.hc_rowid
                                           and hf2.operation='f'
                                           and op_date >= l_FromDate
                                           and op_date <= l_UntilDate
                                           and hf2.op_date > hf1.op_date
                                        )
                    )
        ;
    end GLReportSyncForgive;
END run_adjustments;
/
Show Errors
