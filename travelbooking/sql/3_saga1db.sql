
--do saga2db.sql then this test...

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
select * from saga_message_broker$;
select * from saga_participant_set$;
select * from saga_participant$;
select * from travelagencytest;

declare
  saga_id raw(16);
  request JSON;
 begin
  saga_id := dbms_saga.begin_saga('TravelAgencyPLSQL');
  request := json('[{"car":"toyota"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgencyPLSQL', 'CarPLSQL', 'TravelCoordinator', request);
end;
/

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
select * from travelagencytest;

--check saga2db, get the sagaid and do this... status will be 0

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
select * from travelagencytest;

begin
  dbms_saga.rollback_saga('TravelAgencyPLSQL', 'D3D667FC3CA2797EE0539418000AE6B9');
end;
/

--check saga2db, saga_sender and response payload will be CARPLSQL and [{"result":"success"}], and do this... status will be 3

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
select * from travelagencytest;



--Java....

exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyJava',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => null ,   dblink_to_participant => null);
exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyJava3',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => null ,   dblink_to_participant => null);
exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyJava4',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => null ,   dblink_to_participant => null);
