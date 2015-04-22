-- $Id: integrity.sps.sql,v 1.1 2007/09/24 20:09:29 yangl Exp $
create or replace PACKAGE hostdb.INTEGRITY IS
  SUBTYPE account_t IS dist.account%TYPE;
  SUBTYPE assetno_t IS capequip.assetnum%TYPE;
  SUBTYPE charge_src_t IS Util.charge_src_t;
  SUBTYPE cputype_t IS mach_equiv.cputype%TYPE;
  SUBTYPE cpumodel_t IS mach_equiv.cpumodel%TYPE;
  SUBTYPE dist_t IS dists.id%TYPE;
  SUBTYPE os_t IS os.name%TYPE;
  SUBTYPE osv_t IS os.vers%TYPE;
  SUBTYPE pct_t IS dist.pct%TYPE;
  SUBTYPE princ_t IS who.princ%TYPE;

  SUBTYPE project_t IS dist_names.name%TYPE;
  SUBTYPE sponsor_t IS dist_names.subname%TYPE;

  TYPE charge_t IS RECORD (
    pct pct_t,
    account account_t
  );

  TYPE charge_cursor_t IS REF CURSOR RETURN charge_t;

  constDEBUG_LEVELA		pls_integer := 2;
  constDEBUG_LEVELB		pls_integer := 4;
  constDEBUG_LEVELC		pls_integer := 8;
  constDEBUG_LEVELD		pls_integer := 16;
  constDEBUG_LEVELE		pls_integer := 32;

  constPTCHGCATCOURTESY		char(1)	:= 'c';
  constDEFAULTPCT		pct_t	:= 3.5;

  PROCEDURE capequipAssetChanged(ri ROWID, nassetno assetno_t, oassetno assetno_t);
  PROCEDURE capequipAssetChanges;

  FUNCTION isParttimer(wdist_src	IN	charge_src_t) return boolean;
  FUNCTION projectPseudoUser RETURN VARCHAR2;
  FUNCTION projectPseudoEffort RETURN VARCHAR2;
  FUNCTION Last_Name(name VARCHAR2) RETURN VARCHAR2;
  FUNCTION distByProject(
    by_name VARCHAR2, by_subname VARCHAR2
  ) RETURN dist_t;
  PROCEDURE distQuery(
    by_name1 VARCHAR2,by_subname1 VARCHAR2,
    by_name2 VARCHAR2,by_subname2 VARCHAR2,
    dist OUT dist_t, src OUT charge_src_t, uo OUT CHAR
  );
  PROCEDURE distQuery(
    by_name1		IN	VARCHAR2
    ,by_subname1	IN	VARCHAR2
    ,by_name2		IN	VARCHAR2
    ,by_subname2	IN	VARCHAR2
    ,dist		OUT	dist_t
    ,src		OUT	charge_src_t
    ,uo			OUT	CHAR
    ,pct		OUT	pct_t
  );
  PROCEDURE distQuery(
    by_name1		IN	VARCHAR2
    ,by_subname1	IN	VARCHAR2
    ,by_name2		IN	VARCHAR2
    ,by_subname2	IN	VARCHAR2
    ,dist		OUT	dist_t
    ,src		OUT	charge_src_t
    ,uo			OUT	CHAR
    ,pct		OUT	pct_t
    ,dtype		OUT	pls_integer
  );
  FUNCTION distNormalize(
    cc charge_cursor_t,nc NUMBER,tpct pct_t,prec NUMBER
  ) RETURN dist_t;

  PROCEDURE centerValidate(qcenter IN VARCHAR2);

  PROCEDURE machtabChanging(nproject VARCHAR2, nsubproject IN OUT VARCHAR2);
  PROCEDURE machtabChanged(ri ROWID,assetno VARCHAR2,oassetno VARCHAR2);
  PROCEDURE machtabChanges;

  PROCEDURE machtabQueueByAssetno (qassetno VARCHAR2);
  PROCEDURE machtabQueueByDist (qdist dist_t);
  PROCEDURE machtabQueueByUser (quser VARCHAR2);
  PROCEDURE machtabQueueByProject (qproject VARCHAR2,qsubproject VARCHAR2);
  PROCEDURE machtabQueueBySub (qsubproject VARCHAR2);

  PROCEDURE machequivChanged(ri ROWID, ncputype cputype_t, ncpumodel cpumodel_t,ocputype cputype_t, ocpumodel cpumodel_t);
  PROCEDURE machequivChanges;

  PROCEDURE osChanged(ri ROWID, nos os_t, nosv osv_t,oos os_t, oosv osv_t);
  PROCEDURE osChanges;

  PROCEDURE capequipChanged(ri ROWID,nassetno VARCHAR2,oassetno VARCHAR2);
  PROCEDURE capequipChanges;
  FUNCTION distIdentify RETURN dist_t;

  PROCEDURE distPurge(qname VARCHAR, qsubname VARCHAR);
  PROCEDURE distPurgeBySub(qsubname VARCHAR);

  PROCEDURE distDefine(
    qname VARCHAR, qsubname VARCHAR, qdist dist_names.dist%TYPE,
    qsrc dist_names.src%TYPE
  );
  PROCEDURE distDefine(
    qname VARCHAR, qsubname VARCHAR, qdist dist_names.dist%TYPE,
    qsrc dist_names.src%TYPE, qpct pct_t
  );

  PROCEDURE distChanged(ri ROWID, dist dist.dist%TYPE);

  PROCEDURE distChanges;

  PROCEDURE distsChanged(ri ROWID, name VARCHAR2, subname VARCHAR2, oname VARCHAR2, osubname VARCHAR2);
  PROCEDURE distsChanges;

  PROCEDURE nameChanging(
    name IN OUT VARCHAR2, lname OUT VARCHAR2, lcname OUT VARCHAR2,
                          ssn OUT NUMBER, emp_num OUT NUMBER
  );
  PROCEDURE nameChanges;

  PROCEDURE whoChanged(ri ROWID, nprinc VARCHAR2, oprinc VARCHAR2);
  PROCEDURE whoChanges;
  PROCEDURE whoChanging(nproject IN OUT VARCHAR2,nsubproject IN OUT VARCHAR2);

  PROCEDURE paramChanges;
  PROCEDURE names(name IN VARCHAR2, lastname OUT VARCHAR2, firstname OUT VARCHAR2, middlename OUT VARCHAR2);
  PROCEDURE nameUpdating(name IN OUT VARCHAR2, lname OUT VARCHAR2, lcname OUT VARCHAR2);
	procedure whoPctChanged(ri IN ROWID, nprinc IN VARCHAR2, oprinc IN VARCHAR2);
	procedure whoPctChanges;
END;
/
Show Errors
