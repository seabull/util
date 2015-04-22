CREATE OR REPLACE PACKAGE BODY "INTEGRITY"
IS
   PROCEDURE capequiprun (ri ROWID, qassetno VARCHAR2);

   PROCEDURE distsrun (ri ROWID, NAME VARCHAR2, subname VARCHAR2);

   PROCEDURE distsqueuerelatedbyproject (NAME VARCHAR2, subname VARCHAR2);

   PROCEDURE distsqueuerelatedbyuser (who VARCHAR2);

   PROCEDURE machtabrun (ri ROWID, assetno VARCHAR2);

   PROCEDURE whorun (ri ROWID, qprinc VARCHAR2);

   FUNCTION distbyname (qname VARCHAR2, qsubname VARCHAR2)
      RETURN dist_t;

   FUNCTION projectpseudouser
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN '<User>';
   END;

   FUNCTION projectpseudoeffort
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN '<Effort>';
   END;

   PROCEDURE names (
      NAME               VARCHAR2,
      lastname     OUT   VARCHAR2,
      firstname    OUT   VARCHAR2,
      middlename   OUT   VARCHAR2
   )
   IS
      lc      NUMBER;
      tname   hostdb.emp.FIRST%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s', name);
      IF (NAME IS NULL)
      THEN
         lastname := NULL;
         firstname := NULL;
         middlename := NULL;
      ELSE
         lc := INSTR (NAME, ',');

         IF (lc > 0)
         THEN
            lastname := LTRIM (RTRIM (SUBSTR (NAME, 1, lc - 1)));
            tname := LTRIM (RTRIM (SUBSTR (NAME, lc + 1)));
            lc := INSTR (tname, ' ', -1, 1);

            --firstname := lc;
            --middlename := NULL;
            IF (lc <= 1)
            THEN
               firstname := tname;
               middlename := NULL;
            ELSE
               firstname := RTRIM (SUBSTR (tname, 1, lc - 1));
               middlename := RTRIM (LTRIM (SUBSTR (tname, lc + 1)));
            END IF;
         -- ELSE
            ----- Error out here ------
         END IF;
      END IF;
      DEBUG.LOG(16,'Exit, lastname=%s,firstname=%s,middlename=%s',lastname,firstname,nvl(middlename,'NULL'));
   END names;

   FUNCTION last_name (NAME VARCHAR2)
      RETURN VARCHAR2
   IS
      i       INTEGER;
      lc      INTEGER;
      fname   hostdb.NAME.lname%TYPE;
      sname   hostdb.NAME.lname%TYPE;
      tname   hostdb.NAME.lname%TYPE;
   BEGIN
      IF (NAME IS NULL)
      THEN
         RETURN NULL;
      ELSE
         lc := INSTR (NAME, ',', -1);

         IF (lc = 0)
         THEN
            lc := INSTR (NAME, '[', -1);

            IF (lc = 0)
            THEN
               sname := '';
               lc := LENGTH (NAME);
            ELSE
               sname := ' ' || SUBSTR (NAME, lc);
               lc := lc - 1;
            END IF;
         ELSE
            sname := ' ' || LTRIM (SUBSTR (NAME, lc + 1));
            lc := lc - 1;
         END IF;

         tname := RTRIM (SUBSTR (NAME, 1, lc));
         lc := LENGTH (tname);
         i := INSTR (LOWER (tname), ' van ', -1);

         IF (i = 0)
         THEN
            i := INSTR (tname, ' ', -1);

            IF (i = 0)
            THEN
               fname := '';
            ELSE
               fname := ', ' || SUBSTR (tname, 1, i - 1);
            END IF;
         ELSE
            fname := ', ' || SUBSTR (tname, 1, i - 1);
         END IF;

         RETURN SUBSTR (tname, i + 1, lc - i) || fname || sname;
      END IF;
   END last_name;

   PROCEDURE capequipassetchanged (
      ri         ROWID,
      nassetno   assetno_t,
      oassetno   assetno_t
   )
   IS
   /*
    *   AFTER UPDATE
    *     OF assetno ON capequip FOR EACH ROW
    */
   BEGIN
      DEBUG.LOG(16,'Entering,nassetno=%s,oassetno=%s',nassetno,oassetno);
      IF (nassetno != oassetno)
      THEN
              /*
               *  We could probably let the trigger run even if there were no changes
         but
               *  forms changes all fields by default and this would run all the time.
               *
               *  N.B.  This is a non-standard use of the trigger queue.  We enqueue the
               *  new and old asset numbers as the first and second new text keys so that
               *  the old value will be available for the update of all other tables.
               */
         trigdef.enqueue ('capequip.assetnum',
                          ri,
                          nassetno,
                          oassetno,
                          NULL,
                          NULL,
                          NULL,
                          NULL
                         );
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   /*
    *  Change all assetno or assetnum columns to mimic any change to
    *  capequip.assetnum.  This requires that all asset number foreign key
    *  contraints be created deferrable and initially deferred.
    *
    *  The capequip table is special cased since we know its change cause this
    *  trigger to fire.  The assetno_history table is special cased since we'll
    *  be inserted a mapping entry as our final step.
    */
   PROCEDURE capequipassetrun (nassetno assetno_t, oassetno assetno_t)
   IS
      CURSOR a
      IS
         SELECT table_name tab, column_name col
           FROM all_tab_columns
          WHERE owner = 'HOSTDB'
            AND data_type = 'VARCHAR2'
            AND column_name IN ('ASSETNO', 'ASSETNUM')
            AND table_name IN (SELECT table_name
                                 FROM all_tables
                                WHERE owner = 'HOSTDB')
            AND table_name NOT IN ('ASSETNO_HISTORY', 'CAPEQUIP');

      c     INTEGER;
      n     INTEGER;
      com   VARCHAR2 (132);
   BEGIN
      DEBUG.LOG(16,'Entering, nassetno=%s,oassetno=%s',nassetno,oassetno);
      FOR ar IN a
      LOOP
         BEGIN
            c := DBMS_SQL.open_cursor;
            com :=
                  'UPDATE '
               || ar.tab
               || ' SET '
               || ar.col
               || '='''
               || nassetno
               || ''' WHERE '
               || ar.col
               || '='''
               || oassetno
               || '''';
            util.LOG (com);
            DBMS_SQL.parse (c, com, DBMS_SQL.native);
            n := DBMS_SQL.EXECUTE (c);
            util.LOG ('==> ' || n || ' rows updated');
            DEBUG.LOG(16,'%s ==> %s rows updated',com, n);
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_SQL.close_cursor (c);
               RAISE;
         END;

         DBMS_SQL.close_cursor (c);
      END LOOP;

      INSERT INTO assetno_history
                  (assetno, oldassetno, asof
                  )
           VALUES (nassetno, oassetno, SYSDATE
                  );
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE capequipassetchanges
   IS
      /*
      *   AFTER UPDATE
      *     OF assetno ON capequip
       */
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      c := trigdef.setup ('capequip.assetnum');

      WHILE (trigdef.another (c, r))
      LOOP
         capequipassetrun (r.text1, r.text2);
      END LOOP;
      DEBUG.LOG(16,'Exit');
   END;

   /*
    * AFTER UPDATE,INSERT,DELETE ON backup_report
    *   FOR EACH ROW
    */
   PROCEDURE brchanged (ri ROWID, nhostname VARCHAR2, ohostname VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering');
      trigdef.enqueue ('backup_report',
                       ri,
                       nhostname,
                       NULL,
                       NULL,
                       ohostname,
                       NULL,
                       NULL
                      );
      DEBUG.LOG(16,'Exit');
   END;

   /*
    * AFTER UPDATE,INSERT,DELETE ON backup_report
    */
   PROCEDURE brchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;

      /*
       *   Synchronize the backup host attributes with changes to
       *   the backup report table which shadows the Unix
       *   BackupReport.txt file.
       */
      PROCEDURE brrun (ri ROWID, qhostname VARCHAR2)
      IS
      BEGIN
         DEBUG.LOG(16,'Entering, hostname=%s', qhostname);
         IF (ri IS NULL)
         THEN
            DELETE FROM host_attr
                  WHERE attr = 'B' AND sense = '+';

            IF (SQL%ROWCOUNT > 0)
            THEN
               DEBUG.LOG(16,'Deleted host_attr %s + B( %s )', qhostname,SQL%ROWCOUNT);
               util.LOG (   'Deleted host_attr '
                         || qhostname
                         || '+ B ('
                         || SQL%ROWCOUNT
                         || ')'
                        );
            END IF;
         ELSE
            UPDATE host_attr
               SET sense = '+'
             WHERE hostname = qhostname AND attr = 'B';

            IF (SQL%ROWCOUNT = 0)
            THEN
               INSERT INTO host_attr
                           (hostname, attr, sense, notes
                           )
                    VALUES (qhostname, 'B', '+', 'BackupReport'
                           );
               DEBUG.LOG(16,'Inserted host_attr %s + B', qhostname);
               util.LOG ('Inserted host_attr ' || qhostname || '+ B');
            ELSE
               DEBUG.LOG(16,'Updated host_attr %s + B', qhostname);
               util.LOG ('Updated host_attr ' || qhostname || '+ B');
            END IF;
         END IF;
         DEBUG.LOG(16,'Exit');
      END;
   BEGIN
      DEBUG.LOG(16,'Entering');
      c := trigdef.setup ('backup_report');

      WHILE (trigdef.another (c, r))
      LOOP
         brrun (r.row_id, r.text1);
      END LOOP;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE capequipchanged (ri ROWID, nassetno VARCHAR2, oassetno VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering');
      trigdef.enqueue ('capequip',
                       ri,
                       nassetno,
                       NULL,
                       NULL,
                       oassetno,
                       NULL,
                       NULL
                      );
       DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE capequipchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      c := trigdef.setup ('capequip');

      WHILE (trigdef.another (c, r))
      LOOP
         capequiprun (r.row_id, r.text1);
      END LOOP;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE capequiprun (ri ROWID, qassetno VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering, assetno=%s',qassetno);
      util.LOG ('Process capequip ' || ri);
      machtabqueuebyassetno (qassetno);
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE centervalidate (qcenter IN VARCHAR2)
   IS
      flag   CHAR;
   BEGIN
      DEBUG.LOG(16,'Entering, center=%s',qcenter);
      SELECT closed
        INTO flag
        FROM centers, accounts
       WHERE center = qcenter
         AND centers.ACCOUNT = accounts.ID
         AND flag IN ('c', 's')
         AND USER != 'COSTING@CS.CMU.EDU';

      DEBUG.LOG(16,'Exit, exception flag=%s, center=%s',nvl(flag,'NULL'),qcenter);
      raise_application_error (-20104,
                                  'Center '
                               || qcenter
                               || ' is suspended or closed ('
                               || flag
                               || ')'
                              );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE namechanging (
      NAME      IN OUT   VARCHAR2,
      lname     OUT      VARCHAR2,
      lcname    OUT      VARCHAR2,
      ssn       OUT      NUMBER,
      emp_num   OUT      NUMBER
   )
   IS
      counter   NUMBER (2);
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s', NAME);
      NAME := RTRIM (NAME, ' ');
      lname := last_name (NAME);
      lcname := LOWER (NAME);
      ssn := NULL;
      emp_num := NULL;

--------------------------------------------------------------------------
/* before changes made to Jeeves, manually add records if we can't find */
/* matching name                     */
--------------------------------------------------------------------------
      SELECT COUNT (*)
        INTO counter
        FROM hostdb.emp e
       WHERE LOWER (lname) = LOWER (e.emp_name);

       --SELECT SSN, EMP_NUM into ssn, emp_num FROM emp e
      --WHERE lname = e.emp_name;
      IF (counter > 1)
      THEN
         DEBUG.LOG(16,'%s names in emp matched %s', counter, NAME);
         INSERT INTO name_match
                     (NAME, owner, table_name, creation_date
                     )
              VALUES (lname, 'HOSTDB', 'NAME', NULL
                     );
      ELSE
         SELECT COUNT (*)
           INTO counter
           FROM hostdb.emp e
          WHERE LOWER (lname) = LOWER (e.emp_name);

         /*IF (SQL%NOTFOUND) THEN*/
         IF (counter < 1)
         THEN
            DEBUG.LOG(16,'%s name in emp matched %s', counter, NAME);
            INSERT INTO name_match
                        (NAME, owner, table_name, creation_date
                        )
                 VALUES (lname, 'HOSTDB', 'NAME', NULL
                        );
         ELSE
            SELECT ssn, emp_num
              INTO ssn, emp_num
              FROM hostdb.emp e
             WHERE LOWER (lname) = LOWER (e.emp_name);
         END IF;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE nameupdating (
      NAME     IN OUT   VARCHAR2,
      lname    OUT      VARCHAR2,
      lcname   OUT      VARCHAR2
   )
   IS
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s',NAME);
      NAME := RTRIM (NAME, ' ');
      lname := last_name (NAME);
      lcname := LOWER (NAME);
      DEBUG.LOG(16,'Exit, lname=%s,lcname=%s',lname,lcname);
   END;

   /*
   /*
    *  AFTER INSERT OR UPDATE OF name,princ ON name
    */
   PROCEDURE namechanges
   IS
      nm   NAME.NAME%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering');
      SELECT   n.NAME
          INTO nm
          FROM NAME n, principal p
         WHERE n.princ = p.NAME(+)
      GROUP BY n.NAME
        HAVING COUNT (DISTINCT p.princ) > 1;

      RAISE TOO_MANY_ROWS;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DEBUG.LOG(16,'Exit');
         --NULL;
      WHEN OTHERS
      THEN
         DEBUG.LOG(16,'Exit, ERROR %s can only be assigned to a single principal', nm);
         raise_application_error
                         (x.dup_name,
                             nm
                          || ': name can only be assigned to a single principal'
                         );
   END;

   PROCEDURE dist100
   IS
      bpct   dist.pct%TYPE;
      bid    dist.dist%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering');
      SELECT   dist, SUM (pct)
          INTO bid, bpct
          FROM dist
      GROUP BY dist
        HAVING SUM (pct) != 100.000;

      RAISE TOO_MANY_ROWS;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DEBUG.LOG(16,'Exit');
         --NULL;
      WHEN TOO_MANY_ROWS
      THEN
         DEBUG.LOG(16,'Exit, ERROR: new dist percentage sum to %s instead of 100', bpct);
         raise_application_error (-20101,
                                     'New distribution percentages for #'
                                  || bid
                                  || ' sum to '
                                  || bpct
                                  || '% instead of 100%'
                                 );
   END;

   FUNCTION distbyproject (by_name VARCHAR2, by_subname VARCHAR2)
      RETURN dist_t
   IS
      did   dist_t;
      src   CHAR;
      uo    CHAR;
   BEGIN
      DEBUG.LOG(16,'Entering');
      distquery (NULL, NULL, by_name, by_subname, did, src, uo);
      DEBUG.LOG(16,'Exit, dist_id=%s',did);
      RETURN did;
   END;

   /*
    * Keep the dists table up to date with the dist table
    */
   PROCEDURE distchanged (ri ROWID, dist dist.dist%TYPE)
   IS
      ID   dists.ID%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering');
      LOCK TABLE dists IN EXCLUSIVE MODE;

      SELECT ID
        INTO ID
        FROM dists
       WHERE ID = dist;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO dists
                     (ID
                     )
              VALUES (dist
                     );

         util.LOG ('distChanged defined ' || dist);
         DEBUG.LOG(16,'Exit, distChanged deinfed %s', dist);
   END;

   /*
    * Only needed on delete right now
    */
   PROCEDURE distchanges
   IS
   BEGIN
      DEBUG.LOG(16,'Entering');
      dist100;
      LOCK TABLE dists IN EXCLUSIVE MODE;

      DELETE FROM dists
            WHERE ID NOT IN (SELECT /*+MERGE_AJ*/
                                    dist
                               FROM dist);
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distdefine (
      qname      VARCHAR,
      qsubname   VARCHAR,
      qdist      dist_names.dist%TYPE,
      qsrc       dist_names.src%TYPE,
      qpct       pct_t
   )
   IS
   BEGIN
      --DEBUG.LOG(16,'Entering,name=%s,subname=%s,dist=%s,src=%s,pct=%s',qname,qsubname,qdist,qsrc,nvl(qpct,'NULL'));
      DEBUG.LOG(16,'Entering');
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      IF qpct IS NULL
      THEN
         UPDATE dist_names
            SET dist = qdist,
                src = qsrc
          WHERE NAME = qname AND subname = qsubname;
          DEBUG.LOG(16,'qpct=NULL,update dist_names for name=%s,subname=%s',qname,qsubname);
      ELSE
         UPDATE dist_names
            SET dist = qdist,
                src = qsrc,
                pct = qpct
          WHERE NAME = qname AND subname = qsubname;
          DEBUG.LOG(16,'qpct=%s,update dist_names for name=%s,subname=%s',qpct,qname,qsubname);
      END IF;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO dist_names
                     (NAME, subname, dist, src, pct
                     )
              VALUES (qname, qsubname, qdist, qsrc, qpct
                     );
         DEBUG.LOG(16,'INSERTED');
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distdefine (
      qname      VARCHAR,
      qsubname   VARCHAR,
      qdist      dist_names.dist%TYPE,
      qsrc       dist_names.src%TYPE
   )
   IS
   BEGIN
      distdefine (qname, qsubname, qdist, qsrc, NULL);
   END;

   /*
    *  Determine whether or not a distribution already entered
    *  in the table with temporary id 0 already exists.   If it
    *  does, delete the 0 entries and return the existing
    *  number.  If it does not, allocate a new number, set the
    *  temporary id to the permanent id and return that instead.
    *
    *  The basic approach is to use iterative refinement on the
    *  potential set of matching aggregate rows excluding the
    *  maximum distribution located on the previous pass until
    *  we either find a set of rows where all the maximum
    *  distributions match, i.e. the one we are looking for, or
    *  a set of rows where all the maximums are 0, i.e. there
    *  was no match.
    */
   FUNCTION distidentify
      RETURN dist_t
   IS
      CURSOR one_pass (hi dist_t)
      IS
         SELECT   COUNT (*) n, ACCOUNT, pct, MAX (dist) mdist
             FROM dist
            WHERE dist < hi
         GROUP BY ACCOUNT, pct
           HAVING MIN (dist) = 0;

      below       dist_t;
      hidist      dist_t;
      searching   BOOLEAN;
      match       BOOLEAN;
      FIRST       BOOLEAN;
   BEGIN
      DEBUG.LOG(16,'Entering');
      searching := TRUE;
      below := 999999;

      DEBUG.LOG(16,'Loop');
      WHILE searching
      LOOP
         FIRST := TRUE;

         DEBUG.LOG(16,'+Loop');
         FOR dr IN one_pass (below)
         LOOP
            util.LOG (dr.n || ',' || dr.ACCOUNT || ',' || dr.pct || ','
                      || dr.mdist
                     );
            --DEBUG.LOG(16,'++n=%s,account=%s,pct=%s,mdist=%s',nvl(dr.n,'NULL'),nvl(dr.account,'NULL'),nvl(dr.pct,'NULL'),nvl(dr.mdist,'NULL'));

            IF (FIRST)
            THEN
               hidist := dr.mdist;
               FIRST := FALSE;
               match := TRUE;
            ELSE
               IF (dr.mdist != hidist)
               THEN
                  match := FALSE;

                  /*
                   *  The maximum distribution id in the first row
                   *  initializes the highest found so far. Thereafter
                   *  any other mismatch with the highest maximum so far
                   *  indicates that all rows did not share the same
                   *  maximum and that there is no match on this pass.
                    */
                  IF (hidist < dr.mdist)
                  THEN
                     hidist := dr.mdist;
                  END IF;
               END IF;
            END IF;
         END LOOP;
         DEBUG.LOG(16,'+End Loop');

         /*
          *  At loop exit, match is true only if all rows shared
          *  a common maximum.  Any subsequent search will exclude
          *  the maximum found on this pass so that we eventually
          *  converge.  We continue when there was no match.  The
          *  loop should always yield a high match on 0, but just
          *  in case we also require that the loop had some rows
          *  to make another pass
          */
         searching := NOT match AND NOT FIRST;
         below := hidist;
         util.LOG (   'High '
                   || hidist
                   || ', match '
                   || util.booltostring (match)
                   || ', searching '
                   || util.booltostring (searching)
                  );
         DEBUG.LOG(16,'hidist=%s,match=%s,searching=%s',hidist,util.booltostring(match),util.booltostring(searching));
      END LOOP;
      DEBUG.LOG(16,'End Loop');

      IF (match AND hidist != 0)
      THEN
         /*
          *  Non-zero match found: delete the temporary distribution
          *  and use the existing id.
          */
         DELETE FROM dist
               WHERE dist = 0;
      ELSE
         /*
          *  No match found: allocate a new id and set the temporary
          *  distribution entries to use it instead of 0.
          */
         SELECT dist_id.NEXTVAL
           INTO hidist
           FROM DUAL;

         UPDATE dist
            SET dist = hidist
          WHERE dist = 0;
      END IF;

      DEBUG.LOG(16,'Exit,hidist=%s',hidist);
      RETURN hidist;
   END;

   /*
    *  Create a normalized distribution from a charge vector in
    *  a cursor.
    */
   FUNCTION distnormalize (
      cc     charge_cursor_t,
      nc     NUMBER,
      tpct   pct_t,
      prec   NUMBER
   )
      RETURN dist_t
   IS
      apct   pct_t;
      dpct   pct_t;
      lpct   pct_t;
      npct   pct_t;
      zpct   pct_t;
      did    dist_t;
      nid    dist_t;
      cr     charge_t;
      n      NUMBER (3);
   BEGIN
      DEBUG.LOG(16,'Entering');
      lpct := 100;
      n := nc;

      IF (tpct = 0)
      THEN
         nid := NULL;
      ELSE
         zpct := 100;
         apct := 0;

         DEBUG.LOG(16,'Loop');
         LOOP
            FETCH cc
             INTO cr;

            EXIT WHEN cc%NOTFOUND;

            IF (n = 1)
            THEN
               npct := lpct;
            ELSE
               npct := ROUND (cr.pct * 100 / tpct, prec);
            END IF;

            INSERT INTO dist
                        (dist, ACCOUNT, pct, tpct
                        )
                 VALUES (0, cr.ACCOUNT, zpct, npct
                        );

            apct := apct + cr.pct;
            lpct := lpct - npct;
            zpct := 0;
            n := n - 1;
            DEBUG.LOG(16,'apct=%s,lpct=%s,zpct=%s,n=%s',apct,lpct,zpct,n);
         END LOOP;
         DEBUG.LOG(16,'End Loop');

         /*
          * Just in case someone added a row after we calculated
          * the first time.
          */
         IF (apct != tpct)
         THEN
            raise_application_error (-20199,
                                        'Normalized total pct '
                                     || tpct
                                     || ' changed to '
                                     || apct
                                     || ' during calculation, try again'
                                    );
         END IF;

         UPDATE dist
            SET pct = tpct
          WHERE dist = 0;

         nid := integrity.distidentify;
      END IF;

      DEBUG.LOG(16,'Exit,nid=%s',nid);
      RETURN nid;
   END;

   /*
    * This procedure encapsulates all logic related to purging
    * a distribution, including adjusting links from other
    * tables so that integrity constraints will not be violated.
    */
   PROCEDURE distpurge (qname VARCHAR, qsubname VARCHAR)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering, purge name=%s, subname=%s', nvl(qname,'NULL'), nvl(qsubname,'NULL'));
      util.LOG ('Purge dist name ' || qname || ',' || qsubname);
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      DELETE FROM dist_names
            WHERE NAME = qname AND subname = qsubname;

      distsqueuerelatedbyproject (qname, qsubname);
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distpurgebysub (qsubname VARCHAR)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering, purge subname=%s',qsubname);
      util.LOG ('Purge dist sub-name ' || qsubname);
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      DELETE FROM dist_names
            WHERE subname = qsubname;

      machtabqueuebysub (qsubname);
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distquery (
      by_name1            VARCHAR2,
      by_subname1         VARCHAR2,
      by_name2            VARCHAR2,
      by_subname2         VARCHAR2,
      dist          OUT   dist_t,
      src           OUT   charge_src_t,
      uo            OUT   CHAR,
      pct           OUT   pct_t
   )
   IS
      PROCEDURE QUERY (qname VARCHAR2, qsubname VARCHAR2)
      IS
      BEGIN
         DEBUG.LOG(16,'Entering, name=%s, subname=%s',qname, qsubname);
         SELECT dist, src, user_only, pct
           INTO dist, src, uo, pct
           FROM dist_names
          WHERE NAME = qname AND subname = qsubname;
/*
         --DEBUG.LOG(16,'Exit, dist=%s,src=%s,user_only=%s,pct=%s'
                        ,nvl(dist,'NULL')
                        ,nvl(src,'NULL')
                        ,nvl(uo,'NULL')
                        ,nvl(pct,'NULL')
                        );
*/
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DEBUG.LOG(16,'Exit, No Data Found');
            dist := NULL;
            src := NULL;
            uo := NULL;
            pct := NULL;
      END;
   BEGIN
      DEBUG.LOG(16,'Entering');
      dist := NULL;
      LOCK TABLE dist_names IN SHARE MODE;

      IF (dist IS NULL AND by_name1 IS NOT NULL)
      THEN
         DEBUG.LOG(16,'Dist=NULL, by_name1=%s',by_name1);
         QUERY (by_name1, by_subname1);
      END IF;

      IF (dist IS NULL AND by_name2 IS NOT NULL)
      THEN
         DEBUG.LOG(16,'dist=NULL,by_name2=%s',by_name2);
         QUERY (by_name2, by_subname2);
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distquery (
      by_name1            VARCHAR2,
      by_subname1         VARCHAR2,
      by_name2            VARCHAR2,
      by_subname2         VARCHAR2,
      dist          OUT   dist_t,
      src           OUT   charge_src_t,
      uo            OUT   CHAR
   )
   IS
      pct   pct_t;
   BEGIN
      distquery (by_name1,
                 by_subname1,
                 by_name2,
                 by_subname2,
                 dist,
                 src,
                 uo,
                 pct
                );
   END;

   /*
    * Keep the project_combos tables up to date with
    * projects as maintained by dist names.  We maintain a shadow
    * tables so that they can be used to enforce foreign key
    * contraints on both projects and the combinations.   The
    * project may be null  dist_names. the project center
    * table
    */
   PROCEDURE prjcombodefine (qname VARCHAR2, qsubname VARCHAR2)
   IS
      dummy   dist_names.subname%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s,qsubname=%s',qname, nvl(qsubname,'NULL'));
      IF (qname != projectpseudouser AND qname != projectpseudoeffort)
      THEN
         /* XXX keep projects current as well while we still use it */
         DECLARE
            p   projects.project%TYPE;
         BEGIN
            SELECT project
              INTO p
              FROM projects
             WHERE project = qname;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               INSERT INTO projects
                    VALUES (qname);
               DEBUG.LOG(16,'No Data, Inserting into project for name=%s',qname);
         END;

         LOCK TABLE project_combos IN EXCLUSIVE MODE;

         SELECT subname
           INTO dummy
           FROM project_combos
          WHERE NAME = qname AND subname = qsubname;
      END IF;
      DEBUG.LOG(16,'Exit');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         util.LOG ('project combo ' || qname || ',' || qsubname);

         INSERT INTO project_combos
                     (NAME, subname
                     )
              VALUES (qname, qsubname
                     );
         DEBUG.LOG(16,'Exit, Inserting project combo name=%s,subname=%s',qname,qsubname);
   END;

   PROCEDURE distschanged (
      ri         ROWID,
      NAME       VARCHAR2,
      subname    VARCHAR2,
      oname      VARCHAR2,
      osubname   VARCHAR2
   )
   IS
   BEGIN
      DEBUG.LOG(16,'Entering');
      trigdef.enqueue ('dist_names',
                       ri,
                       NAME,
                       subname,
                       NULL,
                       oname,
                       osubname,
                       NULL
                      );
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distschangesokay
   IS
      bad   project_t;
      p     project_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      p := projectpseudoeffort;

      SELECT MIN (NAME)
        INTO bad
        FROM dist_names
       WHERE pct IS NOT NULL AND NAME <> p;

      IF bad IS NOT NULL
      THEN
         raise_application_error
               (-20105,
                   'dist_names has non-null percentage for non-effort name: '
                || bad
               );
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distschanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      distschangesokay;

      DELETE FROM projects
            WHERE project NOT IN (SELECT /*+MERGE_AJ*/
                                         NAME
                                    FROM dist_names);

      DEBUG.LOG(16,'Purge projects %s', SQL%ROWCOUNT);
      util.LOG ('Purge projects ' || SQL%ROWCOUNT);
      LOCK TABLE project_combos IN EXCLUSIVE MODE;

      DELETE FROM project_combos
            WHERE (NAME, subname) NOT IN (SELECT /*+MERGE_AJ*/
                                                 NAME, subname
                                            FROM dist_names);

      DEBUG.LOG(16,'Purge project_combos %s', SQL%ROWCOUNT);
      util.LOG ('Purge project_combos ' || SQL%ROWCOUNT);
      c := trigdef.setup ('dist_names');

      WHILE (trigdef.another (c, r))
      LOOP
         distsrun (r.row_id, r.text1, r.text2);
      END LOOP;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distsqueuerelatedbyproject (NAME VARCHAR2, subname VARCHAR2)
   IS
      pe   project_t;
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s,subname=%s',name,subname);
      pe := projectpseudoeffort;

      IF (NAME = projectpseudouser)
      THEN
         machtabqueuebyuser (subname);
      ELSE
         INSERT INTO trigdef_q
                     (row_id, tab, seq, text1)
            SELECT ROWID, 'who', change_seq.NEXTVAL, princ
              FROM who
             WHERE (project = NAME AND subproject = subname)
                /*
                 * this clause catches changes to effort distributions which may
                 * define user distributions
                 */
                OR (pe, princ) IN ((NAME, subname));

         IF (SQL%ROWCOUNT > 0)
         THEN
            whochanges;
         END IF;

         DEBUG.LOG(16,'Insert who P');
         util.LOG ('Insert who P');
         machtabqueuebyproject (NAME, subname);
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE distsqueuerelatedbyuser (who VARCHAR2)
   IS
   BEGIN
      machtabqueuebyuser (who);
   END;

   PROCEDURE distsrun (ri ROWID, NAME VARCHAR2, subname VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering, ri=%s,name=%s,subname=%s',nvl(ri,'NULL'),name,subname);
      util.LOG ('Process dist_names #' || ri || '.' || NAME || '.' || subname);
      /*
       *  On any change, recalculate any items that used this
       *  project name.  Even on DELETE.
       */
      distsqueuerelatedbyproject (NAME, subname);

      /*
        *   project_combos synchronization on deleted records happens
        *   once per statement in distsChanges.  We only need to
        *   handle new values for non-deletes.
        */
      IF (ri IS NOT NULL)
      THEN
         prjcombodefine (NAME, subname);
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   /*
    *  Keep the oses table up to date with the os table
    *
    *  Standard formal parameters even though we don't use most of
    *  them now in case we eventually need to.
    */
   PROCEDURE oschanged (ri ROWID, nos os_t, nosv osv_t, oos os_t, oosv osv_t)
   IS
      tos   os_t;
   BEGIN
      DEBUG.LOG(16,'Entering,nos=%s',nos);
      LOCK TABLE oses IN EXCLUSIVE MODE;

      SELECT NAME
        INTO tos
        FROM oses
       WHERE NAME = nos;
       DEBUG.LOG(16,'Exit');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO oses
                     (NAME
                     )
              VALUES (nos
                     );
         DEBUG.LOG(16,'Exit, osChanged defined OS %s',nos);
         util.LOG ('osChanged defined OS ' || nos);
   END;

   PROCEDURE oschanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      LOCK TABLE oses IN EXCLUSIVE MODE;

      DELETE FROM oses
            WHERE NAME NOT IN (SELECT /*+MERGE_AJ*/
                                      NAME
                                 FROM os);
      DEBUG.LOG(16,'Exit, purge oses %s', SQL%ROWCOUNT);
      util.LOG ('Purge oses ' || SQL%ROWCOUNT);
   END;

   /*
    *  Keep the cputypes table up to date with the mach_equiv table
    *
    *  Standard formal parameters even though we don't use most of
    *  them now in case we eventually need to.
    */
   PROCEDURE machequivchanged (
      ri          ROWID,
      ncputype    cputype_t,
      ncpumodel   cpumodel_t,
      ocputype    cputype_t,
      ocpumodel   cpumodel_t
   )
   IS
      cpu   cputype_t;
   BEGIN
      DEBUG.LOG(16,'Entering,ncputype=%s',ncputype);
      LOCK TABLE cputypes IN EXCLUSIVE MODE;

      SELECT NAME
        INTO cpu
        FROM cputypes
       WHERE NAME = ncputype;
       DEBUG.LOG(16,'Exit,cpu=%s',nvl(cpu,'NULL'));
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO cputypes
                     (NAME
                     )
              VALUES (ncputype
                     );

         util.LOG ('machequivChanged defined cpu ' || ncputype);
         DEBUG.LOG(16,'Exit, machequivChanged defined cpu %s',ncputype);
   END;

   PROCEDURE machequivchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      LOCK TABLE cputypes IN EXCLUSIVE MODE;

      DELETE FROM cputypes
            WHERE NAME NOT IN (SELECT /*+MERGE_AJ*/
                                      cputype
                                 FROM mach_equiv);

      util.LOG ('Purge cputypes ' || SQL%ROWCOUNT);
      DEBUG.LOG(16,'Exit, purge cputypes %s', SQL%ROWCOUNT);
   END;

   PROCEDURE machtabchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      c := trigdef.setup ('machtab');

      DEBUG.LOG(16,'Loop');
      WHILE (trigdef.another (c, r))
      LOOP
         machtabrun (r.row_id, r.text1);
      END LOOP;
      DEBUG.LOG(16,'End Loop');
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabdist (
      qassetno     VARCHAR,
      charge_by    CHAR,
      usrprinc     VARCHAR2,
      project      VARCHAR2,
      subproject   VARCHAR2,
      mdist        dist_t,
      mdist_src    charge_src_t
   )
   IS
      ndist      dist_t;
      uo         dist_names.user_only%TYPE;
      nsrc       charge_src_t;
      by_name1   machtab.project%TYPE;
   BEGIN
      DEBUG.LOG(16,'Entering,assetno=%s,charge_by=%s',qassetno,nvl(charge_by,'NULL'));
      IF (util.assetchargeable (qassetno))
      THEN
         DEBUG.LOG(16,'%s chargeable', qassetno);
         IF (charge_by IS NULL)
         THEN
            by_name1 := projectpseudouser;
         ELSE
            by_name1 := NULL;
         END IF;

         distquery (by_name1, usrprinc, project, subproject, ndist, nsrc, uo);

         IF (ndist IS NULL)
         THEN
            /*
             *  If we no longer have a distribution but used to,
             *  change it to residual(X).
             */
            IF (mdist IS NOT NULL)
            THEN
               ndist := mdist;
               nsrc := 'X';
            END IF;
         END IF;
      ELSE
         ndist := NULL;
         nsrc := NULL;
      END IF;

      IF (ndist IS NULL AND mdist IS NOT NULL)
      THEN
         /*
           *  May not drop charging while any pass-through (non-monthly)
           *  services are still pending for the host.
           */
         DECLARE
            an   assetno_t;
         BEGIN
            DEBUG.LOG(16,'ndist=NULL,mdist=%s',mdist);
            SELECT UNIQUE assetno
                     INTO an
                     FROM host_service hs, services s
                    WHERE hs.assetno = qassetno
                      AND s.ID = hs.service_id
                      AND s.monthly IS NULL;

            RAISE TOO_MANY_ROWS;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               DEBUG.LOG(16,'Exit');
               --NULL;
            WHEN OTHERS
            THEN
               DEBUG.LOG(16,'Cannot drop charging while pass-thru service are still pending for %s',qassetno);
               raise_application_error
                  (x.thru_pending,
                      'Cannot drop charging while pass-through service(s) are still pending for #'
                   || qassetno
                  );
         END;
      END IF;

      IF (ndist = mdist AND nsrc = mdist_src)
      THEN
         NULL;
      ELSE
         /* also here if any NULL's above caused an unknown but harmless */
         UPDATE machtab
            SET dist = ndist,
                dist_src = nsrc
          WHERE assetno = qassetno;

         /*
          *   Setting a distribution where there was not one before,
          *   will enable a service list to be produced.  This
          *   may have been caused by an action which does not
          *   dircetly affect the service list and will not
          *   otherwise invoke the trigger (e.g. setting a
          *   project name) so we must (re)generate the service.
          */
         IF (mdist IS NULL AND ndist IS NOT NULL)
         THEN
            costing.hostservicesupdate (qassetno);
         END IF;

         costing.hostcharges (qassetno);
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabchanging (nproject VARCHAR2, nsubproject IN OUT VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,nproject=%s,nsubproject=%s',nvl(nproject,'NULL'),nvl(nsubproject,'NULL'));
      IF (nproject IS NULL)
      THEN
         nsubproject := NULL;
      ELSE
         IF (nsubproject IS NULL)
         THEN
            nsubproject := '*';
         END IF;
      END IF;
      DEBUG.LOG(16,'Exit,nsubproject=%s',nvl(nsubproject,'NULL'));
   END;

   /*
    *  This set of machtabQueue procedures is used to enqueue work
    *  on the machtab queue when a change has been made which
    *  could affect the results calculated by this process.
    *  Separate procedures are used to implement the various kinds
    *  of SQL queries needed (instead of trying to cope with the
    *  requirements of the DBMS_SQL package).
    *
    *  Each of these procedures must implement the same basic
    *  manipulation of the change_q table.  Only the form of the
    *  WHERE clause used for the SELECT to fill the table will
    *  vary.
    */
   PROCEDURE machtabqueuebyassetno (qassetno VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,assetno=%s',qassetno);
      util.LOG ('machtab queue by assetno ' || qassetno);

      INSERT INTO trigdef_q
                  (row_id, tab, seq, text1)
         SELECT machtab.ROWID, 'machtab', change_seq.NEXTVAL, assetno
           FROM machtab
          WHERE assetno = qassetno;

      IF (SQL%ROWCOUNT > 0)
      THEN
         machtabchanges;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabqueuebydist (qdist dist_t)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,dist=%s',qdist);
      util.LOG ('machtab queue by dist ' || qdist);

      INSERT INTO trigdef_q
                  (row_id, tab, seq, text1)
         SELECT machtab.ROWID, 'machtab', change_seq.NEXTVAL, assetno
           FROM machtab
          WHERE dist = qdist;

      IF (SQL%ROWCOUNT > 0)
      THEN
         machtabchanges;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabqueuebyuser (quser VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,user=%s',quser);
      util.LOG ('machtab queue by user ' || quser);

      INSERT INTO trigdef_q
                  (row_id, tab, seq, text1)
         SELECT machtab.ROWID, 'machtab', change_seq.NEXTVAL, assetno
           FROM machtab
          WHERE usrprinc = quser;

      IF (SQL%ROWCOUNT > 0)
      THEN
         machtabchanges;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabqueuebyproject (qproject VARCHAR2, qsubproject VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,project=%s,qsubproject=%s',qproject,qsubproject);
      util.LOG ('machtab queue by project ' || qproject || ',' || qsubproject);

      INSERT INTO trigdef_q
                  (row_id, tab, seq, text1)
         SELECT machtab.ROWID, 'machtab', change_seq.NEXTVAL, assetno
           FROM machtab
          WHERE project = qproject AND subproject = qsubproject;

      IF (SQL%ROWCOUNT > 0)
      THEN
         machtabchanges;
      END IF;
   END;

   PROCEDURE machtabqueuebysub (qsubproject VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,subproject=%s',qsubproject);
      util.LOG ('machtab queue by subproject ' || qsubproject);

      INSERT INTO trigdef_q
                  (row_id, tab, seq, text1)
         SELECT machtab.ROWID, 'machtab', change_seq.NEXTVAL, assetno
           FROM machtab
          WHERE subproject = qsubproject;

      IF (SQL%ROWCOUNT > 0)
      THEN
         machtabchanges;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabchanged (ri ROWID, assetno VARCHAR2, oassetno VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering');
      trigdef.enqueue ('machtab',
                       ri,
                       assetno,
                       NULL,
                       NULL,
                       oassetno,
                       NULL,
                       NULL
                      );
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE machtabrun (ri ROWID, assetno VARCHAR2)
   IS
      m   machtab%ROWTYPE;
   BEGIN
      DEBUG.LOG(16,'Entering,ri=%s,assetno=%s',nvl(ri,'NULL'),assetno);
      IF (ri IS NOT NULL)
      THEN
         SELECT     *
               INTO m
               FROM machtab
              WHERE ROWID = ri
         FOR UPDATE;

         util.LOG ('Process machtab ' || ri || ', #' || m.assetno);
         DEBUG.LOG(16,'Process machtab, assetno=%s', m.assetno);
         machtabdist (m.assetno,
                      m.charge_by,
                      m.usrprinc,
                      m.project,
                      m.subproject,
                      m.dist,
                      m.dist_src
                     );
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   /*
    *  Make sure that a project subname is null when the
    *  project is null (during transition) and set subname to '*'
    *  when null if project is not null (for convenience).
    */
   PROCEDURE projectadjust (NAME IN OUT VARCHAR2, subname IN OUT VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,name=%s,subname=%s',nvl(name,'NULL'),nvl(subname,'NULL'));
      IF (NAME IS NULL)
      THEN
         subname := NULL;
      ELSIF (subname IS NULL)
      THEN
         subname := '*';
      END IF;
      DEBUG.LOG(16,'Exit,name=%s,subname=%s',nvl(name,'NULL'),nvl(subname,'NULL'));
   END;

   /*
    *  Acquire a distribution id for a named distribution.  The
    *  returned distribution is guaranteed to be unchanging for the
    *  duration of the transaction.
    */
   FUNCTION distbyname (qname VARCHAR2, qsubname VARCHAR2)
      RETURN dist_t
   IS
      ID   dist_t;
   BEGIN
      DEBUG.LOG(16,'Entering, name=%s,subname=%s',nvl(qname,'NULL'),nvl(qsubname,'NULL'));
      LOCK TABLE dist_names IN SHARE MODE;

      SELECT ID
        INTO ID
        FROM dist_names
       WHERE NAME = qname AND subname = qsubname;

      DEBUG.LOG(16,'Exit,id=%s',id);
      RETURN ID;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DEBUG.LOG(16,'Exit,id=NULL');
         RETURN NULL;
   END;

   /*
    *  Trigger invoked whenever any who.* colums affected charging
    *  are altered:
    *
    *  charge_by, type
    *  project, subproject
    */
   PROCEDURE whodist (
      wprinc        who.princ%TYPE,
      wproject      who.project%TYPE,
      wsubproject   who.subproject%TYPE,
      charge_by     who.charge_by%TYPE,
      wdist         dist_t,
      wpct          pct_t,
      wdist_src     charge_src_t,
      wtype         who.TYPE%TYPE
   )
   IS
      by_name1   who.princ%TYPE;
      by_name2   who.project%TYPE;
      ndist      who.dist%TYPE;
      nsrc       charge_src_t;
      npct       pct_t;
      qpct       pct_t;
      uo         dist_names.user_only%TYPE;
      same       BOOLEAN;
   BEGIN
      DEBUG.LOG(16,'Entering,wtype=%s,charge_by=%s',wtype,nvl(charge_by,'NULL'));
      IF (wtype = 0)
      THEN
         /* Only users are charged, also known by whoservices view */
         IF (charge_by IS NULL)
         THEN
            by_name1 := projectpseudoeffort;
         ELSE
            by_name1 := NULL;
         END IF;

         IF (charge_by = '!')
         THEN
            by_name2 := NULL;
         ELSE
            /* P or null */
            by_name2 := wproject;
         END IF;

         integrity.distquery (by_name1,
                              wprinc,
                              by_name2,
                              wsubproject,
                              ndist,
                              nsrc,
                              uo,
                              npct
                             );

         /*
          *   The query may return non-null percentage when an effort
          *   distribution.
          */
         IF npct IS NOT NULL
         THEN
            qpct := npct;
         ELSE
            qpct := wpct;
         END IF;

         --DEBUG.LOG(16,'npct=%s,qpct=%s',nvl(npct,'NULL'),qpct);
         IF (ndist IS NULL)
         THEN
            DEBUG.LOG(16,'ndist=NULL');
            /*
             *  If we no longer have a distribution but used to and
             *  charging has not been suppressed (no pct), change it to
             *  residual(X).
             */
            IF (wdist IS NOT NULL AND wpct IS NOT NULL)
            THEN
               DEBUG.LOG(16,'wdist=%s,wpct=%s',wdist,wpct);
               ndist := wdist;
               nsrc := 'X';

               IF (UPPER (wdist_src) = wdist_src)
               THEN
                  qpct := 5;
               ELSE
                  qpct := 1;
               END IF;
               DEBUG.LOG(16,'qpct=%s,ndist=%s,nsrc=%s',qpct,ndist,nsrc);
            END IF;
         END IF;
      ELSE
         ndist := NULL;
         nsrc := NULL;
         qpct := NULL;
         DEBUG.LOG(16,'ndist=NULL,nsrc=NULL,qpct=NULL');
      END IF;

      IF (ndist IS NULL AND wdist IS NOT NULL)
      THEN
         /*
           *  May not drop charging while any pass-through (non-monthly)
           *  services are still pending for the user.
           */
         DECLARE
            p   princ_t;
         BEGIN
            DEBUG.LOG(16,'May not drop charging while any pass-thru service pending for the user. ndist=NULL,wdist=%s',wdist);
            SELECT UNIQUE princ
                     INTO p
                     FROM who_service ws, services s
                    WHERE ws.princ = wprinc
                      AND s.ID = ws.service_id
                      AND s.monthly IS NULL;

            RAISE TOO_MANY_ROWS;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --DEBUG.LOG(16,'Exit');
               NULL;
            WHEN OTHERS
            THEN
               raise_application_error
                  (x.thru_pending,
                      'Cannot drop charging while pass-through service(s) are still pending for user '
                   || wprinc
                  );
         END;
      END IF;

      IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct)
      THEN
         DEBUG.LOG(16,'No op, ndist=wdist,nsrc=wdist_src,qpct=wpct,%s,%s,%s',ndist,nsrc,qpct);
         --NULL;
      ELSE
         UPDATE who
            SET dist = ndist,
                dist_src = nsrc,
                pct = qpct
          WHERE princ = wprinc;
          DEBUG.LOG(16,'Update who, princ=%s',wprinc);

         /*
         *   Setting a distribution where there was not one before,
         *   will enable a service list to be produced.  This
         *   may have been caused by an action which does not
         *   dircetly affect the service list and will not
         *   otherwise invoke the trigger (e.g. setting a
         *   project name) so we must (re)generate the service list.
         */
         IF (wdist IS NULL AND ndist IS NOT NULL)
         THEN
            costing.whoservicesupdate (wprinc);
         END IF;

         costing.whocharges (wprinc, qpct);
      END IF;

      /*
       *   We may also end up here when the distribution vector already established
       *   for a user has changed and cannot only trigger when setting a new
       *   distribution above.
       */
      IF ndist IS NULL OR uo IS NOT NULL
      THEN
         /*
          *  No longer any user charging or the charging is coming
          *  from a 'user only' distribution name.  Drop the 'User'
          *  pseudo project used for distributing non-user charges
          *  by the user distribution.
          */
         DEBUG.LOG(16,'undefine user %s',wprinc);
         util.LOG ('undefine user ' || wprinc);
         distpurge (projectpseudouser, wprinc);
      ELSE
         DECLARE
            tpct   dist.pct%TYPE;
            nc     NUMBER (3, 0);
            mcc    charge_cursor_t;
         BEGIN
            SELECT SUM (pct), COUNT (pct)
              INTO tpct, nc
              FROM dist
             WHERE dist = ndist;

            OPEN mcc
             FOR
        	        SELECT pct, account
                  FROM dist 
                  WHERE dist=ndist 
                  ORDER BY pct, account;

            ndist := integrity.distnormalize (mcc, nc, tpct, 2);

            CLOSE mcc;
         END;

         distdefine (projectpseudouser, wprinc, ndist, 'U');
         util.LOG ('defined user ' || wprinc);
         DEBUG.LOG(16,'defined user %s',wprinc);
      END IF;

      distsqueuerelatedbyuser (wprinc);
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE whochanging (nproject IN OUT VARCHAR2, nsubproject IN OUT VARCHAR2)
   IS
   BEGIN
      DEBUG.LOG(16,'Entering,project=%s,subproject=%s',nvl(nproject,'NULL'),nvl(nsubproject,'NULL'));
      IF (nproject IS NULL)
      THEN
         nsubproject := NULL;
      ELSE
         IF (nsubproject IS NULL)
         THEN
            nsubproject := '*';
         END IF;
      END IF;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE whochanged (ri ROWID, nprinc VARCHAR2, oprinc VARCHAR2)
   IS
   BEGIN
      trigdef.enqueue ('who', ri, nprinc, NULL, NULL, oprinc, NULL, NULL);
   END;

   PROCEDURE whochanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      DEBUG.LOG(16,'Entering');
      c := trigdef.setup ('who');

      WHILE (trigdef.another (c, r))
      LOOP
         IF (r.row_id IS NOT NULL)
         THEN
            /* only care about UPDATE,INSERT  right now */
            whorun (r.row_id, r.text1);
         END IF;
      END LOOP;
      DEBUG.LOG(16,'Exit');
   END;

   PROCEDURE whorun (ri ROWID, qprinc VARCHAR2)
   IS
      w   who%ROWTYPE;
   BEGIN
      DEBUG.LOG(16,'Entering, princ=%s',nvl(qprinc,'NULL'));
      SELECT     *
            INTO w
            FROM who
           WHERE ROWID = ri
      FOR UPDATE;

      util.LOG ('Process who ' || ri || ', ' || w.princ);
      DEBUG.LOG(16,'Process who %s', w.princ);
      whodist (w.princ,
               w.project,
               w.subproject,
               w.charge_by,
               w.dist,
               w.pct,
               w.dist_src,
               w.TYPE
              );
      DEBUG.LOG(16,'Exit');
   END;

   /*
    *  AFTER DELETE OR INSERT OR UPDATE
     *   <all columns> ON param
     *
     *  All havoc could ensure if the param table ceased to have
     *  exactly one row since it is joined to all over the place.
    */
   PROCEDURE paramchanges
   IS
      n   NUMBER;
   BEGIN
      DEBUG.LOG(16,'Entering');
      SELECT COUNT (*)
        INTO n
        FROM param;
      DEBUG.LOG(16,'n=%s',n);

      IF (n <> 1)
      THEN
         raise_application_error
                              (x.param,
                               'PARAM table must always have exactly one row'
                              );
      END IF;
      DEBUG.LOG(16,'Exit');
   END;
BEGIN
   NULL;
END;
/
