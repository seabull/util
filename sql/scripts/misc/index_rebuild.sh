#!/usr/bin/ksh
# ---------------------- Control Block ------------------------------
#
#      Program Name : index_rebuild  2.1
#      Description  : Rebuilds indexes in situ
#      Author       : Chris Gould (chris_gould@hotmail.com)
#      Date Written : 99/02/27 23:16:23
#      Version      : @(#)shl gen index_rebuild 2.1@(#)
#
#      Amendment History
#      Ref   Version Date      Author  Description
#            1.1     29/01/99  CMG     Created
#            1.2     02/02/99  CMG     Tarting up
#            1.3     03/02/99  CMG     Handle unique constraints
#            1.4     04/02/99  CMG     Addn settings on index build
#            1.5     23/02/99  CMG     Include "getopts" processing
#            1.6     27/02/99  CMG     Add exit to end of script
#            1.7     23/06/99  CMG     Cater for bitmap indexes
#            2.0     07/07/99  CMG     additional options included
#            2.1     08/07/99  CMG     Now allows single index selection
#                                      (if constraint exists on this, disables it  
#                                       but still disables all FK constraints) 
# ---------------------------------------------------------------------------
  ##
  ## Creates script to rebuild indexes on a table
  ## (using current settings)
  ## Also handles any primary and foreign key constraints
  ## by disabling and then re-enabling any that are initially enabled

  function Usage {
     echo "\n$THIS_FILE\n usage :"
     echo " $THIS_FILE -t TABLE_NAME -f OUTPUT_FILE [-A] [-u DB_CONNECT_STRING]"
     echo "  [-N] [-i INDEX_NAME] [-p DDICT_TABLE_PREFIX] -D"
     echo "\n  -A : append to output file"
     echo "  -N : non-unique indexes only"
     echo "  -D : debug (keep temp files)"
     echo ""
  }

  THIS_FILE=$(basename $0)
  P_DB_STR=/  ## default
  APPEND_TO_SCRIPT=N
  BUILD_TYPE="all"

  ## getopts processing
  while getopts "ADf:i:p:t:Nu:" opt
  do
   case $opt in
    A ) APPEND_TO_SCRIPT=Y;;
    D ) DEBUG=Y;;
    N ) UNIQUE_INDEXES=N;BUILD_TYPE="Non-unique";;
    f ) REBUILD_SCRIPT=$OPTARG;;
    i ) typeset -u INDEXNAME=$OPTARG;;
    p ) TB_PFX=$OPTARG;;
    t ) typeset -u TABLENAME=$OPTARG;;
    u ) P_DB_STR=${OPTARG:-/};;
    * ) Usage;exit 10;;
   esac
  done
  shift $(($OPTIND -1))


  ## Check parameters
  if [[ -n $REBUILD_SCRIPT && -n $TABLENAME ]]; then
     echo "Parameters OK ..."
     echo "Building index script for $TABLENAME \c"
     if [[ -n $INDEXNAME ]]; then
        BUILD_TYPE="single"
        echo "index $INDEXNAME \c"
     fi
     echo "..."
  else
     Usage
     exit 10
  fi

  WORK_DIR=/tmp/${THIS_FILE}_$$

  mkdir $WORK_DIR
  if (( $? > 0 )); then
     echo "+++Error: cannot create work directory $WORK_DIR"
     exit 10
  fi
  TMP1_SQL=${WORK_DIR}/tmp1.sql
  GEN_ENABLE_FK_SQL=${WORK_DIR}/gen_enable_fk.sql
  GEN_DISABLE_FK_SQL=${WORK_DIR}/gen_disable_fk.sql
  GEN_ENABLE_PK_SQL=${WORK_DIR}/gen_enable_pk.sql
  GEN_DISABLE_PK_SQL=${WORK_DIR}/gen_disable_pk.sql
  GEN_DROP_IDX_SQL=${WORK_DIR}/gen_drop_idx.sql
  GEN_BLD_IDX_SQL=${WORK_DIR}/gen_bld_idx.sql
  ENABLE_FK_SQL=${WORK_DIR}/enable_fk.sql
  DISABLE_FK_SQL=${WORK_DIR}/disable_fk.sql
  ENABLE_PK_SQL=${WORK_DIR}/enable_pk.sql
  DISABLE_PK_SQL=${WORK_DIR}/disable_pk.sql
  DROP_IDX_SQL=${WORK_DIR}/drop_idx.sql
  BLD_IDX_SQL=${WORK_DIR}/bld_idx.sql


 ### if just dealing with non-unique indexes there won't
 ### be any constraints using them, so don't need these

 if [[ $UNIQUE_INDEXES != N ]]; then
    ###
    ### Create SQL to disable/enable foreign-key constraints
    ### referencing this table

    {
      echo "set head off"
      echo "set feedback off"
      echo "set linesize 132"
      echo "set pagesize 0 "

      echo "select 'alter table '||uc1.owner||'.'||uc1.table_name||"
      echo "      ' disable constraint '||uc1.constraint_name||';'"
      echo "from ${TB_PFX}user_constraints uc1"
      echo "    ,${TB_PFX}user_constraints uc2"
      echo "where uc2.table_name = '$TABLENAME'"
      echo "  and uc2.constraint_name = uc1.r_constraint_name"
      echo "  and uc2.owner = uc1.r_owner"
      echo "/"

     } >$GEN_DISABLE_FK_SQL

     echo "Creating FK disable stmts ..."
     cat $GEN_DISABLE_FK_SQL | sqlplus -S $P_DB_STR >$DISABLE_FK_SQL

    {
      echo "set head off"
      echo "set feedback off"
      echo "set linesize 132"
      echo "set pagesize 0 "

      echo "select decode(uc1.status,'DISABLED','REM ',NULL)||"
      echo "       'alter table '||uc1.owner||'.'||uc1.table_name||"
      echo "      ' enable constraint '||uc1.constraint_name||';'"
      echo "from ${TB_PFX}user_constraints uc1"
      echo "    ,${TB_PFX}user_constraints uc2"
      echo "where uc2.table_name = '$TABLENAME'"
      echo "  and uc2.constraint_name = uc1.r_constraint_name"
      echo "  and uc2.owner = uc1.r_owner"
      echo "/"

     } >$GEN_ENABLE_FK_SQL

     echo "Creating FK enable stmts ..."
     cat $GEN_ENABLE_FK_SQL | sqlplus -S $P_DB_STR >$ENABLE_FK_SQL

    ###
    ### Create SQL to disable/enable primary-key and unique constraints
    ### on this table

    {
      echo "set head off"
      echo "set feedback off"
      echo "set linesize 132"
      echo "set pagesize 0 "

      echo "select 'alter table '||uc1.owner||'.'||uc1.table_name||"
      echo "      ' disable constraint '||uc1.constraint_name||';'"
      echo "from user_constraints uc1"
      echo "where uc1.table_name = '$TABLENAME'"
      echo "  and uc1.constraint_type in ('U','P')"
      echo "  and uc1.status = 'ENABLED'"
      if [[ -n $INDEXNAME ]]; then
         ## all this just to get the constraint_name (if any) that uses this index
         echo "and uc1.constraint_name = ("
         echo "   select constraint_name"
         echo "    from ${TB_PFX}user_cons_columns ucc"
         echo "        ,${TB_PFX}user_ind_columns uic"
         echo "    where uic.index_name = '$INDEXNAME'"
         echo "      and uic.table_name = ucc.table_name"
         echo "      and uic.column_name = ucc.column_name"
         echo "      and ucc.position = uic.column_position"
         echo "      and ucc.position = (select max(uic2.column_position)"
         echo "          from ${TB_PFX}user_ind_columns uic2"
         echo "          where uic2.table_name = uic.table_name"
         echo "            and uic2.index_name = uic.index_name)"
         echo "      and ucc.position = (select max(ucc2.position)"
         echo "          from ${TB_PFX}user_cons_columns ucc2"
         echo "         where ucc2.constraint_name = ucc.constraint_name)"
         echo "      and ucc.position = (select count(*) "
         echo "            from ${TB_PFX}user_cons_columns ucc3"
         echo "                ,${TB_PFX}user_ind_columns  uic3"
         echo "           where ucc3.constraint_name = ucc.constraint_name"
         echo "             and uic3.index_name = uic.index_name"
         echo "             and uic3.table_name = ucc3.table_name"
         echo "             and uic3.column_name = ucc3.column_name"
         echo "             and uic3.column_position = ucc3.position)"
         echo ")"
      fi
      echo "/"

     } >$GEN_DISABLE_PK_SQL

     echo "Creating PK disable stmts ..."
     cat $GEN_DISABLE_PK_SQL | sqlplus -S $P_DB_STR >$DISABLE_PK_SQL

    {
      echo "set head off"
      echo "set feedback off"
      echo "set linesize 132"
      echo "set pagesize 0 "

      echo "select 'alter table '||uc1.owner||'.'||uc1.table_name||"
      echo "      ' enable constraint '||uc1.constraint_name||';'"
      echo "from ${TB_PFX}user_constraints uc1"
      echo "where uc1.table_name = '$TABLENAME'"
      echo "  and uc1.constraint_type in ('U','P')"
      echo "  and uc1.status = 'ENABLED'"
      if [[ -n $INDEXNAME ]]; then
         ## all this just to get the constraint_name (if any) that uses this index
         echo "and uc1.constraint_name = ("
         echo "   select constraint_name"
         echo "    from ${TB_PFX}user_cons_columns ucc"
         echo "        ,${TB_PFX}user_ind_columns uic"
         echo "    where uic.index_name = '$INDEXNAME'"
         echo "      and uic.table_name = ucc.table_name"
         echo "      and uic.column_name = ucc.column_name"
         echo "      and ucc.position = uic.column_position"
         echo "      and ucc.position = (select max(uic2.column_position)"
         echo "          from ${TB_PFX}user_ind_columns uic2"
         echo "          where uic2.table_name = uic.table_name"
         echo "            and uic2.index_name = uic.index_name)"
         echo "      and ucc.position = (select max(ucc2.position)"
         echo "          from ${TB_PFX}user_cons_columns ucc2"
         echo "         where ucc2.constraint_name = ucc.constraint_name)"
         echo "      and ucc.position = (select count(*) "
         echo "            from ${TB_PFX}user_cons_columns ucc3"
         echo "                ,${TB_PFX}user_ind_columns  uic3"
         echo "           where ucc3.constraint_name = ucc.constraint_name"
         echo "             and uic3.index_name = uic.index_name"
         echo "             and uic3.table_name = ucc3.table_name"
         echo "             and uic3.column_name = ucc3.column_name"
         echo "             and uic3.column_position = ucc3.position)"
         echo ")"
      fi
      echo "/"

     } >$GEN_ENABLE_PK_SQL

     echo "Creating PK enable stmts ..."
     cat $GEN_ENABLE_PK_SQL | sqlplus -S $P_DB_STR >$ENABLE_PK_SQL
 fi 

 ###
 ### Create SQL to drop indexes

 {
   echo "set head off"
   echo "set feedback off"
   echo "set linesize 132"
   echo "set pagesize 0 "

   echo "select 'drop index '||ui.index_name||';'"
   echo "from user_indexes ui"
   echo "where ui.table_name = '$TABLENAME'"
   if [[ $UNIQUE_INDEXES = N ]]; then
      echo "and ui.uniqueness = 'NONUNIQUE'"
   fi 
   if [[ -n $INDEXNAME ]]; then
      echo "and ui.index_name = '$INDEXNAME'"
   fi
   echo "/"

  } >$GEN_DROP_IDX_SQL

  echo "Creating index drop stmts ..."
  cat $GEN_DROP_IDX_SQL | sqlplus -S $P_DB_STR >$DROP_IDX_SQL

 ###
 ### Create SQL to re-create indexes
 {
   echo "clear breaks"
   echo "clear columns"

   echo "break on idxnm on tblnm on  tblsp skip page"

   echo "set head off"
   echo "set feedback off"
   echo "set linesize 132"
   echo "set pagesize 30 "
   echo "set maxd 60000"
   echo "set arraysize 10"
   echo "-- pagesize needs to be large to get all cols on a page (max 16)"

   echo "col uniq new_value v_uniq noprint"
   echo "col bitm new_value v_bitm noprint"
   echo "col idxnm new_value v_idxnm noprint"
   echo "col tblnm new_value v_tblnm noprint"
   echo "col tblown new_value v_tblown noprint"
   echo "col colseq noprint"
   echo "col tblsp old_value v_tblsp noprint"
   echo "col init old_value v_init noprint"
   echo "col next old_value v_next noprint"
   echo "col pci  old_value v_pci  noprint"
   echo "col pcf  old_value v_pcf  noprint"

   echo "TTITLE LEFT 'prompt table:' v_tblnm '  index:' v_idxnm SKIP -"
   echo "'create ' v_uniq ' ' v_bitm ' index ' v_idxnm SKIP '  on ' v_tblown '.' v_tblnm SKIP ' ('"
   echo "BTITLE LEFT ' ) ' SKIP '  tablespace ' v_tblsp SKIP  -"
   echo "'  pctfree ' v_pcf SKIP -"
   echo "'  storage (initial ' v_init ' next ' v_next ' pctincrease ' v_pci ') unrecoverable noparallel' SKIP '/'"

   echo "select  ui.index_name  idxnm,"
   echo "       ui.table_name  tblnm,"
   echo "       ui.table_owner  tblown,"
   echo "       uic.column_position colseq,"
   echo "       ui.tablespace_name tblsp,"
   echo "       decode(ui.uniqueness,'UNIQUE','UNIQUE',NULL) uniq,"
   echo "       decode(ui.index_type,'BITMAP','BITMAP',NULL) bitm,"
   echo "       LTRIM(ui.initial_extent) init,"
   echo "       LTRIM(ui.next_extent) next,"
   echo "       LTRIM(ui.pct_increase) pci,"
   echo "       LTRIM(ui.pct_free) pcf,"
   echo "       decode(uic.column_position,1,NULL,',') leading_comma,"
   echo "       uic.column_name colnm"
   echo "from ${TB_PFX}user_indexes ui"
   echo "    ,${TB_PFX}user_segments us"
   echo "    ,${TB_PFX}user_ind_columns uic"
   echo "where uic.table_name = ui.table_name"
   echo "and uic.index_name = ui.index_name"
   echo "and us.segment_name = ui.index_name"
   echo "and us.tablespace_name = ui.tablespace_name"
   echo "and ui.table_name = '$TABLENAME'"
   if [[ $UNIQUE_INDEXES = N ]]; then
      echo "and ui.uniqueness = 'NONUNIQUE'"
   fi 
   if [[ -n $INDEXNAME ]]; then
      echo "and ui.index_name = '$INDEXNAME'"
   fi
   echo "order by tblsp,tblnm,idxnm,colseq"
   echo "/"
   echo "ttitle off"
   echo "btitle off"
 } >$GEN_BLD_IDX_SQL

  echo "Creating index create stmts ..."
  cat $GEN_BLD_IDX_SQL | sqlplus -S $P_DB_STR >$TMP1_SQL

  ## Now get rid of blank lines from constructed SQL
  sed /^$/d <$TMP1_SQL >$BLD_IDX_SQL

  ###
  ### Now put all the generated scripts together
  ### to produce the index rebuild script

  if [[ $APPEND_TO_SCRIPT = N ]]; then
     echo "" >$REBUILD_SCRIPT
  fi

  {
    echo "REM *******************************************"
    echo "REM $BUILD_TYPE index rebuild script for $TABLENAME"
    if [[ -n $INDEXNAME ]]; then
       echo "REM index $INDEXNAME"
    fi
    echo "REM (constraints currently disabled REM'd out)"
    echo "REM Created \c"
    date
    echo "REM *******************************************"
    echo "set timing on"
  } >>$REBUILD_SCRIPT

  echo "Creating final script ..."
  if [[ $UNIQUE_INDEXES != N ]]; then
     cat \
     $DISABLE_FK_SQL \
     $DISABLE_PK_SQL \
     >>$REBUILD_SCRIPT
  fi

  cat \
  $DROP_IDX_SQL \
  $BLD_IDX_SQL \
  >>$REBUILD_SCRIPT

  if [[ $UNIQUE_INDEXES != N ]]; then
     cat \
     $ENABLE_PK_SQL \
     $ENABLE_FK_SQL \
     >>$REBUILD_SCRIPT
  fi

  if [[ $APPEND_TO_SCRIPT = N ]]; then
     echo "exit" >>$REBUILD_SCRIPT
  fi

  echo "Done"
  if [[ $DEBUG = Y ]]; then
     echo "** temp files are in ${WORK_DIR}"
  else
     rm -rf ${WORK_DIR} >/dev/null 2>&1
  fi


