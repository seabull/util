-- $Header: c:\\Repository/sql/oracle/plsql/utils/str2list/str2list.pkg.sql,v 1.1 2006/01/19 21:12:38 yangl Exp $
--

CREATE OR REPLACE PACKAGE str2list
-- Copyright 2000 Steven Feuerstein 
--                steven@stevenfeuerstein.com
-- Improved by Paul Sharples (pjbs@eclipse.co.uk) on May 17th, 2001
IS
	-- Call signature #1. Uses parse call #2 using utility funcs specified
	-- at foot of package header. If datatype is not one of the supported
	-- types, then parse form #2 *must* be used. Steven's original function
	-- allows record types to be assigned; this one is limited to the
	-- predefined append_*_procs. (If you're puissant enough to define
	-- a collection of records, you'll have no trouble with the idea of
	-- encapsulating it further by providing your own append procedure!)
	PROCEDURE parse (
	   str             IN   VARCHAR2,
	   delim           IN   VARCHAR2,
	   pkg             IN   VARCHAR2,
	   coll            IN   VARCHAR2,
	   datatype        IN   VARCHAR2 := 'VARCHAR2(32767)',
	   extend_needed        BOOLEAN := FALSE
	);

	-- Call signature #2. The raw procedure.
	PROCEDURE parse (
	   str          IN   VARCHAR2,
	   delim        IN   VARCHAR2,
	   pkg          IN   VARCHAR2,
	   appendproc   IN   VARCHAR2,
	                           /* pkg.appendproc (oneval); */
	   deleteproc   IN   VARCHAR2,
	        /* pkg.deleteproc (onerow); or pkg.deleteproc; */
	   datatype     IN   VARCHAR2
	);

	PROCEDURE showlist (pkg IN VARCHAR2, coll IN VARCHAR2);

	PROCEDURE showlist (
	   pkg            IN   VARCHAR2,
	   firstrowproc   IN   VARCHAR2,
	   nextrowproc    IN   VARCHAR2,
	   getvalfunc     IN   VARCHAR2,
	   showproc       IN   VARCHAR2 := 'pl',
	   datatype       IN   VARCHAR2 := 'VARCHAR2(32767)'
	);

	PROCEDURE delete_coll;

	-- Overloaded append/delete utility funcs. 
	PROCEDURE append_ext_coll (val IN VARCHAR2);

	PROCEDURE append_ext_coll (val IN NUMBER);

	PROCEDURE append_ext_coll (val IN DATE);

	PROCEDURE append_ext_coll (val IN BOOLEAN);

	PROCEDURE append_indtab_coll (val IN VARCHAR2);

	PROCEDURE append_indtab_coll (val IN NUMBER);

	PROCEDURE append_indtab_coll (val IN DATE);

	PROCEDURE append_indtab_coll (val IN BOOLEAN);
END str2list;
/
show error

