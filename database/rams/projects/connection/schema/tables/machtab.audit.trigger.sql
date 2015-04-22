
-- @assys

alter table aud_hostdb.machtab
    add
    (
        conn number(5)
    )
/

CREATE OR REPLACE TRIGGER AUD_HOSTDB.MACHTAB_IU 
    AFTER INSERT OR UPDATE ON "HOSTDB"."MACHTAB" 
    FOR EACH ROW 
declare 
 
  xAction       char(1) ; 
 
begin 
 
  if ( Inserting ) then 
    xAction := aud.Change_Entry.xInsert ; 
  else 
    xAction := aud.Change_Entry.xUpdate ; 
    update  AUD_HOSTDB.MACHTAB
      set   Aud_Change_Flag  = 'H' 
      where Aud_uRowId       = :new.RowId 
      and   Aud_Change_Flag  = 'A' ; 
  end if ; 
 
  insert into AUD_HOSTDB.MACHTAB
    ( Aud_Change_Id 
    , Aud_Change_Flag 
    , Aud_uRowId 
    , Aud_Principal_Log_Id 
    , Aud_Action 
    , Aud_ts 
    , "ASSETNO"
    , "CPUTYPE"
    , "CPUMODEL"
    , "CPUMODELEXT"
    , "HOSTID"
    , "PROJECT"
    , "HWADDR"
    , "USRPRINC"
    , "PRJPRINC"
    , "USAGE"
    , "IROWID"
    , "DIST"
    , "CHARGE_BY"
    , "OPROJECT"
    , "OUSAGE"
    , "SUBPROJECT"
    , "DIST_SRC"
    , "MR_CLASS"
    , "FILTER_CODE"
    , "DESCRIPTION"
    , "CONN"
    ) 
    values 
    ( AUD_HOSTDB.Change_Id_Seq.NextVal 
    , 'A' 
    , :new.RowId 
    , Session_Identity.Get_Principal_Log_Id 
    , xAction 
    , SysTimestamp 
    , :new."ASSETNO"
    , :new."CPUTYPE"
    , :new."CPUMODEL"
    , :new."CPUMODELEXT"
    , :new."HOSTID"
    , :new."PROJECT"
    , :new."HWADDR"
    , :new."USRPRINC"
    , :new."PRJPRINC"
    , :new."USAGE"
    , :new."IROWID"
    , :new."DIST"
    , :new."CHARGE_BY"
    , :new."OPROJECT"
    , :new."OUSAGE"
    , :new."SUBPROJECT"
    , :new."DIST_SRC"
    , :new."MR_CLASS"
    , :new."FILTER_CODE"
    , :new."DESCRIPTION"
    , :new."CONN"
    ) ; 
 
end;
/

CREATE OR REPLACE TRIGGER AUD_HOSTDB.MACHTAB_DEL BEFORE
    DELETE ON HOSTDB.MACHTAB FOR EACH ROW 
begin 
 
  update  AUD_HOSTDB.MACHTAB
    set   Aud_Change_Flag  = 'H' 
    where Aud_uRowId       = :old.RowId ; 
 
  insert into AUD_HOSTDB.MACHTAB
    ( Aud_Change_Id 
    , Aud_Change_Flag 
    , Aud_uRowId 
    , Aud_Principal_Log_Id 
    , Aud_Action 
    , Aud_ts 
    , "ASSETNO"
    , "CPUTYPE"
    , "CPUMODEL"
    , "CPUMODELEXT"
    , "HOSTID"
    , "PROJECT"
    , "HWADDR"
    , "USRPRINC"
    , "PRJPRINC"
    , "USAGE"
    , "IROWID"
    , "DIST"
    , "CHARGE_BY"
    , "OPROJECT"
    , "OUSAGE"
    , "SUBPROJECT"
    , "DIST_SRC"
    , "MR_CLASS"
    , "FILTER_CODE"
    , "DESCRIPTION"
    , "CONN"
    ) 
    values 
    ( AUD_HOSTDB.Change_Id_Seq.NextVal 
    , 'H' 
    , :old.RowId 
    , Session_Identity.Get_Principal_Log_Id 
    , 'D' 
    , SysTimestamp 
    , :old."ASSETNO"
    , :old."CPUTYPE"
    , :old."CPUMODEL"
    , :old."CPUMODELEXT"
    , :old."HOSTID"
    , :old."PROJECT"
    , :old."HWADDR"
    , :old."USRPRINC"
    , :old."PRJPRINC"
    , :old."USAGE"
    , :old."IROWID"
    , :old."DIST"
    , :old."CHARGE_BY"
    , :old."OPROJECT"
    , :old."OUSAGE"
    , :old."SUBPROJECT"
    , :old."DIST_SRC"
    , :old."MR_CLASS"
    , :old."FILTER_CODE"
    , :old."DESCRIPTION"
    , :old."CONN"
    ) ; 
 
end ;
/

