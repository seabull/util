-- $Id: costing.spb.sql,v 1.7 2007/08/02 03:04:08 yangl Exp $
--
create or replace PACKAGE BODY        hostdb.costing
IS
   PROCEDURE hostattrrun (ri ROWID, qhn hostname_t);

   PROCEDURE hostservicesupdate (qassetno assetno_t)
   IS
      massetno     assetno_t;

      /*
       *   order of this query is important for repair service which requires requires
       *   hardware service and most follow it in the list so that the h variable is
       *   set properly.
       */
      CURSOR s
      IS
         SELECT   h.hostname, h.pri, h.qual, h.dept, h.cputype, h.cpumodel,
                  h.bldg, h.rm, h.suffix, b.abbrev bldg_name, h.os hos,
                  h.warranty_expire, h.dist_src, h.project, h.subproject,
                  h.prjprinc, h.usrprinc, h.princ, h.service_id, h.cmu,
                  h.ours, h.not_ours, h.attr, h.attr2, h.generic, h.other,
                  s.SUBTYPE, s.os, s.specific sspecific, s.generic sgeneric,
                  g.no_net, g.no_hardware, q.no_software, q.no_charge,
                  q.no_net q_no_net, NVL (ma.sense, 'X') mattr,
                  NVL (ha.sense, 'X') hattr, hs.service_id present, hs.hr_id,
                  o.CLASS os_class
                 ,(select sense  from hostdb.mach_attr
                                where assetno=massetno
                                  and attr='CLS'
                 ) mattr_cl_slave
                 ,(select sense  from hostdb.mach_attr
                                where assetno=massetno
                                  and attr='CLH'
                 ) mattr_cl_head
             FROM mach_attr ma,
                  host_attr ha,
                  hostsmachcapservices h,
                  services s,
                  host_service hs,
                  oses o,
                  generics g,
                  qualifiers q,
                  bldgs b
            WHERE h.assetno = massetno
              AND h.service_id = s.ID
              AND h.os = o.NAME(+)
              AND h.generic = g.NAME
              AND h.qual = q.code
              AND h.service_id = hs.service_id(+)
              AND h.assetno = hs.assetno(+)
              AND h.pri = hs.pri(+)
              AND ma.assetno(+) = h.assetno
              AND ma.attr(+) = h.attr
              AND ha.hostname(+) = h.hostname
              AND ha.attr(+) = h.attr2
              AND s.monthly IS NOT NULL
              AND h.bldg = b.code(+)
         ORDER BY h.pri, s.monthly;

      first_host   hostsmachcapservices.pri%TYPE;
      cmus         BOOLEAN;
      ours         BOOLEAN;
      h            BOOLEAN                         := FALSE;
      updated      BOOLEAN                         := FALSE;

      --
      -- added for cluster charge support
      --

      --
      function is_cluster(sr s%ROWTYPE)
            return boolean
      is
            l_rtn   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.is_cluster(cputype=%s)', nvl(sr.cputype,'null'));
        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.is_cluster=%s',util.boolToString(l_rtn));

        return l_rtn;
      end is_cluster;

      function is_cluster_head(sr s%rowtype)
            return boolean
      is
            l_rtn   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.is_cluster_head(mattr_cl_head=%s)', nvl(sr.mattr_cl_head,'null'));
        if (sr.mattr_cl_head = '+') then
            l_rtn := true;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.is_cluster_head=%s',util.boolToString(l_rtn));

        return l_rtn;
      end is_cluster_head;

      function is_cluster_slave(sr s%rowtype)
            return boolean
      is
            l_rtn   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.is_cluster_slave(mattr_cl_slave=%s)', nvl(sr.mattr_cl_slave,'null'));
        if (sr.mattr_cl_slave = '+') then
            l_rtn := true;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.is_cluster_slave=%s',util.boolToString(l_rtn));

        return l_rtn;
      end is_cluster_slave;

      function is_cluster_dummy(sr s%rowtype)
            return boolean
      is
            l_rtn   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.is_cluster_dummy(cputype=%s)', nvl(sr.cputype,'null'));
        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.is_cluster_dummy=%s',util.boolToString(l_rtn));

        return l_rtn;
      end is_cluster_dummy;

      function is_cluster_rack(sr s%rowtype)
            return boolean
      is
            l_rtn   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.is_cluster_rack(cputype=%s)', nvl(sr.cputype,'null'));
        if (sr.cputype like 'RACK') then
            l_rtn := true;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.is_cluster_rack=%s',util.boolToString(l_rtn));

        return l_rtn;
      end is_cluster_rack;

      FUNCTION APPLY (sr s%ROWTYPE, which VARCHAR2, osense BOOLEAN)
         RETURN BOOLEAN
      IS
         tpct      pct_t;
         ppct      pct_t;
         n         NUMBER;
         sense     BOOLEAN;
         updated   BOOLEAN;
      BEGIN
         /*
          *  no_charge qualifiers take precedence over any other
          *  service rules.
          */
         IF (sr.no_charge IS NOT NULL)
         THEN
            sense := FALSE;
         ELSE
            sense := osense;
         END IF;

         IF (   (sense AND sr.present IS NOT NULL)
             OR (NOT sense AND sr.present IS NULL)
            )
         THEN
            /*
             * service is already present when expected or not
             * present when not expected - no action neeeded
             */
            Util.log('NOT CHANGE '||qassetno||','||sr.pri||','||sr.service_id);
            updated := FALSE;
         ELSE
            IF (sense)
            THEN
               util.LOG (   'APPLY '
                         || qassetno
                         || ','
                         || sr.pri
                         || ','
                         || sr.service_id
                         || ','
                         || which
                        );

               INSERT INTO host_service
                           (assetno, pri, service_id, SHARED, pct
                           )
                    VALUES (qassetno, sr.pri, sr.service_id, which, 100
                           );
            ELSE
               util.LOG (   'UNAPPLY '
                         || qassetno
                         || ','
                         || sr.pri
                         || ','
                         || sr.service_id
                        );

               DELETE FROM host_service
                     WHERE assetno = qassetno
                       AND pri = sr.pri
                       AND service_id = sr.service_id;
            END IF;

            updated := TRUE;
            /*
             *  This code was obsoleted by transition to 100% charging
             *  to first occurrence of shared OS per assetno/service
             *
            IF (which IS NOT NULL) THEN
         SELECT min(pri) INTO n
           FROM host_service hs
          WHERE assetno=qassetno and hs.shared=which AND service_id=sr.service_id;
         IF (n > 0) THEN
            ppct := 100/n;
           tpct := ppct*n;
           UPDATE host_service SET pct=ppct
            WHERE assetno=qassetno and shared=which AND service_id=sr.service_id;
           IF (tpct != 100) THEN
              tpct := 100-(ppct*(n-1));
             dbms_output.put_line('Adjust '||tpct);
             UPDATE host_service SET pct=tpct
              WHERE assetno=qassetno and shared=which and pri=sr.pri AND service_id=sr.service_id;
           END IF;
         END IF;
           END IF;
           */
         END IF;

         RETURN (updated);
      END;

      FUNCTION backup_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         IF (sr.mattr = '+' OR sr.hattr = '+')
         THEN
            RESULT := TRUE;
         ELSE
            RESULT := FALSE;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION mr_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
         aisle    VARCHAR2 (2);
         rack     sr.suffix%TYPE;
         which    CHAR;
      BEGIN
         IF (sr.bldg = '012' AND sr.rm = '3611' AND sr.pri = first_host)
         THEN
            aisle := SUBSTR (sr.suffix, 1, 2);
            rack := SUBSTR (sr.suffix, 3);

            --remove obsolete business logic 12/18/03 clr

            --IF (upper(aisle) = 'A1') THEN
             /*
               *   Aisle A1 is work area/storage
               */
             --  null;
            --ELSE
             /* also here if aisle (suffix) is null */
            IF (    LENGTH (rack) = 3
                AND SUBSTR (rack, 1, 1) = '-'
                AND SUBSTR (rack, 2, 1) BETWEEN '0' AND '9'
                AND UPPER (SUBSTR (rack, 3, 1)) BETWEEN 'A' AND 'Z'
               )
            THEN
               /* shelved */
               which := '1';
            ELSE
               /* unshelved */
               which := '2';
            END IF;
         --END IF;
         /*
         Util.log('aisle '||aisle||', rack '||rack||', which '||which);
          */
         END IF;

         IF (which = sr.other)
         THEN
            RESULT := TRUE;
         ELSE
            RESULT := FALSE;
         END IF;

        --
        -- for clusters, no mr charges
        --
        if (   is_cluster_rack(sr)
            or is_cluster_slave(sr)
            or is_cluster_head(sr)
            or is_cluster_dummy(sr)
            ) then
            RESULT := false;
        end if;

        --
        -- Attribute overrides location for machine room services
        --  check attr
        --  + : force enable
        --  - : force disable
        --
        if (sr.pri = first_host) then
            if (sr.mattr = '+') then
                RESULT := TRUE;
            else    if  (sr.mattr = '-') then
                        RESULT := FALSE;
                    end if;
            end if;
        end if;

         RETURN RESULT;
      END;

      FUNCTION net_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         /*
          *  Use IF/THEN rather than boolean here since the condition
          *  may yield unknown.
          */
         IF (   sr.no_net IS NOT NULL
             OR sr.q_no_net IS NOT NULL
             OR sr.mattr = '-'
             OR sr.pri != first_host
            )
         THEN
            RESULT := FALSE;
         ELSE
            -- for cluster dummy/slave/rack, turn network off by default.
            if ( is_cluster_slave(sr)
                or is_cluster_rack(sr)
                or is_cluster_dummy(sr)
            ) then
                if (sr.mattr = '+') then
                    RESULT := TRUE;
                else
                    result := false;
                end if;
            else
                RESULT := TRUE;
            end if;

         END IF;

         RETURN RESULT;
      END;

      FUNCTION hardware_service (sr s%ROWTYPE, ours BOOLEAN)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         IF (   sr.no_hardware IS NOT NULL
             OR sr.mattr = '-'
             OR sr.pri != first_host
            )
         THEN
            RESULT := FALSE;
         ELSE
            IF (   sr.mattr = '+'
                OR (    ours
                     and not is_cluster_rack(sr)
                     and not is_cluster_slave(sr)
                     and not is_cluster_dummy(sr)
                    )
            )
            THEN
               RESULT := TRUE;
            ELSE
               RESULT := FALSE;
            END IF;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION repair_service (sr s%ROWTYPE, ours BOOLEAN, h BOOLEAN)
         RETURN BOOLEAN
      IS
         RESULT      BOOLEAN;
         now         DATE;
         warranted   BOOLEAN;
      BEGIN
         -- short-circuit repair service since only hardware service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;

         RETURN RESULT;

         IF (sr.mattr = '-' OR sr.pri != first_host OR NOT h)
         THEN
            RESULT := FALSE;
         ELSE
            IF (sr.mattr = '+' OR ours)
            THEN
               SELECT charge_last
                 INTO now
                 FROM param;

               IF (sr.sgeneric IS NOT NULL OR sr.sspecific IS NOT NULL)
               THEN
                  IF (sr.warranty_expire >= now)
                  THEN
                     warranted := TRUE;
                  ELSE
                     warranted := FALSE;
                  END IF;

                  IF (sr.other = 'warranty')
                  THEN
                     RESULT := warranted;
                  ELSE
                     RESULT := NOT warranted;
                  END IF;
               ELSE
                  /*
                   * Miscellaneous repair always applies
                   */
                  RESULT := TRUE;
               END IF;
            ELSE
               RESULT := FALSE;
            END IF;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION license_service (sr s%ROWTYPE, ours BOOLEAN)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         -- short-circuit license service since only hardware service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;
         RETURN RESULT;

         IF (sr.no_software IS NOT NULL OR sr.mattr = '-' OR sr.hattr = '-'
            )
         THEN
            RESULT := FALSE;
         ELSE
            if (is_cluster_slave(sr)
                or is_cluster_rack(sr)
                or is_cluster_dummy(sr)
                )
            then
                result := (sr.hattr = '+' OR sr.mattr = '+');
            else
                RESULT := (ours OR sr.hattr = '+' OR sr.mattr = '+');
            end if;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION software_service (sr s%ROWTYPE, ours BOOLEAN)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         IF (sr.no_software IS NOT NULL OR sr.mattr = '-' OR sr.hattr = '-'
            )
         THEN
            RESULT := FALSE;
         ELSE
            if (is_cluster_slave(sr)
                or is_cluster_rack(sr)
                or is_cluster_dummy(sr)
                )
            then
                result := (sr.hattr = '+' OR sr.mattr = '+');
            else
                RESULT := (ours OR sr.hattr = '+' OR sr.mattr = '+') and (sr.pri = first_host);
            end if;
         END IF;

         -- short-circuit software service since only hardware service is charged
         -- starting from FY2008 (2007-Jul-01)
         -- result := false;
         RETURN RESULT;
      END;

      FUNCTION is_asset (an assetno_t)
         RETURN BOOLEAN
      IS
         l        NUMBER;
         numbs    assetno_t;
         RESULT   BOOLEAN;
      BEGIN
         l := LENGTH (an);
         numbs := SUBSTR (an, 1, l - 3) || SUBSTR (an, l - 1, 2);
         /*
          *  Asset number is all digits except for third character
          *  from end which must be '.'
          */
         RESULT := (SUBSTR (an, l - 2, 1) = '.');

         FOR i IN 1 .. (l - 1)
         LOOP
            RESULT := RESULT AND (SUBSTR (numbs, i, 1) BETWEEN '0' AND '9');
            EXIT WHEN NOT RESULT;
         END LOOP;

              /*
         Util.Log('Asset '||an||', numbs '||numbs||' was '||Util.BoolToString(result));
                */
         RETURN RESULT;
      END;

      function cluster_rack_service (sr s%rowtype)
         return boolean
      is
         l_result   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.cluster_rack_service');

        if (is_cluster_rack(sr) and sr.mattr != '-')
        then
           l_result := true;
        else
            if (is_cluster_rack(sr) and sr.mattr = '+') then
                l_result := true;
            end if;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.cluster_rack_service=%s', util.boolToString(l_result));
        return l_result;
      end cluster_rack_service;

      function cluster_headnode_service (sr s%rowtype)
         return boolean
      is
         l_result   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.cluster_headnode_service');

        if (is_cluster_head(sr) and sr.mattr != '-' and sr.pri = first_host)
        then
           l_result := true;
        else
            if (is_cluster_head(sr) and sr.mattr = '+' and sr.pri = first_host) then
                l_result := true;
            end if;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.cluster_headnode_service=%s', util.boolToString(l_result));
        return l_result;
      end cluster_headnode_service;

      function cluster_slavenode_service (sr s%rowtype)
         return boolean
      is
         l_result   boolean := false;
      begin
        traceit.log(traceit.constDEBUGLEVEL_A, 'Enter costing.HostServiceUpdate.cluster_slavenode_service');

        if (is_cluster_slave(sr) and sr.mattr != '-' and sr.pri = first_host)
        then
           l_result := true;
        else
            if (is_cluster_slave(sr) and sr.mattr = '+' and sr.pri = first_host) then
                l_result := true;
            end if;
        end if;

        traceit.log(traceit.constDEBUGLEVEL_A, 'Exit costing.HostServiceUpdate.cluster_slavenode_service=%s', util.boolToString(l_result));
        return l_result;
      end cluster_slavenode_service;

      /*
       *  Obtain the hr_id to record the historical details of
       *  this host, created a record if needed.
       */
      FUNCTION id_for (
         rhostname     host_recorded.hostname%TYPE,
         rassetno      host_recorded.assetno%TYPE,
         rcpu          host_recorded.cpu%TYPE,
         rqual         host_recorded.qual%TYPE,
         rcharge_src   host_recorded.charge_src%TYPE,
         ros           host_recorded.os%TYPE,
         rlocation     host_recorded.LOCATION%TYPE,
         rproject      host_recorded.project%TYPE,
         rsubproject   host_recorded.subproject%TYPE,
         rprjprinc     host_recorded.prjprinc%TYPE,
         rusrprinc     host_recorded.usrprinc%TYPE,
         rprinc        host_recorded.princ%TYPE
      )
         RETURN NUMBER
      IS
         rhr_id   host_recorded.ID%TYPE;
      BEGIN
         BEGIN
            SELECT ID
              INTO rhr_id
              FROM host_recorded
             WHERE (hostname = rhostname)
               AND (assetno = rassetno)
               AND (cpu = rcpu)
               AND (   charge_src = rcharge_src
                    OR (charge_src IS NULL AND rcharge_src IS NULL)
                   )
               AND (os = ros OR (os IS NULL AND ros IS NULL))
               AND (   LOCATION = rlocation
                    OR (LOCATION IS NULL AND rlocation IS NULL)
                   )
               AND (   project = rproject
                    OR (project IS NULL AND rproject IS NULL)
                   )
               AND (   subproject = rsubproject
                    OR (subproject IS NULL AND rsubproject IS NULL)
                   )
               AND (   prjprinc = rprjprinc
                    OR (prjprinc IS NULL AND rprjprinc IS NULL)
                   )
               AND (   usrprinc = rusrprinc
                    OR (usrprinc IS NULL AND rusrprinc IS NULL)
                   )
               AND (princ = rprinc OR (princ IS NULL AND rprinc IS NULL));
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               INSERT INTO host_recorded
                           (hostname, assetno, cpu, qual, charge_src,
                            os, LOCATION, project, subproject,
                            prjprinc, usrprinc, princ
                           )
                    VALUES (rhostname, rassetno, rcpu, rqual, rcharge_src,
                            ros, rlocation, rproject, rsubproject,
                            rprjprinc, rusrprinc, rprinc
                           )
                 RETURNING ID
                      INTO rhr_id;
         END;

         RETURN rhr_id;
      END;
   BEGIN
      util.LOG ('hostServicesUpdate ' || qassetno);

      /*
       *  Synchronize on asset number (not really an update)
       */
      BEGIN
         SELECT     assetno
               INTO massetno
               FROM machtab
              WHERE assetno = qassetno
         FOR UPDATE;
      EXCEPTION
         /*
          *  If the asset number is currently being changed and one
          *  of the related tables is changed first, this
          *  may yield no rows.  When it does, we know we will be
          *  called again when the machtab trigger fires so we
          *  set the assetno number used for the cursor query to
          *  null so that it will yield no rows.  The only affect
          *  here will be to delete all services for the old
          *  asset number.
          */
         WHEN NO_DATA_FOUND
         THEN
            massetno := NULL;
      END;

      /*
       *  Purge all monthly services for host entries that have been
       *  deleted.  Pass-through services (priority 999999) are
       *  not touched.
       */
      DELETE FROM host_service
            WHERE assetno = qassetno
              AND pri != 999999
              AND pri NOT IN (SELECT pri
                                FROM hostsmachcap
                               WHERE assetno = qassetno);

      IF (SQL%ROWCOUNT > 0)
      THEN
         util.LOG (SQL%ROWCOUNT || 'obsolete host entries purged ' || qassetno
                  );
         updated := TRUE;
      END IF;

      /*
       *   Purge any monthly services which no longer map to this asset (say
       *   because the cputype or some other characteristic which
       *   supplied them originally has since changed).  Non-monthly
       *   services are not affected.
       */
      DELETE FROM host_service
            WHERE assetno = qassetno
              AND service_id NOT IN (
                             SELECT service_id
                               FROM hostsmachcapservices h
                              WHERE h.assetno = qassetno
                             UNION
                             SELECT ID
                               FROM services
                              WHERE monthly IS NULL);

      IF (SQL%ROWCOUNT > 0)
      THEN
         util.LOG (SQL%ROWCOUNT || ' obsolete services purged ' || qassetno);
         updated := TRUE;
      END IF;

      FOR sr IN s
      LOOP
         IF (first_host IS NULL)
         THEN
            first_host := sr.pri;
         END IF;

         cmus := sr.cmu IS NOT NULL OR is_asset (qassetno);
         ours :=
            (    (sr.ours IS NOT NULL OR sr.dept IS NULL)
             AND (cmus OR sr.not_ours IS NULL)
            );

         /*
         dbms_output.put_line(sr.hostname||','||sr.pri||','||sr.subtype||','||sr.service_id);
         */
         IF (sr.SUBTYPE = 'N')
         THEN
            updated := APPLY (sr, NULL, net_service (sr)) OR updated;
         ELSE
            IF (sr.SUBTYPE = 'H')
            THEN
               h := hardware_service (sr, ours);
               updated := APPLY (sr, NULL, h) OR updated;
            ELSE
               IF (sr.SUBTYPE = 'R')
               THEN
                  updated :=
                     APPLY (sr, NULL, repair_service (sr, ours, h))
                     OR updated;
               ELSE
                  IF (sr.SUBTYPE = 'MR')
                  THEN
                     updated := APPLY (sr, NULL, mr_service (sr)) OR updated;
                  ELSE
                     IF (sr.SUBTYPE = 'S')
                     THEN
                        updated :=
                              APPLY (sr, sr.os, software_service (sr, ours))
                           OR updated;
                     ELSE
                        IF (sr.SUBTYPE = 'L')
                        THEN
                           updated :=
                                 APPLY (sr, sr.os,
                                        license_service (sr, ours))
                              OR updated;
                        ELSE
                           IF (sr.SUBTYPE = 'B')
                           THEN
                              updated :=
                                    APPLY (sr,
                                           sr.os_class,
                                           backup_service (sr)
                                          )
                                 OR updated;
                           else
                                --
                                -- The two new services were added to
                                -- support cluster charges
                                --
                                if (sr.subtype = 'C-S') then
                                    updated := apply(sr, null, cluster_slavenode_service(sr))
                                                or updated;
                                else
                                    if (sr.subtype = 'C-R') then
                                        updated := apply( sr
                                                            ,null
                                                            ,cluster_rack_service(sr)
                                                        ) or updated;
                                    else
                                        if (sr.subtype = 'C-H') then
                                            updated := apply( sr
                                                                ,null
                                                                ,cluster_headnode_service(sr)
                                                            ) or updated;
                                        end if;
                                    end if;
                                end if;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      END LOOP;

      /*
       * host priorities may change with no other affect on
       * the service list so we must do a comprehensive update
       * for the entire asset.  The minimum priority per shared
       * category gets 100% and the others get 0%.
       */
      UPDATE host_service
         SET pct = 0
       WHERE assetno = qassetno
         AND SHARED IS NOT NULL
         AND pct != 0
         AND (pri, SHARED, service_id) NOT IN (
                SELECT   MIN (pri), SHARED, service_id
                    FROM host_service hs
                   WHERE hs.assetno = qassetno
                     AND SHARED IS NOT NULL
                     AND host_service.assetno = hs.assetno
                GROUP BY service_id, SHARED);

      IF (SQL%ROWCOUNT > 0)
      THEN
         util.LOG ('set 0% for ' || SQL%ROWCOUNT || ' row(s) ' || qassetno);
         updated := TRUE;
      END IF;

      UPDATE host_service
         SET pct = 100
       WHERE assetno = qassetno
         AND SHARED IS NOT NULL
         AND pct != 100
         AND (pri, SHARED, service_id) IN (
                SELECT   MIN (pri), SHARED, service_id
                    FROM host_service hs
                   WHERE hs.assetno = qassetno
                     AND SHARED IS NOT NULL
                     AND host_service.assetno = hs.assetno
                GROUP BY service_id, SHARED);

      IF (SQL%ROWCOUNT > 0)
      THEN
         util.LOG ('set 100% for ' || SQL%ROWCOUNT || ' row(s) ' || qassetno
                  );
         updated := TRUE;
      END IF;
   END;

   /*
    *  Triggers invoked by changes to
    *  host_attr[hostname,attr,sense]
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF BLDG,DEPT,QUAL,RM,SUFFIX,WARRANTY_EXPIRE ON CAPEQUIP FOR EACH ROW
    */
   PROCEDURE hostattrchanged (ri ROWID, nhn hostname_t, ohn hostname_t)
   IS
   BEGIN
      trigdef.enqueue ('host_attr', ri, nhn, NULL, NULL, ohn, NULL, NULL);
   END;

   /*
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF BLDG,DEPT,QUAL,RM,SUFFIX,WARRANTY_EXPIRE ON CAPEQUIP
    */
   PROCEDURE hostattrchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;
   BEGIN
      c := trigdef.setup ('host_attr');

      WHILE (trigdef.another (c, r))
      LOOP
         hostattrrun (r.row_id, r.text1);
      END LOOP;
   END;

   PROCEDURE hostattrrun (ri ROWID, qhn hostname_t)
   IS
      CURSOR h
      IS
         SELECT UNIQUE assetno
                  FROM hoststab
                 WHERE hostname = qhn;
   BEGIN
      FOR hr IN h
      LOOP
         hostservicesupdate (hr.assetno);
      END LOOP;
   END;

   /*
    *  Redistribute the service charges for a host.  Called by the trigger whenever
    *  a specific host/service combination has been altered or for all services
    *  and hosts whenever the distribution has been altered.
    *
    *  N.B.  Caller *MUST* have synchronized on machtab.assetno
    *  prior to invocation.
    */
   PROCEDURE hostservicecharges (
      qassetno   assetno_t,
      prilo      hpri_t,
      prihi      hpri_t,
      idlo       service_id_t,
      idhi       service_id_t
   )
   IS
      CURSOR a
      IS
         SELECT   hs.service_id, hs.pri, hs.pct hpct, d.pct, d.ACCOUNT,
                  c.amount
             FROM host_service hs, COST c, param p, dist d, machtab h
            WHERE hs.assetno = qassetno
              AND hs.assetno = h.assetno
              AND h.dist = d.dist
              /*
               *  select the proper service and/or priority
               */
              AND hs.service_id >= idlo
              AND hs.service_id <= idhi
              AND hs.pri >= prilo
              AND hs.pri <= prihi
              /*
               * select the proper service rate in the current
               * charge period
               */
              AND c.service_id = hs.service_id
              AND p.charge_last >= c.period_begin
              AND (p.charge_last <= c.period_end OR c.period_end IS NULL)
         ORDER BY hs.service_id, hs.pri, d.pct DESC, d.account ;

      tpct      dpct_t;
      tamount   COST.amount%TYPE;
      amount    COST.amount%TYPE;
   BEGIN
      /* XXX sync needed */
      tpct := 0;
      tamount := 0;

      FOR ar IN a
      LOOP
         tpct := tpct + ar.pct;

         IF (tpct > 100)
         THEN
            raise_application_error (x.oops,
                                        'Total pct for '
                                     || qassetno
                                     || ' never matched 100.00 before '
                                     || tpct
                                    );
         END IF;

         IF (tpct = 100.00)
         THEN
            amount := ar.amount - tamount;
            tpct := 0;
            tamount := 0;
         ELSE
            amount := ROUND ((ar.pct / 100) * ar.amount, 2);
            tamount := tamount + amount;
         END IF;

         /*  We "know" host percentages are always either 0 or 100 */
         IF (ar.hpct > 0)
         THEN
            util.LOG (   qassetno
                      || ','
                      || ar.pri
                      || ' #'
                      || ar.service_id
                      || ' '
                      || ar.amount
                      || '@'
                      || ar.pct
                      || '%='
                      || amount
                     );

            INSERT INTO host_service_charge
                        (assetno, pri, ACCOUNT, charge, pct,
                         amount, service_id
                        )
                 VALUES (qassetno, ar.pri, ar.ACCOUNT, ar.amount, ar.pct,
                         amount, ar.service_id
                        );
         END IF;
      END LOOP;
   END;

   /*
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF assetno,pri,service_id,pct ON host_service FOR EACH ROW
    */
   PROCEDURE hostservicechanged (
      ri            ROWID,
      nassetno      assetno_t,
      npri          hpri_t,
      nservice_id   service_id_t,
      oassetno      assetno_t,
      opri          hpri_t,
      oservice_id   service_id_t
   )
   IS
   BEGIN
      trigdef.enqueue ('host_service',
                       ri,
                       nassetno,
                       NULL,
                       npri,
                       nservice_id,
                       oassetno,
                       NULL,
                       opri,
                       oservice_id
                      );
   END;

   /*
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF assetno,pri,service_id,pct ON host_service
    */
   PROCEDURE hostservicechanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;

      PROCEDURE handle (
         ri            ROWID,
         qassetno      assetno_t,
         qpri          hpri_t,
         qservice_id   service_id_t
      )
      IS
         an   assetno_t;
      BEGIN
         util.LOG (   'hostServiceChanges '
                   || qassetno
                   || ', '
                   || qpri
                   || ', '
                   || qservice_id
                  );

         /*
          *  Synchronize on asset
          */
         BEGIN
            SELECT     assetno
                  INTO an
                  FROM machtab
                 WHERE assetno = qassetno
            FOR UPDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               an := NULL;
         END;

         /*
          *  Purge the charge list for this asset/service combo.
          */
         DELETE FROM host_service_charge
               WHERE assetno = qassetno
                 AND pri = qpri
                 AND service_id = qservice_id;

         IF (ri IS NULL OR an IS NULL)
         THEN
            util.LOG ('purged ' || SQL%ROWCOUNT || ' obsolete charge rows');
         ELSE
            hostservicecharges (qassetno,
                                qpri,
                                qpri,
                                qservice_id,
                                qservice_id
                               );
         END IF;
      END;
   BEGIN
      c := trigdef.setup ('host_service');

      WHILE (trigdef.another (c, r))
      LOOP
         handle (r.row_id, r.text1, r.num1, r.num2);
      END LOOP;
   END;

   PROCEDURE hostserviceregen
   IS
      CURSOR c
      IS
         SELECT DISTINCT hs.ROWID, hs.assetno, hs.pri, hs.service_id
                    FROM host_service hs, host_service_charge hsc, COST c
                   WHERE hsc.service_id = c.service_id
                     AND hsc.charge != c.amount
                     AND hsc.assetno = hs.assetno
                     AND hsc.pri = hs.pri
                     AND hsc.service_id = hs.service_id;
   BEGIN
      FOR r IN c
      LOOP
         hostservicechanged (r.ROWID,
                             r.assetno,
                             r.pri,
                             r.service_id,
                             r.assetno,
                             r.pri,
                             r.service_id
                            );
      END LOOP;

      hostservicechanges;
   END;

   /*
    *  Triggers invoked
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF "ASSETNO", "OS", "PRI", "PROTOCOL" ON HOSTSTAB FOR EACH ROW
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF "ASSETNO", "CPUMODEL", "CPUTYPE" ON MACHTAB FOR EACH ROW
    *  machtab_attr
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF BLDG,DEPT,QUAL,RM,SUFFIX,WARRANTY_EXPIRE ON CAPEQUIP FOR EACH ROW
    */
   PROCEDURE hostservicecommonchanged (
      ri         ROWID,
      nassetno   assetno_t,
      oassetno   assetno_t
   )
   IS
   BEGIN
      trigdef.enqueue ('hostServices',
                       ri,
                       nassetno,
                       NULL,
                       NULL,
                       oassetno,
                       NULL,
                       NULL
                      );
   END;

   /*
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF "ASSETNO", "OS", "PRI", "PROTOCOL" ON HOSTSTAB
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF "ASSETNO", "CPUMODEL", "CPUTYPE" ON MACHTAB
    *  machtab_attr
    *  AFTER DELETE OR INSERT OR UPDATE
    *  OF BLDG,DEPT,QUAL,RM,SUFFIX,WARRANTY_EXPIRE ON CAPEQUIP
    */
   PROCEDURE hostservicecommonchanges
   IS
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;

      PROCEDURE handle (ri ROWID, qassetno assetno_t)
      IS
      BEGIN
         IF (ri IS NULL)
         THEN
            DELETE FROM host_service
                  WHERE assetno = qassetno;
         ELSE
            hostservicesupdate (qassetno);
         END IF;
      END;
   BEGIN
      c := trigdef.setup ('hostServices');

      WHILE (trigdef.another (c, r))
      LOOP
         handle (r.row_id, r.text1);
      END LOOP;
   END;

   PROCEDURE hostcharges (qassetno assetno_t)
   IS
   BEGIN
      util.LOG ('hostCharges ' || qassetno);

      DELETE FROM host_service_charge
            WHERE assetno = qassetno;

      hostservicecharges (qassetno,
                          hpri_min,
                          hpri_max,
                          service_id_min,
                          service_id_max
                         );
   END;

   /*
    * who_services management
    */
   PROCEDURE whoservicesupdate (qprinc princ_t)
   IS
      wprinc    who.princ%TYPE;

      CURSOR s
      IS
         SELECT   w.princ, s.SUBTYPE, w.attr, NVL (wa.sense, 'X') wattr,
                  ws.service_id present, w.service_id, ws.pct
             FROM who_attr wa, whoservices w, services s, who_service ws
            WHERE w.princ = wprinc
              AND w.service_id = s.ID
              AND w.service_id = ws.service_id(+)
              AND w.princ = ws.princ(+)
              AND wa.princ(+) = w.princ
              AND wa.attr(+) = w.attr
              AND s.monthly IS NOT NULL
         ORDER BY s.monthly;

      wpct      pct_t;
      updated   BOOLEAN          := FALSE;

      FUNCTION general_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         RESULT := TRUE;
         RETURN RESULT;
      END;

      FUNCTION afs_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         -- short-circuit afs service since only general service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;
         RETURN RESULT;

         IF (sr.wattr = '-')
         THEN
            RESULT := FALSE;
         ELSE
            RESULT := TRUE;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION print_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         -- short-circuit afs service since only general service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;
         RETURN RESULT;

         IF (sr.wattr = '-')
         THEN
            RESULT := FALSE;
         ELSE
            RESULT := TRUE;
         END IF;
         RETURN RESULT;

      END;

      FUNCTION dev_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         -- short-circuit afs service since only general service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;
         RETURN RESULT;

         IF (sr.wattr = '-')
         THEN
            RESULT := FALSE;
         ELSE
            RESULT := TRUE;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION purch_service (sr s%ROWTYPE)
         RETURN BOOLEAN
      IS
         RESULT   BOOLEAN;
      BEGIN
         -- short-circuit afs service since only general service is charged
         -- starting from FY2008 (2007-Jul-01)
         result := false;
         RETURN RESULT;

         IF (sr.wattr = '-')
         THEN
            RESULT := FALSE;
         ELSE
            RESULT := TRUE;
         END IF;

         RETURN RESULT;
      END;

      FUNCTION APPLY (sr s%ROWTYPE, sense BOOLEAN)
         RETURN BOOLEAN
      IS
      BEGIN
         IF (   (sense AND sr.present IS NOT NULL)
             OR (NOT sense AND sr.present IS NULL)
            )
         THEN
            /*
             * service is already present when expected or not
             * present when not expected - no action neeeded
            Util.log('NULL APPLY '||qprinc||','||sr.service_id);

             */
            updated := FALSE;
         ELSE
            IF (sense)
            THEN
               INSERT INTO who_service
                           (princ, service_id, pct
                           )
                    VALUES (qprinc, sr.service_id, 100
                           );

               util.LOG ('APPLY ' || qprinc || ',' || sr.service_id);
            ELSE
               DELETE FROM who_service
                     WHERE princ = qprinc AND service_id = sr.service_id;

               util.LOG ('UNAPPLY ' || qprinc || ',' || sr.service_id);
            END IF;

            updated := TRUE;
         END IF;

         RETURN updated;
      END;
   BEGIN
      util.LOG ('whoServicesUpdate ' || qprinc);

      /*
       *  Synchronize on principal (not really an update)
       *
       *  As with machines, if the query yields no rows, the person
       *  name is changing and we do nothing now but delete all
       *  records for the old name by setting the principal
       *  name used in the query to null
       */
      BEGIN
         SELECT     princ, pct
               INTO wprinc, wpct
               FROM who
              WHERE princ = qprinc
         FOR UPDATE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            wprinc := NULL;
      END;

      /*
       *   Purge any monthly services which no longer map to this person (say
       *   because the type or some other characteristic which
       *   supplied them originally has since changed or the person
       *   has been deleted).
       */
      DELETE FROM who_service
            WHERE princ = qprinc
              AND service_id NOT IN (
                                  SELECT service_id
                                    FROM whoservices w
                                   WHERE w.princ = qprinc
                                  UNION
                                  SELECT ID
                                    FROM services
                                   WHERE monthly IS NULL);

      IF (SQL%ROWCOUNT > 0)
      THEN
         util.LOG (SQL%ROWCOUNT || ' obsolete services purged ' || qprinc);
         updated := TRUE;
      END IF;

      FOR sr IN s
      LOOP
         /*
         dbms_output.put_line(sr.hostname||','||sr.pri||','||sr.subtype||','||sr.service_id);
         */
         IF (sr.SUBTYPE = 'G')
         THEN
            updated := APPLY (sr, general_service (sr)) OR updated;
         ELSE
            IF (sr.SUBTYPE = 'AFS')
            THEN
               updated := APPLY (sr, afs_service (sr)) OR updated;
            ELSE
               IF (sr.SUBTYPE = 'P')
               THEN
                  updated := APPLY (sr, print_service (sr)) OR updated;
               ELSE
                  IF (sr.SUBTYPE = 'D')
                  THEN
                     updated := APPLY (sr, dev_service (sr)) OR updated;
                  ELSE
                     IF (sr.SUBTYPE = 'TPI')
                     THEN
                        updated := APPLY (sr, purch_service (sr)) OR updated;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      END LOOP;
   END;

   /*
    *  Redistribute the service charges for a user.  Called by the trigger whenever
    *  a specific service has been altered or for all services
    *  whenever the distribution has been altered.
    *
    *  N.B.  Caller *MUST* have synchronized on who.princ
    *  prior to invocation.
    */
   PROCEDURE whoservicecharges (
      qprinc   princ_t,
      idlo     service_id_t,
      idhi     service_id_t,
      wpct     pct_t
   )
   IS
      CURSOR a
      IS
         SELECT   ws.service_id, d.pct, d.ACCOUNT, c.amount, s.monthly
                    ,w.dist_src, w.charge_by
             FROM who_service ws, COST c, param p, dist d, who w, services s
            WHERE ws.princ = qprinc
              AND ws.princ = w.princ
              AND w.dist = d.dist
              AND ws.service_id = s.ID
              /*
               *  select the proper service and/or priority
               */
              AND ws.service_id >= idlo
              AND ws.service_id <= idhi
              /*
               * select the proper service rate in the current
               * charge period
               */
              AND c.service_id = ws.service_id
              AND p.charge_last >= c.period_begin
              AND (p.charge_last <= c.period_end OR c.period_end IS NULL)
         ORDER BY ws.service_id, d.pct DESC, d.account ;

        tpct      dpct_t;
        tamount   COST.amount%TYPE;
        amount    COST.amount%TYPE;
        prorate   NUMBER (5, 4);
        l_distnames_r    dist_names%ROWTYPE;
        l_dn_pct        dist_names.pct%TYPE;
   BEGIN
      tpct := 0;
      tamount := 0;

        begin
            select  *
              into l_distnames_r
              from dist_names d
             where d.name=integrity.projectPseudoEffort
               and d.subname=qprinc;

            l_dn_pct := nvl(l_distnames_r.pct, 100);
        exception
            when no_data_found then
                l_dn_pct := 100;
        end;

      FOR ar IN a
      LOOP
         tpct := tpct + ar.pct;

         /*
          *  Adjust the effective % after accumulating it from the
          *  distribution so that the accumulation will reach 100%
          *  but the adjusted value is used for compuation and
          *  stored in the table.  Only monthly services are
          *  prorated.
          */
         IF (ar.monthly IS NULL)
         THEN
            prorate := 1;
         ELSE
            -- should be data driven but leave it as hardcoded for now.
            if ar.charge_by is null and ar.dist_src not in ('P','X') then
                -- distribution from payroll feeders (tmcd or labor)
                --prorate := (wpct / 100) * (l_dn_pct / 100);

                -- To be able to handle master students/collaborators
                -- who could have labor (full-time) data.
                if upper(ar.dist_src) = ar.dist_src then
                    -- full-time
                    prorate := (wpct / 100) * (l_dn_pct / 100);
                else
                    -- part-timers, ignore who.pct (which should be 4% for FY08)
                    -- and use whatever
                    -- percentage we get from payroll data.
                    prorate := (l_dn_pct / 100);
                end if;

                --prorate := (l_dn_pct / 100);
            else
                -- not follow payroll or follow payroll but no payroll data
                prorate := (wpct / 100);
            end if;
         END IF;

         ar.pct := ar.pct * prorate;

         IF (tpct > 100)
         THEN
            raise_application_error (x.oops,
                                        'Total pct for '
                                     || qprinc
                                     || ' never matched 100.00 before '
                                     || tpct
                                    );
         END IF;

         IF (tpct = 100.00)
         THEN
            /*
             *  ar.amount must also be adjust by the effective
             *  percentage (tamount is an adjusted total).
             */
            amount := ar.amount * prorate - tamount;
            tpct := 0;
            tamount := 0;
         ELSE
            amount := ROUND ((ar.pct / 100) * ar.amount, 2);
            tamount := tamount + amount;
         END IF;

         util.LOG (   qprinc
                   || ', #'
                   || ar.service_id
                   || ' '
                   || ar.amount
                   || '@'
                   || ar.pct
                   || '%='
                   || amount
                  );

         INSERT INTO who_service_charge
                     (princ, ACCOUNT, charge, pct, amount,
                      service_id
                     )
              VALUES (qprinc, ar.ACCOUNT, ar.amount, ar.pct, amount,
                      ar.service_id
                     );
      END LOOP;
   END;

   PROCEDURE whoservicechanged (
      ri            ROWID,
      nprinc        princ_t,
      nservice_id   service_id_t,
      oprinc        princ_t,
      oservice_id   service_id_t
   )
   IS
   /*
    *   AFTER DELETE OR INSERT OR UPDATE
    *     OF princ,service_id,pct ON host_service FOR EACH ROW
    */
   BEGIN
      trigdef.enqueue ('who_service',
                       ri,
                       nprinc,
                       NULL,
                       nservice_id,
                       oprinc,
                       NULL,
                       oservice_id
                      );
   END;

   PROCEDURE whoservicechanges
   IS
      /*
      *   AFTER DELETE OR INSERT OR UPDATE
      *     OF princ,service_id,pct ON host_service
       */
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;

      PROCEDURE handle (ri ROWID, qprinc princ_t, qservice_id service_id_t)
      IS
         wpct   who.pct%TYPE;
      BEGIN
         util.LOG ('whoServiceChanges ' || qprinc || ', ' || qservice_id);

         /*
          *  Synchronize on principal
          */
         BEGIN
            SELECT     pct
                  INTO wpct
                  FROM who
                 WHERE princ = qprinc
            FOR UPDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               wpct := NULL;
         END;

         /*
          *  Purge current charges for this service
          */
         DELETE FROM who_service_charge
               WHERE princ = qprinc AND service_id = qservice_id;

         IF (ri IS NULL OR wpct IS NULL)
         THEN
            util.LOG ('purged ' || SQL%ROWCOUNT || ' obsolete charge rows');
         ELSE
            whoservicecharges (qprinc, qservice_id, qservice_id, wpct);
         END IF;
      END;
   BEGIN
      c := trigdef.setup ('who_service');

      WHILE (trigdef.another (c, r))
      LOOP
         handle (r.row_id, r.text1, r.num1);
      END LOOP;
   END;

   PROCEDURE whoserviceregen
   IS
      CURSOR c
      IS
         SELECT DISTINCT ws.ROWID, ws.princ, ws.service_id
                    FROM who_service ws, who_service_charge wsc, COST c
                   WHERE wsc.service_id = c.service_id
                     AND wsc.charge != c.amount
                     AND wsc.princ = ws.princ
                     AND wsc.service_id = ws.service_id;
   BEGIN
      FOR r IN c
      LOOP
         whoservicechanged (r.ROWID,
                            r.princ,
                            r.service_id,
                            r.princ,
                            r.service_id
                           );
      END LOOP;

      whoservicechanges;
   END;

   PROCEDURE whocharges (qprinc princ_t, wpct pct_t)
   IS
   BEGIN
      util.LOG ('whoCharges ' || qprinc || '@' || wpct);

      DELETE FROM who_service_charge
            WHERE princ = qprinc;

      whoservicecharges (qprinc, service_id_min, service_id_max, wpct);
   END;

   PROCEDURE whoservicecommonchanged (ri ROWID, nprinc princ_t, oprinc princ_t)
   IS
   /*
    *   AFTER DELETE OR INSERT OR UPDATE
    *     OF , ON host_service FOR EACH ROW
    */
   BEGIN
      trigdef.enqueue ('whoServices',
                       ri,
                       nprinc,
                       NULL,
                       NULL,
                       oprinc,
                       NULL,
                       NULL
                      );
   END;

   PROCEDURE whoservicecommonchanges
   IS
      /*
       * AFTER DELETE OR INSERT OR UPDATE
       *   OF attr,princ,sense ON who_attr
       * AFTER DELETE OR INSERT OR UPDATE
       *   OF princ,type ON who
       */
      c   trigdef.trigdef_cursor_t;
      r   trigdef.trigdef_t;

      PROCEDURE handle (ri ROWID, qprinc princ_t)
      IS
      BEGIN
         IF (ri IS NULL)
         THEN
            DELETE FROM who_service
                  WHERE princ = qprinc;
         ELSE
            whoservicesupdate (qprinc);
         END IF;
      END;
   BEGIN
      c := trigdef.setup ('whoServices');

      WHILE (trigdef.another (c, r))
      LOOP
         handle (r.row_id, r.text1);
      END LOOP;
   END;

   PROCEDURE whoattrchanges
   IS
      /*
       * AFTER DELETE OR INSERT OR UPDATE
       *   OF attr,princ,sense ON who_attr
       */
      p   who_attr.princ%TYPE;
   BEGIN
      /*
       *  Enforce additional who_attr data integrity.  Short-term development service
       *  may not be dropped without also dropping long-term development service.
       *
       *  (GROUP BY below so that SELECT yields no rows for MIN(princ) when no rows
       *  were selected)
       */
      SELECT   /*+ MERGE_AJ*/
               MIN (princ)
          INTO p
          FROM who_attr
         WHERE attr = 'D-S'
           AND sense = '-'
           AND princ NOT IN (SELECT princ
                               FROM who_attr
                              WHERE attr = 'D-L' AND sense = '-')
      GROUP BY attr;

      raise_application_error
                 (x.who_attr_dev,
                     p
                  || ': may not remove short-term and keep long-term development'
                 );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;
END;
/
Show Errors
