-- Copyright (c) 2022, 2024, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

-- This must be executed as SYS
create user testuser identified by Welcome12345;
grant resource, connect, unlimited tablespace to testuser;
grant aq_user_role to testuser;
grant execute on dbms_aq to testuser;
grant execute on dbms_aqadm to testuser;
grant execute ON dbms_aqin TO testuser;
grant execute ON dbms_aqjms TO testuser;
grant execute on dbms_teqk to testuser;
commit;