--
--  $RCSfile: costing.sps.sql,v $
--  $Revision: 1.2 $
--  $Date: 2006/12/07 16:30:30 $
--  $Author: yangl $
--
create or replace PACKAGE               hostdb.costing IS

  SUBTYPE assetno_t IS capequip.assetnum%TYPE;
  SUBTYPE os_t IS oses.name%TYPE;
  SUBTYPE princ_t IS Util.princ_t;
  SUBTYPE pct_t IS host_service.pct%TYPE;
  SUBTYPE dpct_t IS dist.pct%TYPE;
  SUBTYPE hostname_t is hoststab.hostname%TYPE;
  SUBTYPE journal_id_t IS journals.id%TYPE;

  /*
   *  WARNING: if the precision of these data types is changed, the min and
   *  max constants must be adjusted accordingly.
   */
  SUBTYPE service_id_t IS services.id%TYPE;  /* (3,0) */
  SUBTYPE hpri_t IS hoststab.pri%TYPE;	     /* (6,0) */

  hpri_min hpri_t := 0;
  hpri_max hpri_t := 999999;
  service_id_min hpri_t := 0;
  service_id_max hpri_t := 999;


  PROCEDURE hostCharges(qassetno assetno_t);

  /*
   *  The who_attr and mach_attr triggers call the
   *  {host/who}ServicesChanged functions directly.  host_attr
   *  must be handled separately since the hostname musr be
   *  first converted to an asset number.
   */
  PROCEDURE hostAttrChanged(ri ROWID, nhn hostname_t, ohn hostname_t);
  PROCEDURE hostAttrChanges;


  PROCEDURE hostServiceChanged(
    ri ROWID,
    nassetno assetno_t, npri hpri_t, nservice_id service_id_t,
    oassetno assetno_t, opri hpri_t, oservice_id service_id_t
  );
  PROCEDURE hostServiceChanges;
  PROCEDURE hostServiceRegen;

  PROCEDURE hostServiceCommonChanged(ri ROWID, nassetno assetno_t, oassetno assetno_t);
  PROCEDURE hostServiceCommonChanges;

  PROCEDURE hostServicesUpdate(qassetno assetno_t);

  PROCEDURE whoCharges(qprinc princ_t, wpct pct_t);

  PROCEDURE whoAttrChanges;

  PROCEDURE whoServiceChanged(
    ri ROWID,
    nprinc princ_t, nservice_id service_id_t,
    oprinc princ_t, oservice_id service_id_t
  );
  PROCEDURE whoServiceChanges;
  PROCEDURE whoServiceRegen;

  PROCEDURE whoServiceCommonChanged(ri ROWID, nprinc princ_t, oprinc princ_t);
  PROCEDURE whoServiceCommonChanges;

  PROCEDURE whoServicesUpdate(qprinc  princ_t);
END;
/
show errors
