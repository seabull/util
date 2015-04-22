setlocal

perl get_tptscript.pl ProdBBYVWS.TBEND_SA_DCNT  		> generated\TBEND_SA_DCNT.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_DCNT_OTHER            > generated\TBEND_SA_DCNT_OTHER.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_ITEM                  > generated\TBEND_SA_ITEM.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_ITEM_OTHER            > generated\TBEND_SA_ITEM_OTHER.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_PYMT                  > generated\TBEND_SA_PYMT.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_PYMT_MTHD             > generated\TBEND_SA_PYMT_MTHD.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_PYMT_MTHD_OTHER       > generated\TBEND_SA_PYMT_MTHD_OTHER.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_PYMT_OTHER            > generated\TBEND_SA_PYMT_OTHER.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_SALE                  > generated\TBEND_SA_SALE.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_SALE_OTHER            > generated\TBEND_SA_SALE_OTHER.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_TAX                   > generated\TBEND_SA_TAX.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_TAX_DTL               > generated\TBEND_SA_TAX_DTL.tpt
perl get_tptscript.pl ProdBBYVWS.TBEND_SA_TAX_OTHER		> generated\TBEND_SA_TAX_OTHER.tpt


endlocal
