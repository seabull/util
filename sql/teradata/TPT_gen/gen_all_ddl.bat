setlocal

perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_DCNT  		   > ddl_generated\TBEND_SA_DCNT.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_DCNT_OTHER            > ddl_generated\TBEND_SA_DCNT_OTHER.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_ITEM                  > ddl_generated\TBEND_SA_ITEM.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_ITEM_OTHER            > ddl_generated\TBEND_SA_ITEM_OTHER.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_PYMT                  > ddl_generated\TBEND_SA_PYMT.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_PYMT_MTHD             > ddl_generated\TBEND_SA_PYMT_MTHD.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_PYMT_MTHD_OTHER       > ddl_generated\TBEND_SA_PYMT_MTHD_OTHER.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_PYMT_OTHER            > ddl_generated\TBEND_SA_PYMT_OTHER.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_SALE                  > ddl_generated\TBEND_SA_SALE.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_SALE_OTHER            > ddl_generated\TBEND_SA_SALE_OTHER.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_TAX                   > ddl_generated\TBEND_SA_TAX.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_TAX_DTL               > ddl_generated\TBEND_SA_TAX_DTL.sql
perl get_tptscript.pl -d ProdBBYVWS.TBEND_SA_TAX_OTHER		   > ddl_generated\TBEND_SA_TAX_OTHER.sql

endlocal
