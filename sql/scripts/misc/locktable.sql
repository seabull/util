rem Author:  Longjiang Yang
rem Name:    locktable.sql
rem Purpose: Displays lock compatibility table
rem Usage:   @locktable
rem Subject: tuning
rem Attrib:  sql
rem Descr:
rem Notes:   Includes detailed description of lock types
rem SeeAlso:
rem History:
rem          14-feb-02  Initial release

@setup

prompt +------------------------------------------------------------+
prompt |LOCKS DEFINED                                               |
prompt |                                                            |
prompt |RS  - Row Share           - no exclusive WRITE              |
prompt |RX  - Row eXclusive       - no exclusive READ or WRITE      |
prompt |S   - Share               - no modifications                |
prompt |SRX - Share Row eXclusive - no modifications or RX          |
prompt |X   - eXclusive           - no access period                |
prompt |                                                            |
prompt |TX  - Row Locks                                             |
prompt |TM  - Table Locks                                           |
prompt +--------------------------------+-------+---+---+---+---+---+ 
prompt |SQL Statement                   |Mode   |RS |RX |S  |SRX|X  |
prompt |                                |       |   |   |   |   |   |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt |SELECT ... FROM table ...       |none   |Y  |Y  |Y  |Y  |Y  |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt |INSERT INTO table ...           |none   |Y* |Y* |N  |N  |N  |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt |UPDATE table ...                |none   |Y* |Y* |N  |N  |N  |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt |DELETE FROM table ...           |none   |Y* |Y* |N  |N  |N  |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt |SELECT ... FROM table ...       |none   |Y* |Y* |Y* |Y* |N  |
prompt |  FOR UPDATE OF ...             |       |   |   |   |   |   |
prompt +--------------------------------+-------+---+---+---+---+---+
prompt
prompt *if no conflicting locks are held by another transaction; 
prompt  otherwise, waits occur

@setdefs
