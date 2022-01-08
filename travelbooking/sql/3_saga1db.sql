
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

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
select * from travelagencytest;


