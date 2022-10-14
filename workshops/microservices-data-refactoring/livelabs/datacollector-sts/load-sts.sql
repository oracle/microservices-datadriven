-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

DECLARE
 cur DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
 OPEN cur FOR
   SELECT VALUE(P)
     FROM table(
       DBMS_SQLTUNE.SELECT_CURSOR_CACHE(
         'parsing_schema_name=upper(''tkdradata'') and sql_text not like ''%OPT_DYN%''',
          NULL, NULL, NULL, NULL, 1, NULL,
         'ALL', 'NO_RECURSIVE_SQL')) P;
 
DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => 'tkdradata',
                        populate_cursor => cur,
                        sqlset_owner => 'tkdradata');
 
END;
/ 