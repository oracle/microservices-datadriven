
--on travelagencydb
declare
  saga_id RAW(16);
  request JSON;
 begin
  saga_id := dbms_saga.begin_saga('TravelAgency');
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'JavaAirline', 'TACoordinator', request);
end;
/

--on participantdb
exec dbms_session.sleep(15);
--check the saga status (status should be 0)
select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
--check the flights table
select * from flights;
select * from test;


--on travelagencydb
declare
  saga_id RAW(16);
begin
  select id into saga_id from sys.saga$ where status = 0;
  dbms_saga.rollback_saga(saga_id);
end;

--on participantdb
--check the saga status (status should be 3)
select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
--check the flights table
select * from flights;
--check the test table
select * from test;
