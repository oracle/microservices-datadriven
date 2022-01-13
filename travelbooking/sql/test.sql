

declare
  saga_id raw(16);
  request JSON;
 begin
  saga_id := dbms_saga.begin_saga('TravelAgencyPLSQL');
  flightrequest := json('[{"flight":"myflight"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgencyPLSQL', 'FlightPLSQL', 'TravelCoordinator', flightrequest);
  hotelrequest := json('[{"hotel":"myhoteg"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgencyPLSQL', 'CarPLSQL', 'TravelCoordinator', hotelrequest);
  carrequest := json('[{"car":"mycar"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgencyPLSQL', 'HotelPLSQL', 'TravelCoordinator', carrequest);
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


