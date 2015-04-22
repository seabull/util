SELECT table_name
FROM all_tables
WHERE owner = 'HOSTDB'
MINUS
SELECT table_name
FROM all_constraints
WHERE owner = 'HOSTDB'
AND constraint_type = 'P';
