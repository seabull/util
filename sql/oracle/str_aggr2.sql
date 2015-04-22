-- $Id: str_aggr2.sql,v 1.3 2005/06/30 20:39:21 yangl Exp $
--
/***
	You can pass object type in place of scalar parameter to 
	aggregate functions and bypass restriction on passing in 
	multiple values. Kind of worries me why restriction was 
	there in the first place though...

--Usage:
	SQL> SELECT concat_all (concat_expr (deptno, '|')) deptnos,
	concat_all (concat_expr (dname, ',')) dnames
	FROM   dept;

	DEPTNOS       DNAMES
	------------- ------------------------------------
	10|20|30|40   ACCOUNTING,RESEARCH,SALES,OPERATIONS

--Improvement:
	If you change the definition of concat_expr from

	CREATE OR REPLACE TYPE concat_expr AS OBJECT (
		str VARCHAR2 (4000),
		del VARCHAR2 (4000),
	);
	/

	to the following, you even can concatenate distinct strings. 

	CREATE OR REPLACE TYPE concat_expr AS OBJECT (
		str VARCHAR2 (4000),
		del VARCHAR2 (4000),
		MAP MEMBER FUNCTION mapping_function RETURN VARCHAR2
	);
	/

	CREATE OR REPLACE TYPE BODY concat_expr AS
		MAP MEMBER FUNCTION mapping_function RETURN VARCHAR2
		IS
		BEGIN
			RETURN str||del;
		END mapping_function;
	END;
	/

***/

drop function concat_all;
drop type body concat_all_ot;
drop type concat_all_ot;
drop type body concat_expr;
drop type concat_expr;

CREATE OR REPLACE TYPE concat_expr AS OBJECT (
	str VARCHAR2(4000)
	,del VARCHAR2(4000)
	,MAP MEMBER FUNCTION mapping_function RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY concat_expr AS
	MAP MEMBER FUNCTION mapping_function RETURN VARCHAR2
	IS
	BEGIN
		RETURN str||del;
	END mapping_function;
END;
/

CREATE OR REPLACE TYPE concat_all_ot AS OBJECT (
	str VARCHAR2(4000)
	,del VARCHAR2(4000)

	,STATIC FUNCTION odciaggregateinitialize (
				sctx IN OUT concat_all_ot
			)
		RETURN NUMBER
	,MEMBER FUNCTION odciaggregateiterate (
				SELF IN OUT concat_all_ot
				,ctx IN concat_expr
				)
		RETURN NUMBER

	,MEMBER FUNCTION odciaggregateterminate (
			SELF IN concat_all_ot
			,returnvalue OUT VARCHAR2
			,flags IN NUMBER)
		RETURN NUMBER

	,MEMBER FUNCTION odciaggregatemerge (
			SELF IN OUT concat_all_ot
			,ctx2 concat_all_ot)
		RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY concat_all_ot
AS
	STATIC FUNCTION odciaggregateinitialize (
			sctx IN OUT concat_all_ot)
		RETURN NUMBER
	IS
	BEGIN
		sctx := concat_all_ot (NULL, NULL);
		RETURN odciconst.success;
	END;

	MEMBER FUNCTION odciaggregateiterate (
			SELF IN OUT concat_all_ot
			,ctx IN concat_expr)
		RETURN NUMBER
	IS
	BEGIN
		IF instr(ctx.del||SELF.str||ctx.del, ctx.del||ctx.str||ctx.del) = 0 
		THEN
			IF (SELF.str IS NOT NULL) 
			THEN
				SELF.str := SELF.str || ctx.del;
			END IF;
			SELF.str := SELF.str || ctx.str;
		END IF;
		RETURN odciconst.success;
	END;

	MEMBER FUNCTION odciaggregateterminate (
			SELF IN concat_all_ot
			,returnvalue OUT VARCHAR2
			,flags IN NUMBER)
		RETURN NUMBER
	IS
	BEGIN
		returnvalue := SELF.str;
		RETURN odciconst.success;
	END;

	MEMBER FUNCTION odciaggregatemerge (
			SELF IN OUT concat_all_ot
			,ctx2 IN concat_all_ot)
		RETURN NUMBER
	IS
	BEGIN
		IF SELF.str IS NOT NULL THEN
			SELF.str := SELF.str || SELF.del;
		END IF;
		SELF.str := SELF.str || ctx2.str;
		RETURN odciconst.success;
	END;
END;
/

CREATE OR REPLACE FUNCTION concat_all (
		ctx IN concat_expr
		)
	RETURN VARCHAR2 DETERMINISTIC PARALLEL_ENABLE
	AGGREGATE USING concat_all_ot;
/

