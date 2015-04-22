/* Compile Me With
 gcc -O3 flatten.c -o flatten -L/oracle/rdbms/9.2.0/orax011/lib32   -lclntsh 
-lclntst9
This is from asktom
*/

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define MAX_VNAME_LEN     30
#define MAX_INAME_LEN     30

static char *   USERID = NULL;
static char *   SQLSTMT = NULL;
static char *   ARRAY_SIZE = "10";
static char *   RECSEP = NULL;
static char *   FIELDSEP = NULL;
int DOUBLEQUOTE = (-1);

#define vstrcpy( a, b ) \
(strcpy( a.arr, b ), a.len = strlen( a.arr ), a.arr)

EXEC SQL INCLUDE sqlca;
EXEC SQL INCLUDE sqlda;

extern SQLDA *sqlald();
extern void   sqlclu();



static void die( char * msg )
{
    fprintf( stderr, "%s\n", msg );
    exit(1);
}


/*
    this array contains a default mapping
    I am using to constrain the
       lengths of returned columns.  It is mapping,
    for example, the Oracle
       NUMBER type (type code = 2) to be 45 characters
    long in a string.
*/

static int lengths[] =
{ -1, 0, 45, 0, 0, 0, 0, 0, 2000, 0, 0,
 18, 25, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 512, 2000 };


static void process_parms( argc, argv )
int    argc;
char *    argv[];
{
int    i;

    for( i = 1; i < argc; i++ )
    {
        if ( !strncasecmp( argv[i], "userid=", 7 ) )
              USERID = argv[i]+7;
        else
        if ( !strncasecmp( argv[i], "sqlstmt=", 8 ) )
              SQLSTMT = argv[i]+8;
        else
        if ( !strncasecmp( argv[i], "arraysize=", 10 ) )
              ARRAY_SIZE = argv[i]+10;
        else
        if ( !strncasecmp( argv[i], "recsep=", 7) )
              RECSEP = argv[i] + 7;
        else
        if ( !strncasecmp( argv[i], "fieldsep=", 9 ))
              FIELDSEP = argv[i] + 9;
        else
        if ( !strncasecmp(argv[i], "doublequote=true", 16))
            DOUBLEQUOTE=1;
        else
        if ( !strncasecmp(argv[i], "doublequote=false", 17))
            DOUBLEQUOTE=0;
        else
        {
            fprintf( stderr,
                    "usage: %s %s %s %s %s %s %s \n",
                     argv[0],
                    "userid=<user/pass@connect_string>", "sqlstmt=<Query>",
                    "arraysize=<Fetch Size>\n", "fieldsep=<Field Sep String>", 
"recsep=<Record Sep String>", 
                    "doublequote=<TRUE/FALSE>" );
            exit(1);
        }
    }
    if ( USERID == NULL  || SQLSTMT == NULL || RECSEP == NULL || FIELDSEP == 
NULL || DOUBLEQUOTE == (-1))
    {
            fprintf( stderr,
                    "usage: %s %s %s %s %s %s %s \n",
                     argv[0],
                    "userid=<user/pass@connect_string>", "sqlstmt=<Query>",
                    "arraysize=<Fetch Size>\n", "fieldsep=<Field Sep String>", 
"recsep=<Record Sep String>", 
                    "doublequote=<TRUE/FALSE>" );
            exit(1);
    }
}

static void sqlerror_hard()
{
    EXEC SQL WHENEVER SQLERROR CONTINUE;

    fprintf(stderr,"\nORACLE error detected:");
    fprintf(stderr,"\n% .70s \n", sqlca.sqlerrm.sqlerrmc);

    EXEC SQL ROLLBACK WORK RELEASE;
    exit(1);
}



