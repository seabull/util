create or replace PACKAGE BODY hostdb.INTEGRITY
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
   END;

   /*
    *  Change all assetno or assetnum columns to mimic any change to
    *  capequip.assetnum.  This requires that all asset number foreign key
    *  contraints be created deferrable and initially deferred.
    *
    *  The capequip table is special cased since we know its change cause this
    *  trigger to fire.  The assetno_history table is special cased since we'll
    *  be inserted a mapping entry as our final step.
    *  machtab is special cased since some procedures/triggers depend on it to
    *  be sync-ed.
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
            AND table_name NOT IN ('ASSETNO_HISTORY', 'CAPEQUIP', 'MACHTAB')
	    AND table_name not in (select
					object_name
				     from all_objects
				    where owner = 'HOSTDB'
				      and object_type = 'MATERIALIZED VIEW'
				);

      c     INTEGER;
      n     INTEGER;
      com   VARCHAR2 (132);
   BEGIN

      Update machtab
         set assetno=nassetno
       where assetno=oassetno;
      util.LOG ('update machtab set assetno=' || nassetno
                         || ' where assetno=' || oassetno );

      util.LOG('==>' || SQL%ROWCOUNT || ' rows updated');

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
      c := trigdef.setup ('capequip.assetnum');

      WHILE (trigdef.another (c, r))
      LOOP
         capequipassetrun (r.text1, r.text2);
      END LOOP;
   END;

   /*
    * AFTER UPDATE,INSERT,DELETE ON backup_report
    *   FOR EACH ROW
    */
   PROCEDURE brchanged (ri ROWID, nhostname VARCHAR2, ohostname VARCHAR2)
   IS
   BEGIN
      trigdef.enqueue ('backup_report',
                       ri,
                       nhostname,
                       NULL,
                       NULL,
                       ohostname,
                       NULL,
                       NULL
                      );
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
         IF (ri IS NULL)
         THEN
            DELETE FROM host_attr
                  WHERE attr = 'B' AND sense = '+';

            IF (SQL%ROWCOUNT > 0)
            THEN
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

               util.LOG ('Inserted host_attr ' || qhostname || '+ B');
            ELSE
               util.LOG ('Updated host_attr ' || qhostname || '+ B');
            END IF;
         END IF;
      END;
   BEGIN
      c := trigdef.setup ('backup_report');

      WHILE (trigdef.another (c, r))
      LOOP
         brrun (r.row_id, r.text1);
      END LOOP;
   END;

   PROCEDURE capequipchanged (ri ROWID, nassetno VARCHAR2, oassetno VARCHAR2)
   IS
   BEGIN
      trigdef.enqueue ('capequip',
                       ri,
                       nassetno,
                       NULL,
                       NULL,
                       oassetno,
                       NULL,
                       NULL
                      );
   END;

   PROCEDURE capequipchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      c := trigdef.setup ('capequip');

      WHILE (trigdef.another (c, r))
      LOOP
         capequiprun (r.row_id, r.text1);
      END LOOP;
   END;

   PROCEDURE capequiprun (ri ROWID, qassetno VARCHAR2)
   IS
   BEGIN
      util.LOG ('Process capequip ' || ri);
      machtabqueuebyassetno (qassetno);
   END;

   PROCEDURE centervalidate (qcenter IN VARCHAR2)
   IS
      flag   CHAR;
   BEGIN
      SELECT closed
        INTO flag
        FROM centers, accounts
       WHERE center = qcenter
         AND centers.ACCOUNT = accounts.ID
         AND flag IN ('c', 's')
         AND USER != 'COSTING@CS.CMU.EDU';

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
   END;

   PROCEDURE nameupdating (
      NAME     IN OUT   VARCHAR2,
      lname    OUT      VARCHAR2,
      lcname   OUT      VARCHAR2
   )
   IS
   BEGIN
      NAME := RTRIM (NAME, ' ');
      lname := last_name (NAME);
      lcname := LOWER (NAME);
   END;

   /*
   /*
    *  AFTER INSERT OR UPDATE OF name,princ ON name
    */
   PROCEDURE namechanges
   IS
      nm   NAME.NAME%TYPE;
   BEGIN
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
         NULL;
      WHEN OTHERS
      THEN
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
      SELECT   dist, SUM (pct)
          INTO bid, bpct
          FROM dist
      GROUP BY dist
        HAVING SUM (pct) != 100.000;

      RAISE TOO_MANY_ROWS;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN TOO_MANY_ROWS
      THEN
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
      distQuery (NULL, NULL, by_name, by_subname, did, src, uo);
      RETURN did;
   END;

   /*
    * Keep the dists table up to date with the dist table
    */
   PROCEDURE distchanged (ri ROWID, dist dist.dist%TYPE)
   IS
      ID   dists.ID%TYPE;
   BEGIN
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
   END;

   /*
    * Only needed on delete right now
    */
   PROCEDURE distchanges
   IS
   BEGIN
      dist100;
      LOCK TABLE dists IN EXCLUSIVE MODE;

      DELETE FROM dists
            WHERE ID NOT IN (SELECT /*+MERGE_AJ*/
                                    dist
                               FROM dist);
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
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      IF qpct IS NULL
      THEN
         UPDATE dist_names
            SET dist = qdist,
                src = qsrc
          WHERE NAME = qname AND subname = qsubname;
      ELSE
         UPDATE dist_names
            SET dist = qdist,
                src = qsrc,
                pct = qpct
          WHERE NAME = qname AND subname = qsubname;
      END IF;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO dist_names
                     (NAME, subname, dist, src, pct
                     )
              VALUES (qname, qsubname, qdist, qsrc, qpct
                     );
      END IF;
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
      searching := TRUE;
      below := 999999;

      WHILE searching
      LOOP
         FIRST := TRUE;

         FOR dr IN one_pass (below)
         LOOP
            util.LOG (dr.n || ',' || dr.ACCOUNT || ',' || dr.pct || ','
                      || dr.mdist
                     );

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
      END LOOP;

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
      lpct := 100;
      n := nc;

      IF (tpct = 0)
      THEN
         nid := NULL;
      ELSE
         zpct := 100;
         apct := 0;

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
         END LOOP;

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
      util.LOG ('Purge dist name ' || qname || ',' || qsubname);
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      DELETE FROM dist_names
            WHERE NAME = qname AND subname = qsubname;

      distsqueuerelatedbyproject (qname, qsubname);
   END;

   PROCEDURE distpurgebysub (qsubname VARCHAR)
   IS
   BEGIN
      util.LOG ('Purge dist sub-name ' || qsubname);
      LOCK TABLE dist_names IN EXCLUSIVE MODE;

      DELETE FROM dist_names
            WHERE subname = qsubname;

      machtabqueuebysub (qsubname);
   END;

   PROCEDURE distQuery (
      by_name1             VARCHAR2
      ,by_subname1         VARCHAR2
      ,by_name2            VARCHAR2
      ,by_subname2         VARCHAR2
      ,dist          OUT   dist_t
      ,src           OUT   charge_src_t
      ,uo            OUT   CHAR
      ,pct           OUT   pct_t
      ,dtype         OUT   pls_integer
   )
   IS
      PROCEDURE QUERY (qname VARCHAR2, qsubname VARCHAR2)
      IS
      BEGIN
         SELECT dist, src, user_only, pct
           INTO dist, src, uo, pct
           FROM dist_names
          WHERE NAME = qname AND subname = qsubname;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dist := NULL;
            src := NULL;
            uo := NULL;
            pct := NULL;
      END;
   BEGIN
      dtype := 0;
      dist := NULL;
      LOCK TABLE dist_names IN SHARE MODE;

      IF (dist IS NULL AND by_name1 IS NOT NULL)
      THEN
         dtype := 1;
         QUERY (by_name1, by_subname1);
      END IF;

      IF (dist IS NULL AND by_name2 IS NOT NULL)
      THEN
	 dtype := 2;
         QUERY (by_name2, by_subname2);
      END IF;
   END distQuery;

   PROCEDURE distQuery (
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
      dtype	pls_integer;
   BEGIN
      distQuery (by_name1
		,by_subname1
		,by_name2
		,by_subname2
		,dist
		,src
		,uo
		,pct
		,dtype
                );
   END distQuery;

   PROCEDURE distQuery (
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
      distQuery (by_name1,
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
         END;

         LOCK TABLE project_combos IN EXCLUSIVE MODE;

         SELECT subname
           INTO dummy
           FROM project_combos
          WHERE NAME = qname AND subname = qsubname;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         util.LOG ('project combo ' || qname || ',' || qsubname);

         INSERT INTO project_combos
                     (NAME, subname
                     )
              VALUES (qname, qsubname
                     );
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
      trigdef.enqueue ('dist_names',
                       ri,
                       NAME,
                       subname,
                       NULL,
                       oname,
                       osubname,
                       NULL
                      );
   END;

   PROCEDURE distschangesokay
   IS
      bad   project_t;
      p     project_t;
   BEGIN
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
   END;

   PROCEDURE distschanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      distschangesokay;

      DELETE FROM projects
            WHERE project NOT IN (SELECT /*+MERGE_AJ*/
                                         NAME
                                    FROM dist_names);

      util.LOG ('Purge projects ' || SQL%ROWCOUNT);
      LOCK TABLE project_combos IN EXCLUSIVE MODE;

      DELETE FROM project_combos
            WHERE (NAME, subname) NOT IN (SELECT /*+MERGE_AJ*/
                                                 NAME, subname
                                            FROM dist_names);

      util.LOG ('Purge project_combos ' || SQL%ROWCOUNT);
      c := trigdef.setup ('dist_names');

      WHILE (trigdef.another (c, r))
      LOOP
         distsrun (r.row_id, r.text1, r.text2);
      END LOOP;
   END;

   PROCEDURE distsqueuerelatedbyproject (NAME VARCHAR2, subname VARCHAR2)
   IS
      pe   project_t;
   BEGIN
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

         util.LOG ('Insert who P');
         machtabqueuebyproject (NAME, subname);
      END IF;
   END;

   PROCEDURE distsqueuerelatedbyuser (who VARCHAR2)
   IS
   BEGIN
      machtabqueuebyuser (who);
   END;

   PROCEDURE distsrun (ri ROWID, NAME VARCHAR2, subname VARCHAR2)
   IS
   BEGIN
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
      LOCK TABLE oses IN EXCLUSIVE MODE;

      SELECT NAME
        INTO tos
        FROM oses
       WHERE NAME = nos;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO oses
                     (NAME
                     )
              VALUES (nos
                     );

         util.LOG ('osChanged defined OS ' || nos);
   END;

   PROCEDURE oschanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      LOCK TABLE oses IN EXCLUSIVE MODE;

      DELETE FROM oses
            WHERE NAME NOT IN (SELECT /*+MERGE_AJ*/
                                      NAME
                                 FROM os);

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
      LOCK TABLE cputypes IN EXCLUSIVE MODE;

      SELECT NAME
        INTO cpu
        FROM cputypes
       WHERE NAME = ncputype;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO cputypes
                     (NAME
                     )
              VALUES (ncputype
                     );

         util.LOG ('machequivChanged defined cpu ' || ncputype);
   END;

   PROCEDURE machequivchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      LOCK TABLE cputypes IN EXCLUSIVE MODE;

      DELETE FROM cputypes
            WHERE NAME NOT IN (SELECT /*+MERGE_AJ*/
                                      cputype
                                 FROM mach_equiv);

      util.LOG ('Purge cputypes ' || SQL%ROWCOUNT);
   END;

   PROCEDURE machtabchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      c := trigdef.setup ('machtab');

      WHILE (trigdef.another (c, r))
      LOOP
         machtabrun (r.row_id, r.text1);
      END LOOP;
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
      IF (util.assetchargeable (qassetno))
      THEN
         IF (charge_by IS NULL)
         THEN
            by_name1 := projectpseudouser;
         ELSE
            by_name1 := NULL;
         END IF;

         distQuery (by_name1, usrprinc, project, subproject, ndist, nsrc, uo);

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
               NULL;
            WHEN OTHERS
            THEN
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
         --IF (mdist IS NULL AND ndist IS NOT NULL)
         --THEN
            costing.hostservicesupdate (qassetno);
         --END IF;

         costing.hostcharges (qassetno);
      END IF;
   END;

   PROCEDURE machtabchanging (nproject VARCHAR2, nsubproject IN OUT VARCHAR2)
   IS
   BEGIN
      IF (nproject IS NULL)
      THEN
         nsubproject := NULL;
      ELSE
         IF (nsubproject IS NULL)
         THEN
            nsubproject := '*';
         END IF;
      END IF;
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
   END;

   PROCEDURE machtabqueuebydist (qdist dist_t)
   IS
   BEGIN
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
   END;

   PROCEDURE machtabqueuebyuser (quser VARCHAR2)
   IS
   BEGIN
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
   END;

   PROCEDURE machtabqueuebyproject (qproject VARCHAR2, qsubproject VARCHAR2)
   IS
   BEGIN
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
   END;

   PROCEDURE machtabchanged (ri ROWID, assetno VARCHAR2, oassetno VARCHAR2)
   IS
   BEGIN
      trigdef.enqueue ('machtab',
                       ri,
                       assetno,
                       NULL,
                       NULL,
                       oassetno,
                       NULL,
                       NULL
                      );
   END;

   PROCEDURE machtabrun (ri ROWID, assetno VARCHAR2)
   IS
      m   machtab%ROWTYPE;
   BEGIN
      IF (ri IS NOT NULL)
      THEN
         SELECT     *
               INTO m
               FROM machtab
              WHERE ROWID = ri
         FOR UPDATE;

         util.LOG ('Process machtab ' || ri || ', #' || m.assetno);
         machtabdist (m.assetno,
                      m.charge_by,
                      m.usrprinc,
                      m.project,
                      m.subproject,
                      m.dist,
                      m.dist_src
                     );
      END IF;
   END;

   /*
    *  Make sure that a project subname is null when the
    *  project is null (during transition) and set subname to '*'
    *  when null if project is not null (for convenience).
    */
   PROCEDURE projectadjust (NAME IN OUT VARCHAR2, subname IN OUT VARCHAR2)
   IS
   BEGIN
      IF (NAME IS NULL)
      THEN
         subname := NULL;
      ELSIF (subname IS NULL)
      THEN
         subname := '*';
      END IF;
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
      LOCK TABLE dist_names IN SHARE MODE;

      SELECT ID
        INTO ID
        FROM dist_names
       WHERE NAME = qname AND subname = qsubname;

      RETURN ID;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
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
      payroll_pct pct_t := null;
      uo         dist_names.user_only%TYPE;
      same       BOOLEAN;
      dtype	 pls_integer := 0;
      l_pct	 pct_t;
	BEGIN
		traceit.log(constDEBUG_LEVELA, 'Enter whodist, wprinc=%s',wprinc);
		IF (wtype = 0)
		THEN
			traceit.log(constDEBUG_LEVELD, 'wtype=%s',wtype);
			/* Only users are charged, also known by whoservices view */
			IF (charge_by IS NULL)
			THEN
				traceit.log(constDEBUG_LEVELD, 'charge_by=NULL,by_name1=<Effort>');
				by_name1 := projectpseudoeffort;
			ELSE
				traceit.log(constDEBUG_LEVELD, 'charge_by=%s,by_name1=NULL',charge_by);
				by_name1 := NULL;
			END IF;

			IF (charge_by = '!')
			THEN
				traceit.log(constDEBUG_LEVELD, 'charge_by=%s,by_name2=NULL',charge_by);
				by_name2 := NULL;
			ELSE
				traceit.log(constDEBUG_LEVELD, 'charge_by=%s,by_name2=%s',nvl(charge_by,'NULL'), wproject);
				/* P or null */
				by_name2 := wproject;
			END IF;

			integrity.distQuery (by_name1
						,wprinc
						,by_name2
						,wsubproject
						,ndist
						,nsrc
						,uo
						,npct
						,dtype
						);

			traceit.log(constDEBUG_LEVELD
					, 'ndist=%s,nsrc=%s,uo=%s,npct=%s,dtype=%s'
					,ndist
					,nsrc
					,uo
					,npct
					,dtype
					);
			/*
			 *   The query may return non-null percentage when an effort
			 *   distribution.
			 */
			IF npct IS NOT NULL
			THEN
                -- dist_names.pct is not null for effort distribution,
                -- it also means, labor (full-time) distribution is charged for 100%
                -- timecard distribution can be charged at any percentage.
                -- the model can be changed to have who.pct overrides payroll
                -- but it overrides timecard data as well.
                -- To change the model and hence considering payroll data,
                -- costing.who_service_charge needs to be modified
                -- i.e. make dist.pct * who.pct * dist_names.pct
                -- instead of having who.pct := dist_names.pct here and use who.pct
                -- only in who_service_charge.
                -- qpct := wpct;
				traceit.log(constDEBUG_LEVELA, 'qpct=%s',npct);
				--qpct := npct;
				qpct := wpct;
                payroll_pct := npct;
			ELSE
				--if dtype = 2 then
				--	if (wdist is not null and charge_by is null and isParttimer(wdist_src))
				--	then
				--		BEGIN
				--			select pct
				--			  into l_pct
				--			  from pt_chg_cat
				--			 where cat=constPTCHGCATCOURTESY;
				--		EXCEPTION
				--			when no_data_found then
				--				l_pct := constDEFAULTPCT;
				--				traceit.log(constDEBUG_LEVELD, 'Use Default l_pct=%s',l_pct);
				--			when others then
				--				traceit.log(constDEBUG_LEVELA, 'Exception - %s,%s',SQLCODE,SQLERRM);
				--				raise_application_error(X.oops, 'Exception when looking up charge cat percent. '||SQLERRM);
				--		END;

				--		util.LOG('PT cat used -'||wprinc||','||wpct);
				--		traceit.log(constDEBUG_LEVELD, 'PT cat used - wprinc=%s, wpct=%s ,l_pct=%s',wprinc, wpct, l_pct);

				--		/*
				--		insert into pt_chg_whocat_hist
				--		(
				--			id
				--			,princ
				--			,odist
				--			,odist_src
				--			,opct
				--			,npct
				--		)
				--		select
				--			ptchgwhocathist_seq.nextval
				--			,wprinc
				--			,wdist
				--			,wdist_src
				--			,wpct
				--			,l_pct
				--		  from dual;
				--		--  not record change
				--		insert into pt_chg_whocat_hist
				--		(
				--			id
				--			,princ
				--			,odist
				--			,odist_src
				--			,opct
				--			,npct
				--			,acct
				--			,distpct
				--		)
				--		select
				--			ptchgwhocathist_seq.nextval
				--			,wprinc
				--			,wdist
				--			,wdist_src
				--			,wpct
				--			,l_pct
				--			,account
				--			,pct
				--		  from dist
				--		 where dist.dist=wdist
				--		;
				--		*/
				--	else
                --        l_pct := wpct;
                --    end if;
				--	qpct := l_pct;

				--else
                --    -- dist comes from by_name1 (effort)
                --    qpct := wpct;
                --end if;

                qpct := wpct;
				traceit.log(constDEBUG_LEVELA, 'qpct=%s',npct);
         	END IF;

			IF (ndist IS NULL)
			THEN
            /*
             *  If we no longer have a distribution but used to and
             *  charging has not been suppressed (no pct), change it to
             *  residual(X).
             */
				IF (wdist IS NOT NULL AND wpct IS NOT NULL)
				THEN
					ndist := wdist;
					nsrc := 'X';

                    -- Do not change pct for residual 'X'
					--IF (UPPER (wdist_src) = wdist_src)
					--THEN
					--	qpct := 5;
					--ELSE
				   	--	qpct := 1;
					--END IF;
					traceit.log(constDEBUG_LEVELD, '%s to residual - %s',wprinc, qpct);
				END IF;
			END IF;
		ELSE
			ndist := NULL;
			nsrc := NULL;
			qpct := NULL;
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

        -- we don't keep history of payroll pct,
        -- 1. since dist_src/nsrc contains implicit payroll/project source data
        --    we know if nsrc=wdist_src then old/new sources are same (part-time/full-time/hardcode)
        -- 2. part-time payroll pct could change, so sync costing tables
        --      if source is part-time payroll
        -- This assumes full-time payroll (labor) are all 100%.

		IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct and upper(nsrc) = nsrc)
		--IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct)
		THEN
		   NULL;
		ELSE
			traceit.log(constDEBUG_LEVELD, 'update %s to dist=%s,dist_src=%s,pct=%s'
							,wprinc
							,ndist
							,nsrc
							,qpct
					);
			UPDATE who
			   SET dist = ndist,
			       dist_src = nsrc,
			       pct = qpct
			 WHERE princ = wprinc;

			/*
			 *   Setting a distribution where there was not one before,
			 *   will enable a service list to be produced.  This
			 *   may have been caused by an action which does not
			 *   dircetly affect the service list and will not
			 *   otherwise invoke the trigger (e.g. setting a
			 *   project name) so we must (re)generate the service list.
			 */
		--	IF (wdist IS NULL AND ndist IS NOT NULL)
		--	THEN
				costing.whoservicesupdate (wprinc);
		--	END IF;

		--	IF (qpct != wpct and ndist = wdist and nsrc = wdist_src) THEN
		--		null;
		--	ELSE
				costing.whocharges (wprinc, qpct);
		--	END IF;
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
			util.LOG ('undefine user ' || wprinc);
			traceit.log(constDEBUG_LEVELA, 'Undefine user %s', wprinc);
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
			traceit.log(constDEBUG_LEVELA, 'defined user %s', wprinc);
		END IF;

		distsqueuerelatedbyuser (wprinc);
		traceit.log(constDEBUG_LEVELA, 'Exit whodist');
	END;

   PROCEDURE whochanging (nproject IN OUT VARCHAR2, nsubproject IN OUT VARCHAR2)
   IS
   BEGIN
      IF (nproject IS NULL)
      THEN
         nsubproject := NULL;
      ELSE
         IF (nsubproject IS NULL)
         THEN
            nsubproject := '*';
         END IF;
      END IF;
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
      c := trigdef.setup ('who');

      WHILE (trigdef.another (c, r))
      LOOP
         IF (r.row_id IS NOT NULL)
         THEN
            /* only care about UPDATE,INSERT  right now */
            whorun (r.row_id, r.text1);
         END IF;
      END LOOP;
   END;

   PROCEDURE whorun (ri ROWID, qprinc VARCHAR2)
   IS
      w   who%ROWTYPE;
   BEGIN
      SELECT     *
            INTO w
            FROM who
           WHERE ROWID = ri
      FOR UPDATE;

      util.LOG ('Process who ' || ri || ', ' || w.princ);
      whodist (w.princ,
               w.project,
               w.subproject,
               w.charge_by,
               w.dist,
               w.pct,
               w.dist_src,
               w.TYPE
              );
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
      SELECT COUNT (*)
        INTO n
        FROM param;

      IF (n <> 1)
      THEN
         raise_application_error
                              (x.param,
                               'PARAM table must always have exactly one row'
                              );
      END IF;
   END;

   FUNCTION isParttimer(
			wdist_src	IN	charge_src_t
                       )
   return boolean
   IS
     l_rtn	boolean := false;
   BEGIN
	if lower(wdist_src)=wdist_src then
		l_rtn := true;
	end if;
	return l_rtn;
   END isParttimer;

	procedure whoPctChanged(ri IN ROWID, nprinc IN vARCHAR2, oprinc IN VARCHAR2)
	is
	begin

		traceit.log(constDEBUG_LEVELA, 'Enter whoPctChanged, princ=%s', nprinc);
		trigdef.enqueue ('who.pct',
			ri,
			nprinc,
			oprinc,
			NULL,
			NULL,
			NULL,
			NULL
			);
		traceit.log(constDEBUG_LEVELA, 'Exit whoPctChanged');
	end whoPctChanged;

	procedure whoPctChanges
	is
		c	trigdef.trigdef_cursor_t;
		r	trigdef.trigdef_t;
		w	who%ROWTYPE;
	begin
		traceit.log(constDEBUG_LEVELA, 'Enter whoPctChanges');
		c := trigdef.setup ('who.pct');

		WHILE (trigdef.another (c, r))
		LOOP
			IF (r.row_id IS NOT NULL)
			THEN
				/* only care about UPDATE,INSERT  right now */
				SELECT     *
				  INTO w
				  FROM who
				 WHERE ROWID = r.row_id;
				traceit.log(constDEBUG_LEVELA, 'Process who rowid=%s, princ=%s, pct=%s, dist=%s', r.row_id, w.princ, w.pct, w.dist);
				util.LOG ('Process who ' || r.row_id || ', ' || w.princ);
				costing.whoCharges(w.princ, w.pct);
			END IF;
		END LOOP;
		traceit.log(constDEBUG_LEVELA, 'Exit whoPctChanges');
	end whoPctChanges;

BEGIN
   NULL;
END;
/
Show Errors
