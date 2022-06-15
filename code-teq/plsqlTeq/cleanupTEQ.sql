--
--  This sample demonstrates how to remove (clean up) a TEQ using PL/SQL
--

--  Execute permission on dbms_aqadm is required.

begin
    -- first we need to stop the TEQ
    dbms_aqadm.stop_queue( 
        queue_name     => 'my_json_teq'
    );  

    -- now we can drop the TEQ
    dbms_aqadm.drop_transactional_event_queue(
        queue_name     => 'my_json_teq'
    );
end;
/
