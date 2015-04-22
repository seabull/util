--
-- save entries of host/who_adjust_charge that will be purged
-- 2006/11/10
--

--@ashostdb

--create table host_adjust_charge_save as
--    select * 
--      from host_adjust_charge
--     where 0=1
--/

spool adjust_save

create table who_adjust_charge_save as
    select * 
      from who_adjust_charge
     where 0=1
/

select 
        journal
        , count(*) 
  from host_adjust_charge 
group by journal
/

select 
        journal
        , count(*) 
  from who_adjust_charge 
group by journal
/

insert into host_adjust_charge_save
    select
            *
      from host_adjust_charge
     where journal is not null
/

insert into who_adjust_charge_save
    select
            *
      from who_adjust_charge
     where journal is not null
/

delete from host_adjust_charge
where journal is not null
/

delete from who_adjust_charge
where journal is not null
/

select 
        journal
        , count(*) 
  from host_adjust_charge 
group by journal
/

select 
        journal
        , count(*) 
  from who_adjust_charge 
group by journal
/

spool off
