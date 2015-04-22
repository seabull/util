LOAD DATA
INFILE '20060721'
--append
replace
--INFILE *
INTO TABLE pta_rm
FIELDS TERMINATED BY whitespace OPTIONALLY ENCLOSED BY '"'
(
	pta "rtrim(:pta)"
)
