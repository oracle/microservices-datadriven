
--on travelagencydb
declare
  saga_id RAW(16);
  request JSON;
 begin
  saga_id := dbms_saga.begin_saga('TravelAgency');
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Flight', 'TravelCoordinator', request);
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Hotels', 'TravelCoordinator', request);
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Car', 'TravelCoordinator', request);
end;
/
--begin test for enroll_participant from participant
declare
  saga_id RAW(16);
 begin
  saga_id := dbms_saga.begin_saga('TravelAgency');
end;
/

declare
  saga_id RAW(16);
  request JSON;
 begin
  saga_id := dbms_saga.begin_saga(‘TravelAgency’);
  request := json(‘[{“flight”:“United”}]’);
  dbms_saga.enroll_participant(saga_id, ‘TravelAgency’, ‘Flight’, ‘TACoordinator’, request);
  dbms_saga.enroll_participant(saga_id, ‘TravelAgency’, ‘Hotels’, ‘TACoordinator’, request);
  dbms_saga.enroll_participant(saga_id, ‘TravelAgency’, ‘Car’, ‘TACoordinator’, request);
end;
/

declare
  request JSON;
 begin
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant('D0EDC89D67303EB1E0533D11000AFC17', 'TravelAgency', 'Airline', 'TACoordinator', request);
end;
/

--end test for enroll_participant from participant


--on participantdb
exec dbms_session.sleep(15);
--check the saga status (status should be 0)
select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
select id, initiator, coordinator, owner, begin_time, status from saga$;
--check the flights table
select * from flights;
select * from test;


--on travelagencydb
declare
  saga_id RAW(16);
begin
  select id into saga_id from saga$ where status = 0;
  dbms_saga.rollback_saga('TravelAgency', saga_id);
end;
/

--on participantdb
--check the saga status (status should be 3)
select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
--check the flights table
select * from flights;
--check the test table
select * from test;
