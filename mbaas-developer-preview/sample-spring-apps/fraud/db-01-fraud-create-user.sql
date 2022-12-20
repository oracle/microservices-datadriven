-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

CREATE USER FRAUD IDENTIFIED BY "<DATABASE PASSWORD>";
GRANT CONNECT, RESOURCE TO FRAUD;
ALTER USER FRAUD QUOTA UNLIMITED ON USERS;