CREATE OR REPLACE PACKAGE BODY str2list
IS
	/****** Package variable alert *******/
	-- Used by overloaded utility procs to create dynamic append statement
	-- Assigned to by Parse #1
	collection_name   VARCHAR2 (100);

	PROCEDURE disperr (str IN VARCHAR2)
	IS
	BEGIN
		pl ('Compilation/Execution Error:');
		pl (SQLERRM);
		pl ('In:');
		pl (str);
	END;

	PROCEDURE parse (
		str             IN   VARCHAR2,
		delim           IN   VARCHAR2,
		pkg             IN   VARCHAR2,
		coll            IN   VARCHAR2,
		datatype        IN   VARCHAR2 := 'VARCHAR2(32767)',
		extend_needed        BOOLEAN := FALSE
	)
	IS
		append_proc   VARCHAR2 (100);
		dynblock      VARCHAR2 (32767);
	BEGIN
		-- Sets up package variable for append and delete procs to work with
		collection_name :=    pkg
		                   || '.'
		                   || coll;

		IF extend_needed
		THEN
			-- Nested table or VARRAY
			append_proc := 'append_ext_coll';
		ELSE
			-- Index-by collection
			append_proc := 'append_indtab_coll';
		END IF;

		dynblock := '	BEGIN
					str2list.parse (:str, :delim, :pkg, :appendproc, :deleteproc, :datatype);
				END;';
		EXECUTE IMMEDIATE dynblock
			USING str
				,delim
				,'str2list'
				,append_proc
				,'delete_coll'
				,datatype;
	EXCEPTION
		WHEN OTHERS THEN
			disperr (dynblock);
	END;

	PROCEDURE parse (
			str          IN   VARCHAR2,
			delim        IN   VARCHAR2,
			pkg          IN   VARCHAR2,
			appendproc   IN   VARCHAR2,
			deleteproc   IN   VARCHAR2,
			datatype     IN   VARCHAR2
	)
	IS
		dynblock   VARCHAR2 (32767);
	BEGIN
		dynblock :=
		         'DECLARE 
		      v_loc PLS_INTEGER;
		      v_startloc PLS_INTEGER := 1;
		      v_item '
		      || datatype
		      || ';
		    BEGIN 
		       '
		      || pkg
		      || '.'
		      || deleteproc
		      || ';
		       IF :str IS NOT NULL 
		       THEN 
		          LOOP
		             v_loc := INSTR (:str, :delim, v_startloc);
		             IF v_loc = v_startloc
		             THEN
		                v_item := NULL;
		             ELSIF v_loc = 0
		             THEN
		                v_item := SUBSTR (:str, v_startloc);
		             ELSE
		                v_item := SUBSTR (:str, v_startloc, v_loc - v_startloc);
		             END IF;
		             '
		      || pkg
		      || '.'
		      || appendproc
		      || '( v_item );
		             IF v_loc = 0
		             THEN
		                EXIT;
		             ELSE 
		                v_startloc := v_loc + 1;
		             END IF;
		          END LOOP;
		       END IF;
		    END;';
		EXECUTE IMMEDIATE dynblock USING str, delim;
	EXCEPTION
		WHEN OTHERS THEN
			disperr (dynblock);
	END;

	PROCEDURE showlist (pkg IN VARCHAR2, coll IN VARCHAR2)
	IS
		collname   VARCHAR2 (100)   :=    pkg
		                               || '.'
		                               || coll;
		dynblock   VARCHAR2 (32767);
	BEGIN
		dynblock :=
		         'DECLARE 
		      indx PLS_INTEGER := '
		      || collname
		      || '.FIRST;
		      v_startloc PLS_INTEGER := 1;
		      v_item VARCHAR2(32767);
		    BEGIN 
		       LOOP
		          EXIT WHEN indx IS NULL;
		          pl ('
		      || collname
		      || '(indx));
		          indx := '
		      || collname
		      || '.NEXT (indx);
		       END LOOP;
		    END;';
		EXECUTE IMMEDIATE dynblock;
	EXCEPTION
		WHEN OTHERS THEN
			disperr (dynblock);
	END;

	PROCEDURE showlist (
			pkg            IN   VARCHAR2,
			firstrowproc   IN   VARCHAR2,
			nextrowproc    IN   VARCHAR2,
			getvalfunc     IN   VARCHAR2,
			showproc       IN   VARCHAR2 := 'pl',
			datatype       IN   VARCHAR2 := 'VARCHAR2(32767)'
	)
	IS
		dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=
	            'DECLARE 
	         indx PLS_INTEGER := '
	         || pkg
	         || '.'
	         || firstrowproc
	         || ';
	         v_startloc PLS_INTEGER := 1;
	         v_item '
	         || datatype
	         || ';
	       BEGIN 
	          LOOP
	             EXIT WHEN indx IS NULL;'
	         || showproc
	         || ' ('
	         || pkg
	         || '.'
	         || getvalfunc
	         || '(indx));
	             indx := '
	         || pkg
	         || '.'
	         || nextrowproc
	         || '(indx);
	          END LOOP;
	       END;';
	   EXECUTE IMMEDIATE dynblock;
	EXCEPTION
	   WHEN OTHERS
	   THEN
	      disperr (dynblock);
	END;

	
	/* ---- Utility Procs -------------------------------------------------------*/

	-- Called by parse #2 prior to parsing str
	PROCEDURE delete_coll
	IS
	   dynblock   VARCHAR2 (2000);
	BEGIN
	   dynblock :=
	             'BEGIN '
	          || collection_name
	          || '.DELETE; END;';
	   EXECUTE IMMEDIATE dynblock;
	END delete_coll;

	-- One of these is called by parse #2 for each element found in str

	PROCEDURE append_ext_coll (val IN VARCHAR2)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '.EXTEND;'
	               || collection_name
	               || '('
	               || collection_name
	               || '.LAST) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_ext_coll;

	PROCEDURE append_ext_coll (val IN NUMBER)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '.EXTEND;'
	               || collection_name
	               || '('
	               || collection_name
	               || '.LAST) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_ext_coll;

	PROCEDURE append_ext_coll (val IN DATE)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '.EXTEND;'
	               || collection_name
	               || '('
	               || collection_name
	               || '.LAST) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_ext_coll;

	PROCEDURE append_ext_coll (val IN BOOLEAN)
	IS
	   dynblock      VARCHAR2 (32767);
	   string_bool   VARCHAR2 (10);
	BEGIN
	   IF val
	   THEN
	      string_bool := 'TRUE';
	   ELSE
	      string_bool := 'FALSE';
	   END IF;

	   dynblock :=    'BEGIN '
	               || collection_name
	               || '.EXTEND;'
	               || collection_name
	               || '('
	               || collection_name
	               || '.LAST) := '
	               || string_bool
	               || ';
	      END;';
	   EXECUTE IMMEDIATE dynblock;
	END append_ext_coll;

	PROCEDURE append_indtab_coll (val IN VARCHAR2)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '(NVL ('
	               || collection_name
	               || '.LAST, 0) + 1) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_indtab_coll;

	PROCEDURE append_indtab_coll (val IN NUMBER)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '(NVL ('
	               || collection_name
	               || '.LAST, 0) + 1) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_indtab_coll;

	PROCEDURE append_indtab_coll (val IN DATE)
	IS
	   dynblock   VARCHAR2 (32767);
	BEGIN
	   dynblock :=    'BEGIN '
	               || collection_name
	               || '(NVL ('
	               || collection_name
	               || '.LAST, 0) + 1) := :val;
	      END;';
	   EXECUTE IMMEDIATE dynblock USING val;
	END append_indtab_coll;

	PROCEDURE append_indtab_coll (val IN BOOLEAN)
	IS
	   dynblock      VARCHAR2 (32767);
	   string_bool   VARCHAR2 (10);
	BEGIN
	   IF val
	   THEN
	      string_bool := 'TRUE';
	   ELSE
	      string_bool := 'FALSE';
	   END IF;

	   dynblock :=    'BEGIN '
	               || collection_name
	               || '(NVL ('
	               || collection_name
	               || '.LAST, 0) + 1) := '
	               || string_bool
	               || ';
	      END;';
	   EXECUTE IMMEDIATE dynblock;
	END append_indtab_coll;
END str2list;
/
show error
