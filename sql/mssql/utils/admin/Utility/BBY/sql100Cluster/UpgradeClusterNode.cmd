rem Does not work if preferred nodes are not set correctly: perl cpt38lib.pl -C -S DVD01SQL .\T38lib
rem Update perl library on one node a time.
perl cpt38lib.pl -S %computername% .\T38lib
perl t38instl100.pl -x gcm T38APP80\t38dba.cfg USERDB.cfg
