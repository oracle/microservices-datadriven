-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

begin
    dbms_sqltune.create_sqlset (
        sqlset_name => 'tkdradata', 
        description => 'SQL data from tkdradata schema'
    );
end;
/