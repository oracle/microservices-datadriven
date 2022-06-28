-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

--
--  This sample demonstrates how to remove (clean up) a TEQ using PL/SQL
--

--  Execute permission on dbms_aqadm is required.

begin
    -- first we need to stop the TEQ
    dbms_aqadm.stop_queue( 
        queue_name     => 'my_teq'
    );  

    -- now we can drop the TEQ
    dbms_aqadm.drop_transactional_event_queue(
        queue_name     => 'my_teq'
    );
end;
/
