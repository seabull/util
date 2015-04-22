create or replace view hostdb.tmcd_princ as
SELECT
  UNIQUE
    p.princ,
    l.*,
    l.rowid ri
  FROM tmcd_ldr l, name n, principal p
  WHERE
    --LOWER(l.fname || ' ' || l.lname) = LOWER(n.name(+)) AND
    --l.ssn = n.ssn(+) AND n.princ = p.name(+)
    l.emp_num = n.emp_num(+) AND n.princ = p.name(+)
union
SELECT
  UNIQUE
    p.princ,
    l.*,
    l.rowid ri
  FROM tmcd_ldr l, name n, principal p
 WHERE
       lower(l.fname ||' '||l.lname)=lower(n.name(+))
   AND n.princ=p.name(+)
/
