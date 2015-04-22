-- Those are the PIs that are not in by_princ but in by_name
select
	emp_num
	,emp_name
  from hostdb.emp
 where emp_num IN
(11852,2992,36443,4514,50804,7444)
/

select 
	princ
	,name
	,emp_num
  from hostdb.name
 where lname like 'Skees, %'
    or lname like 'Kubica, %'
    or lname like 'Burks, %'
    or lname like 'Copetas, %'
    or lname like 'D''Amico, %'
    or lname like 'Choset, %'
/
