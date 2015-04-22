
-- To be inserted into integrity header
	procedure whoPctChanged(ri IN ROWID, nprinc IN VARCHAR2, oprinc IN VARCHAR2);
	procedure whoPctChanges;

-- To be inserted into integrity package body
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
				util.LOG ('Process who ' || ri || ', ' || w.princ);
				costing.whoCharges(w.princ, w.pct);
			END IF;
		END LOOP;
		traceit.log(constDEBUG_LEVELA, 'Exit whoPctChanges');
	end whoPctChanges;

-- Make the following changes in integrity body
in whodist(...) look for the following IF statement
		IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct)

in the ELSE part of the IF, we need to make sure when qpct!=wpct, Costing.whoCharges does not get called 
since it will be called by the new triggers added. (even though it does not hurt to call it twice.)
From
-----
		IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct)
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
			IF (wdist IS NULL AND ndist IS NOT NULL)
			THEN
				costing.whoservicesupdate (wprinc);
			END IF;

			costing.whocharges (wprinc, qpct);
		END IF;
----
TO
----
		IF (ndist = wdist AND nsrc = wdist_src AND qpct = wpct)
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
			IF (wdist IS NULL AND ndist IS NOT NULL)
			THEN
				costing.whoservicesupdate (wprinc);
			END IF;

			IF (qpct != wpct) THEN
				costing.whocharges (wprinc, qpct);
			END IF;
		END IF;
