
--on participantpdb
create or replace package dbms_javaairline_cbk as
function request(saga_id in RAW, saga_sender IN VARCHAR2, payload IN JSON DEFAULT NULL) return JSON;
procedure after_rollback(saga_id in RAW, saga_sender IN varchar2, payload IN JSON DEFAULT NULL);
end dbms_javaairline_cbk;
/
create or replace package body dbms_javaairline_cbk as
function request(saga_id in RAW, saga_sender IN VARCHAR2, payload IN JSON DEFAULT NULL) return JSON as
response JSON;
tickets NUMBER;
begin
  insert into test values(saga_sender);
  insert into test values(json_serialize(payload));
  select seats into tickets from flights where id = 1;
  IF tickets > 0 THEN
    response := json('[{"result":"success"}]');
  ELSE
    response := json('[{"result":"failure"}]');
  END IF;
  sendReserveFlightMessage(saga_id);
  -- the service will do this instead when it gets message update flights set seats = seats - 1 where id = 1;
  return response;
end;

procedure after_rollback(saga_id in RAW, saga_sender IN varchar2, payload IN JSON DEFAULT NULL)as
begin
    sendRollbackMessage(saga_id);
-- the service will do this instead when it gets message  update flights set seats = seats + 1 where id = 1;
end;
end dbms_airline_cbk;
/
show errors;
exec dbms_saga_adm.add_participant(participant_name=> 'JavaAirline' , dblink_to_broker=> 'travelagencypdb',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => 'dbms_javaairline_cbk' , dblink_to_participant=> 'participantpdb');



CREATE OR REPLACE PROCEDURE BEGINSAGAWRAPPER
(
   SAGANAME IN VARCHAR2,
   SAGAID OUT VARCHAR2
)
IS
     request JSON;
BEGIN
  SAGAID := dbms_saga.begin_saga(SAGANAME);
END;


CREATE OR REPLACE PROCEDURE REGISTER_PARTICIPANT_IN_SAGA
(
   PARTICIPANTTYPE IN VARCHAR2,
   RESERVATIONTYPE IN VARCHAR2,
   RESERVATIONVALUE IN VARCHAR2,
   SAGANAME IN VARCHAR2,
   SAGAID IN VARCHAR2
)
IS
     request JSON;
BEGIN
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(SAGAID, SAGANAME, PARTICIPANTTYPE, 'TACoordinator', request);
END;


    CREATE OR REPLACE PROCEDURE COMMITSAGA(SAGAID IN RAW)
     IS
     saga_id RAW(16);
     begin
     select id into saga_id from sys.saga$ where id = SAGAID;
     dbms_saga.commit_saga(saga_id);
     END;


    CREATE OR REPLACE PROCEDURE ROLLBACKSAGA(SAGAID IN RAW)
     IS
     saga_id RAW(16);
     begin
     select id into saga_id from sys.saga$ where id = SAGAID;
     dbms_saga.rollback_saga(saga_id);
     END;



select id, initiator, coordinator, owner, begin_time, status from sys.saga$;

exec dbms_saga.rollback_saga('CC9BE6B041CFE734E053C100000A6808')

-------------------- older versions... ----------------


CREATE OR REPLACE PROCEDURE BEGINTRAVELAGENCYSAGA_ANDRESERVEFLIGHT
(
   SAGANAME IN VARCHAR2,
   SAGAID OUT VARCHAR2
)
IS
     request JSON;
BEGIN
  SAGAID := dbms_saga.begin_saga(SAGANAME);
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(SAGAID, SAGANAME, 'Airline', 'TACoordinator', request);
END;

CREATE OR REPLACE PROCEDURE ADDHOTELTO_TRAVELAGENCYSAGA
(
   SAGANAME IN VARCHAR2,
   SAGAID IN VARCHAR2
)
IS
     request JSON;
BEGIN
  request := json('[{"hotel":"Sofitel"}]');
  dbms_saga.enroll_participant(SAGAID, SAGANAME, 'Hotel', 'TACoordinator', request);
END;


CREATE OR REPLACE PROCEDURE BEGINTRAVELAGENCYSAGA
(
   SAGANAME IN VARCHAR2,
   SAGAID OUT RAW(16)
)
AS
BEGIN
  saga_id := dbms_saga.begin_saga('TravelAgency');
  request := json('[{"flight":"United"}]');
  dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Airline', 'TACoordinator', request);
END;

    /**
     CREATE OR REPLACE PROCEDURE BEGINTRAVELAGENCYSAGA(SAGANAME IN VARCHAR2)
     IS
     saga_id RAW(16);
     request JSON;
     BEGIN
     saga_id := dbms_saga.begin_saga('TravelAgency');
     request := json('[{"flight":"United"}]');
     dbms_saga.enroll_participant(saga_id, 'TravelAgency', 'Airline', 'TACoordinator', request);
     END;
     */



       /**
          CREATE OR REPLACE PROCEDURE COMMITSAGA(SAGAID IN VARCHAR2)
          IS
          saga_id RAW(16);
          begin
          select id into saga_id from sys.saga$ where status = 0;
          dbms_saga.commit_saga(saga_id);
          END;
          */

      declare
         saga_id RAW(16);
      begin
        select id into saga_id from sys.saga$ where status = 0;
        dbms_saga.commit_saga(saga_id);
       end;
       /




