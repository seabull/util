CREATE OR REPLACE PACKAGE CTRL_SCHEMA_USER
AS
/*
 *  NAME    : CTRL_SCHEMA_USER
 *  PURPOSE : Package Header
 */
PROCEDURE NewLine                    
        ( ioString         IN OUT LONG,
          iString          IN VARCHAR2);
PROCEDURE ExecDynSQL                 
        ( vDynSQL          IN LONG);
FUNCTION  IS_USER                    
        ( iUser            IN VARCHAR2) RETURN BOOLEAN;
FUNCTION  IS_TABLESPACE              
        ( iTSName          IN VARCHAR2, 
          iTSType          IN VARCHAR2) RETURN BOOLEAN;
PROCEDURE GET_FILEPATH               
        ( ofilepath        OUT VARCHAR2);
PROCEDURE CREATE_USER                
        ( iOwner           IN VARCHAR2,
          iPassword        IN VARCHAR2,
          iTSName          IN VARCHAR2,
          iTempTSName      IN VARCHAR2); 
PROCEDURE CREATE_USER                
        ( iOwner           IN VARCHAR2);
PROCEDURE CREATE_USER_PRIVS          
        ( iOwner           IN VARCHAR2,
          iTSName          IN VARCHAR2,
          iTempTSName      IN VARCHAR2);
END CTRL_SCHEMA_USER;
/

/*
 *  NAME    : CTRL_SCHEMA_USER
 *  PURPOSE : Package Body
 */
CREATE OR REPLACE PACKAGE BODY CTRL_SCHEMA_USER
AS
vDynSQL      LONG;
filepath     VARCHAR2(513);
 
/*
 *  NAME    : NewLine
 *  PURPOSE : This procedure is used to build a SQL statement to execute. 
 *            It appends a new line of code and a new line character each time called.
 *            This is just easier for me instead of concatenating many lines of code
 *            and trying to maintain some format to it by putting carriage returns inline. 
 *            
 */
PROCEDURE NewLine 
( ioString     IN OUT LONG,
  iString      VARCHAR2) 
AS
BEGIN
  ioString := ioString||iString||CHR(10);
END NewLine;

/*
 *  NAME    : ExecDynSQL
 *  PURPOSE : Execute some Dynamic SQL.
 *            Having one central location to execute SQL allows you to have
 *            one place to error trap as well. 
 */
PROCEDURE ExecDynSQL 
( vDynSQL      IN LONG)
AS
BEGIN
  EXECUTE IMMEDIATE vDynSQL;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20000, 'ExecDynSQL:'||
                                     'SQLCODE  :'||SQLCODE||
                                     ' SQLERRM :'||SQLERRM);
END ExecDynSQL;

/*
 *  NAME    : IS_USER
 *  PURPOSE : Check to see if the user already exists in the database.
 *            Returns TRUE if user is found in dba_users view.
 */
FUNCTION IS_USER 
( iUser VARCHAR2) RETURN BOOLEAN IS
v_username      VARCHAR2(30);
BEGIN
  SELECT username INTO v_username 
    FROM dba_users WHERE UPPER(username) = UPPER(iUser);
  RETURN UPPER(v_username) = UPPER(iUser);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END IS_USER;

/*
 *  NAME    : IS_TABLESPACE
 *  PURPOSE : Check to see if tablespace already exists in the database.
 *            Returns TRUE if tablespace is found.
 */
FUNCTION IS_TABLESPACE 
( iTSName VARCHAR2, iTSType VARCHAR2) RETURN BOOLEAN IS
v_tablespace_name        VARCHAR2(30) := NULL;
BEGIN
  SELECT tablespace_name INTO v_tablespace_name 
    FROM dba_tablespaces
   WHERE UPPER(tablespace_name) = UPPER(iTSName)
     AND UPPER(contents)        = UPPER(iTSType);
  RETURN UPPER(v_tablespace_name) = UPPER(iTSName);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END IS_TABLESPACE;

/*
 *  NAME    : GET_FILEPATH
 *  PURPOSE : Get a valid file path to create tablespaces.
 */
