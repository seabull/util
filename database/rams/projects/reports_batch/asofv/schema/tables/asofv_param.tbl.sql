create global temporary table utility.asofv_param
(
        id      number          primary key
        ,flag   char(1)         default 'H'		not null
        ,ts     timestamp       default systimestamp	not null
) on commit preserve rows
/

grant select, insert, delete, update on utility.asofv_param to public
/
