--$Header: c:\\Repository/sql/oracle/plsql/utils/strip_string.sql,v 1.2 2006/01/19 20:43:58 yangl Exp $

-- For testing
-- BEGIN
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', 'e'));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string (NULL, 'e'));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', 'e', NULL));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', NULL));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', 'e', 'e'));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', 'e', 't'));
--   DBMS_OUTPUT.put_line (strip_string_pkg.strip_string ('Steven Feuerstein', 'etn'));
-- END;
--
CREATE OR REPLACE package strip_string_pkg
as
	FUNCTION strip_string (
			 p_expression_in    IN   VARCHAR2
			,p_characters_in    IN   VARCHAR2
			,p_placeholder_in   IN   VARCHAR2 DEFAULT CHR(1)
		) RETURN VARCHAR2;
	FUNCTION strip_string_10g (
					 p_string_in               IN   VARCHAR2
					,p_strip_characters_in     IN   VARCHAR2
				)
	RETURN VARCHAR2;
end strip_string;
.
run
show error

create or replace package body strip_string_pkg
AS
BEGIN
	FUNCTION strip_string (
			 p_expression_in    IN   VARCHAR2
			,p_characters_in    IN   VARCHAR2
			,p_placeholder_in   IN   VARCHAR2 DEFAULT CHR(1)
		) RETURN VARCHAR2
	is
	begin
		RETURN TRANSLATE (	p_expression_in
					, p_placeholder_in || p_characters_in
					, p_placeholder_in
					);
	end strip_string;

	FUNCTION strip_string_10g (
					 p_string_in               IN   VARCHAR2
					,p_strip_characters_in     IN   VARCHAR2
				)
	RETURN VARCHAR2
	IS
		-- With REGEXP_REPLACE, each character to be replaced with NULL,
		-- must be followed by a "*".
		
		c_asterisk              CONSTANT CHAR (1) := '*';
		l_strip_characters      VARCHAR2 (32767);
		l_length                PLS_INTEGER;
		l_character             VARCHAR2 (2);
	BEGIN
		l_length := LENGTH (p_strip_characters_in);
		
		IF l_length > 0
		THEN
			FOR l_index IN 1 .. l_length
			LOOP
				l_character := SUBSTR (p_strip_characters_in, l_index, 1);
				
				IF l_character = c_asterisk
				THEN
				   l_character := '\' || c_asterisk ;
				END IF;
				
				l_strip_characters :=
				      l_strip_characters
				   || l_character
				   || c_asterisk;
			END LOOP;
		END IF;
		
		RETURN regexp_replace (p_string_in, l_strip_characters);
	END strip_string;
END strip_string;
.
run
show error
