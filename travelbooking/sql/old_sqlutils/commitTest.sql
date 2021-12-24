
--on travelagencydb
declare
  saga_id RAW(16);
  request JSON;
begin
  saga_id := dbms_saga.begin_saga('TravelAgency');
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Airline', 'TACoordinator', request);
end;
 /

--on participantdb
--check the saga status (status should be 0)
select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
--check the flights table (seats should be reduced to 1)
select * from flights;
select * from test;

--on travelagencydb
exec dbms_session.sleep(15);
--check the test table (should be Airline [{"result":"success"}])
select * from test;
declare
   saga_id RAW(16);
begin
  select id into saga_id from saga$ where status = 0;
  dbms_saga.commit_saga('TravelAgency', saga_id);
 end;
 /

--on participantdb
exec dbms_session.sleep(15);
--check the saga status (status should be 2)
 select id, initiator, coordinator, owner, begin_time, status from sys.saga$;
--check the flights table (seats should be 1)
select * from flights;
--check the test table (should be TRAVEL AGENCY [{"flight":"United"}]
select * from test;