static SQLDA * process_1(char * sqlstmt, int array_size )
{
SQLDA *    select_dp;
int     i;
int        j;
int        null_ok;
int        precision;
int        scale;
int        size = 10;

    fprintf( stderr, "Unloading '%s'\n", sqlstmt );
    fprintf( stderr, "Array size = %d\n", array_size );
    fprintf( stderr, "Field Separator = '%s'\n", FIELDSEP);
    fprintf( stderr, "Record Separator = '%s'\n", RECSEP);
    fprintf( stderr, "Doublequote is set to '%d'\n\n", DOUBLEQUOTE);


    EXEC SQL WHENEVER SQLERROR DO sqlerror_hard();
       EXEC SQL PREPARE S FROM :sqlstmt;
       EXEC SQL DECLARE C CURSOR FOR S;

    if ((select_dp = sqlald(size,MAX_VNAME_LEN,MAX_INAME_LEN))
                   == NULL )
        die( "Cannot allocate  memory for select descriptor." );

    select_dp->N = size;
    EXEC SQL DESCRIBE SELECT LIST FOR S INTO select_dp;
    if ( !select_dp->F ) return NULL;

    if (select_dp->F < 0)
    {
        size = -select_dp->F;
        sqlclu( select_dp );
        if ((select_dp =
                sqlald (size, MAX_VNAME_LEN, MAX_INAME_LEN))
                      == NULL )
        die( "Cannot allocate  memory for descriptor." );
        EXEC SQL DESCRIBE SELECT LIST FOR S INTO select_dp;
    }
    select_dp->N = select_dp->F;

    for (i = 0; i < select_dp->N; i++)
        select_dp->I[i] = (short *) malloc(sizeof(short) *
                                                array_size );

    for (i = 0; i < select_dp->F; i++)
    {
        sqlnul (&(select_dp->T[i]),
                &(select_dp->T[i]), &null_ok);
        if ( select_dp->T[i] <
                     sizeof(lengths)/sizeof(lengths[0]) )
        {
            if ( lengths[select_dp->T[i]] )
                 select_dp->L[i]  = lengths[select_dp->T[i]];
            else select_dp->L[i] += 5;
        }
        else select_dp->L[i] += 5;

        select_dp->T[i] = 5;
        select_dp->V[i] = (char *)malloc( select_dp->L[i] *
                                               array_size );

        for( j = MAX_VNAME_LEN-1;
             j > 0 && select_dp->S[i][j] == ' ';
             j--);
        fprintf (stderr,
                "%s%.*s", i?",":"", j+1, select_dp->S[i]);
    }
    fprintf( stderr, "\n" );


    EXEC SQL OPEN C;
    return select_dp;
}


static void process_2( SQLDA * select_dp, int array_size )
{
int    last_fetch_count;
int        row_count = 0;
short    ind_value;
char    * char_ptr;
int    i, j;
  

    for ( last_fetch_count = 0;
          ;
          last_fetch_count = sqlca.sqlerrd[2] )
    {
        EXEC SQL FOR :array_size FETCH C
                      USING DESCRIPTOR select_dp;

        for( j=0; j < sqlca.sqlerrd[2]-last_fetch_count; j++ )
        {
            for (i = 0; i < select_dp->F; i++)
            {
                ind_value = *(select_dp->I[i]+j);
                char_ptr  = select_dp->V[i] +
                                  (j*select_dp->L[i]);

                /* Double quote character is stored here */
                printf( "%s%s%s%s", i?FIELDSEP:"", DOUBLEQUOTE?"\"":"", 
ind_value?"":char_ptr, DOUBLEQUOTE?"\"":"");
            }
            row_count++;
            printf( "%s\n", RECSEP );
        }
        if ( sqlca.sqlcode > 0 ) break;
    }

    sqlclu(select_dp);

    EXEC SQL CLOSE C;

    EXEC SQL COMMIT WORK;
    fprintf( stderr, "%d rows extracted\n", row_count );
}



main( argc, argv )
int    argc;
char *    argv[];
{
EXEC SQL BEGIN DECLARE SECTION;
VARCHAR   oracleid[50];
EXEC SQL END DECLARE SECTION;
SQLDA    * select_dp;


    process_parms( argc, argv );

    /* Connect to ORACLE. */
    vstrcpy( oracleid, USERID );

    EXEC SQL WHENEVER SQLERROR DO sqlerror_hard();

    EXEC SQL CONNECT :oracleid;
    fprintf(stderr, "\nConnected to ORACLE as user: %s\n\n",
             oracleid.arr);

    EXEC SQL ALTER SESSION
      SET NLS_DATE_FORMAT = 'ddmmyyyyhh24miss';

    select_dp = process_1( SQLSTMT, atoi(ARRAY_SIZE) );
    process_2( select_dp , atoi(ARRAY_SIZE));

    /* Disconnect from ORACLE. */
    EXEC SQL COMMIT WORK RELEASE;
    exit(0);
}
