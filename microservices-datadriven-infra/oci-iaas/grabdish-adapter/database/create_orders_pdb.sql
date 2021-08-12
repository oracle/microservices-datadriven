Set ECHO ON

alter pluggable database orders close immediate instances=all;
drop pluggable database orders  including datafiles;

CREATE PLUGGABLE DATABASE orders
ADMIN USER admin IDENTIFIED BY "Welcome123"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '/u01/app/oracle/oradata/ORCL/orders/orders01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '/u01/app/oracle/oradata/ORCL/dbs/orders/'
FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/pdbseed/', '/u01/app/oracle/oradata/ORCL/orders/');

alter pluggable database orders  open;
quit;
/

alter pluggable database orders close immediate instances=all;
drop pluggable database orders  including datafiles;

CREATE PLUGGABLE DATABASE orders
ADMIN USER admin IDENTIFIED BY "Welcome123"
STORAGE (MAXSIZE 2G)
DEFAULT TABLESPACE oracle
DATAFILE '$ORA_BASE/oradata/ORCL/orders/orders01.dbf' SIZE 250M AUTOEXTEND ON
PATH_PREFIX = '$ORA_BASE/oradata/ORCL/dbs/orders/'
FILE_NAME_CONVERT = ('$ORA_BASE/oradata/ORCL/pdbseed/', '$ORA_BASE/oradata/ORCL/orders/');

alter pluggable database orders  open;
quit;
/