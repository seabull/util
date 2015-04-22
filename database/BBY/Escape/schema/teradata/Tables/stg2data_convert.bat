
setlocal

SET WORKDIR=
SET SRCDIR=oraddl
SET DSTDIR=Teradata\populate

@SET ECHO OFF

SET SRCDDL_TYPE=Oracle
SET DSTDDL_TYPE=TTSchema

SET DST_TEMPLATE=Stg2Data.tt

::
:: We could programmatically read the file from the directory in the for loop below
:: But we want to control which files to be converted, so the files have to be explicitly specified here.
::
SET TABLELIST=custcst tacs tard tars tasc tata tbmd tcac tcai tcat tcmd tcmh tcpt tcsc tcsi tctp tdpm tdpt tdvp tegt tfat tkpg tlia tlni tpad tpak tpkg tpkp tpkt tplc tpln trmd tskp tslt tstd tvaf tvni tvpf tvpr tvpt

::SET TABLELIST=custcst tacs tard

FOR %%t IN (%TABLELIST%) DO (
    echo populating table esc_%%t from staging
    sqlt -f %SRCDDL_TYPE% -t %DSTDDL_TYPE% --tt-conf EVAL_PERL=1 --template %DST_TEMPLATE% %SRCDIR%\esc_%%t.sql | sed -e "s/\r//" > %DSTDIR%\%%t.sql
)

endlocal