PROCEDURE GET_FILEPATH 
( ofilepath OUT VARCHAR2)
AS
BEGIN
SELECT DISTINCT decode(instr(name,':',1),0, 
                substr(name,1,instr(name,'/',-1)), 
                substr(name,1,instr(name,'\',-1)))
  INTO ofilepath
  FROM v$datafile WHERE rownum = 1;
/*'*/
END GET_FILEPATH;

/*
 *  NAME    : CREATE_USER
 *  PURPOSE : Call this procedure if you want to create a user with a 
 *            predefined default tablespace and default temporary tablespace.
 */
PROCEDURE CREATE_USER 
( iOwner       IN VARCHAR2) 
AS
BEGIN
  GET_FILEPATH(filepath);
  /* If tablespace does not exist then create one */
  IF NOT IS_TABLESPACE('DFLT_USER_TS','PERMANENT') THEN
    ExecDynSQL('CREATE TABLESPACE DFLT_USER_TS DATAFILE '''||
                filepath||'DFLTUSERTS01.DBF'' SIZE 1024M');
  END IF;
  /* If tablespace does not exist then create one */
  IF NOT IS_TABLESPACE('TMPY_USER_TS','TEMPORARY') THEN
    ExecDynSQL('CREATE TEMPORARY TABLESPACE TMPY_USER_TS TEMPFILE '''||
                filepath||'TMPYUSERTS01.DBF'' SIZE 300M');
  END IF;
  CREATE_USER(iOwner, iOwner, 'DFLT_USER_TS', 'TMPY_USER_TS');
END CREATE_USER;
/*
 *  NAME    : CREATE_USER
 *  PURPOSE : This is an overloaded procedure.
 *            If CREATE_USER is called with a supplied password and tablespaces
 *            this procedure will be called instead of the prior CREATE_USER
 *            procedure. This allows for some logic on the front end to query
 *            the database for valid tablespaces or to accept user entered tablespaces.
 */
PROCEDURE CREATE_USER 
( iOwner       IN VARCHAR2,
  iPassword    IN VARCHAR2,
  iTSName      IN VARCHAR2,
  iTempTSName  IN VARCHAR2) 
AS
BEGIN
  GET_FILEPATH(filepath);
  /* If tablespace does not exist then create one */
  IF NOT IS_TABLESPACE(iTSName,'PERMANENT') THEN
    ExecDynSQL('CREATE TABLESPACE '||iTSName||' DATAFILE '''||
                filepath||iTSName||'01.DBF'' SIZE 1024M');
  END IF;
  /* If tablespace does not exist then create one */
  IF NOT IS_TABLESPACE(iTempTSName,'TEMPORARY') THEN
    ExecDynSQL('CREATE TEMPORARY TABLESPACE '||iTempTSName||' TEMPFILE '''||
                filepath||iTempTSName||'01.DBF'' SIZE 300M');
  END IF;
  /* If the user does not already exist then create the user */
  IF NOT IS_USER(iOwner) THEN
    vDynSQL := '';
    NewLine(vDynSQL,'CREATE USER '||iOwner||' IDENTIFIED BY "'||iPassword||'"');
    NewLine(vDynSQL,'    DEFAULT TABLESPACE '   || iTSName);
    NewLine(vDynSQL,'    TEMPORARY TABLESPACE ' || iTempTSName);
    NewLine(vDynSQL,'    PROFILE DEFAULT');
    ExecDynSQL(vDynSQL);
  END IF;
  CREATE_USER_PRIVS(iOwner, iTSName, iTempTSName);
END CREATE_USER;

/*
 *  NAME    : CREATE_USER_PRIVS
 *  PURPOSE : This does basic grants for a schema user
 *            This is the most important part of this procedure.
 *            Please note that the privileges granted only apply to the grantee's 
 *            own schema. There are no global or system wide privileges given. Also
 *            there are no WITH ADMIN OPTION clauses given so this user can not
 *            affect any other schema but its own. 
 *            There are a few V$ views that I normally grant to users only because 
 *            I feel they are important enough when debugging code or providing the
 *            applications to understand where it is in the execution process.
 */
PROCEDURE CREATE_USER_PRIVS 
( iOwner         IN VARCHAR2,
  iTSName        IN VARCHAR2,
  iTempTSName    IN VARCHAR2)
AS
BEGIN
    ExecDynSQL('ALTER USER '||iOwner||' QUOTA UNLIMITED ON '||iTSName);
    ExecDynSQL('ALTER USER '||iOwner||' QUOTA UNLIMITED ON '||iTempTSName);
    ExecDynSQL('GRANT CREATE CLUSTER            TO '||iOwner);
    ExecDynSQL('GRANT CREATE DATABASE LINK      TO '||iOwner);
    ExecDynSQL('GRANT CREATE DIMENSION          TO '||iOwner);
    ExecDynSQL('GRANT CREATE INDEXTYPE          TO '||iOwner);
    ExecDynSQL('GRANT CREATE JOB                TO '||iOwner);
    ExecDynSQL('GRANT CREATE MATERIALIZED VIEW  TO '||iOwner);
    ExecDynSQL('GRANT CREATE OPERATOR           TO '||iOwner);
    ExecDynSQL('GRANT CREATE PROCEDURE          TO '||iOwner);
    ExecDynSQL('GRANT CREATE SEQUENCE           TO '||iOwner);
    ExecDynSQL('GRANT ALTER  SESSION            TO '||iOwner);
    ExecDynSQL('GRANT CREATE SESSION            TO '||iOwner);
    ExecDynSQL('GRANT CREATE SYNONYM            TO '||iOwner);
    ExecDynSQL('GRANT CREATE TABLE              TO '||iOwner);
    ExecDynSQL('GRANT CREATE TRIGGER            TO '||iOwner);
    ExecDynSQL('GRANT CREATE TYPE               TO '||iOwner);
    ExecDynSQL('GRANT CREATE VIEW               TO '||iOwner);
    ExecDynSQL('GRANT SELECT ON DUAL            TO '||iOwner);
    ExecDynSQL('GRANT SELECT ON V_$SESSION      TO '||iOwner);
    ExecDynSQL('GRANT SELECT ON V_$PROCESS      TO '||iOwner);
    ExecDynSQL('GRANT SELECT ON V_$MYSTAT       TO '||iOwner);
    ExecDynSQL('GRANT SELECT ON V_$TIMER        TO '||iOwner);
END CREATE_USER_PRIVS;
END CTRL_SCHEMA_USER ;
/
