rem Author:  Longjiang Yang
rem Name:    locks.sql
rem Purpose: Displays active locks
rem Usage:   @locks
rem Subject: tuning
rem Attrib:  sql dba
rem Descr:
rem Notes:   Includes detailed description of lock type
rem SeeAlso:
rem History:
rem          14-feb-02  Initial release

@setup

column username format a12
column sid format 990
column lock_mode format a3
column name format a20
column description format a33 wrap

PROMPT ------------------------------------------------------------
PROMPT LOCKS DEFINED
PROMPT
PROMPT RS  - Row Share           - no exclusive WRITE
PROMPT RX  - Row eXclusive       - no exclusive READ or WRITE
PROMPT S   - Share               - no modifications
PROMPT SRX - Share Row eXclusive - no modifications or RX
PROMPT X   - eXclusive           - no access period
PROMPT
PROMPT ------------------------------------------------------------

SELECT
  s.username,
  s.sid,
  l.type,
  o.name,
  DECODE(l.lmode,
    1, '',
    2, 'RS',
    3, 'RX',
    4, 'S',
    5, 'SRX',
    6, 'X',
    '???'
  ) lock_mode,
  DECODE(l.type,
    'RW', 'Row wait enqueue lock',
    'TM', 'DML enqueue lock '||
          decode(l.lmode,
            2, '(no X)',
            3, '(no S,SRX,X)',
            4, '(no RX,SRX,X)',
            5, '(no RX,S,SRX,X)',
            6, '(no RS,RX,S,SRX,X)',
            ''
          ),
    'TX', 'Transaction enqueue lock',
    'UL', 'User supplied lock'
  ) description
FROM v$lock l, v$session s, sys.obj$ o
WHERE l.type IN ('RW','TM','TX','UL')
AND l.sid = s.sid
AND l.id1 = o.obj#
UNION ALL
SELECT
  '(system)',
  0,
  l.type,
  '',
  '',
  DECODE(l.type,
    'BL', 'Buffer hash table instance lock',
    'CF', 'Cross-instance function invocation instance lock',
    'CI', 'Control file schema global enqueue lock',
    'CS', 'Control file schema global enqueue lock', 
    'DF', 'Data file instance lock',
    'DM', 'Mount / startup db primary / secondary instance lock',
    'DR', 'Distributed recovery process lock',
    'DX', 'Distributed transaction entry lock',
    'FI', 'SGA open-file information lock',
    'FS', 'File set lock',
    'IR', 'Instance recovery serialization global enqueue lock',
    'IV', 'Library cache invalidation instance lock',
    'LS', 'Log start / log switch enqueue lock',
    'MB', 'Master buffer hash table instance lock',
    'MM', 'Master definition global enqueue lock',
    'MR', 'Media recovery lock',
    'RE', 'USE_ROW_ENQUEUES enforcement lock',
    'RT', 'Redo thread global enqueue lock',
    'SC', 'System commit number instance lock',
    'SH', 'System commit number high water mark enqueue lock',
    'SN', 'Sequence number instance lock',
    'SQ', 'Sequence number enqueue lock',
    'ST', 'Space transaction enqueue lock',
    'SV', 'Sequence number value lock',
    'TA', 'Generic enqueue lock',
    'TD', 'DDL enqueue lock',
    'TE', 'Extend-segment enqueue lock',
    'TS', DECODE(id2, 0,
       'Temporary segment enqueue lock',
       'New block allocation enqueue lock'),
    'TT', 'Temporary table enqueue lock',
    'UN', 'User name lock',
    'WL', 'Being-written redo log instance lock',
    'WS', 'Write-atomic-log-switch global enqueue lock',
    '?Unknown lock type?'
  ) description    
FROM v$lock l --, v$session s, sys.obj$ o
WHERE l.type NOT IN ('RW','TM','TX','UL')
AND l.type NOT BETWEEN 'LA' AND 'LP'
AND l.type NOT BETWEEN 'PA' AND 'QZ'
and l.type <> 'MR'
-- AND l.sid = s.sid
-- AND l.id1 = o.obj#
UNION ALL
SELECT
  '(system)',
  0,
  l.type,
  '',
  '',
  DECODE(SUBSTR(l.type,1,1),
    'L', 'Library cache lock instance lock (namespace "'||SUBSTR(l.type,2)||'")',
    'P', 'Library cache pin instance lock (namespace "'||SUBSTR(l.type,2)||'")',
    'Q', 'Row cache instance lock (cache "'||SUBSTR(l.type,2)||'")',
    ''
  )
FROM v$lock l
WHERE (l.type BETWEEN 'LA' AND 'LP'
  OR l.type BETWEEN 'PA' AND 'QZ')
;


@setdefs

