--todo install saga


grant all on dbms_saga_adm to admin;


begin
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'PARTICIPANTADMINCRED',
    username => 'ADMIN',
    password => 'Welcome12345');
end;
/


begin
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'participantadminlink',
    hostname => 'adb.us-phoenix-1.oraclecloud.com',
    port => '1522',
    service_name => 'fcnesu1k4xmzwf1_sagadb2_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'PARTICIPANTADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
end;
/
select sysdate from dual@participantadminlink;

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

CREATE OR REPLACE PROCEDURE ENROLL_PARTICIPANT_IN_SAGA
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
    dbms_saga.enroll_participant(SAGAID, SAGANAME, PARTICIPANTTYPE, 'TravelCoordinator', request);
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


--Create Broker
exec dbms_saga_adm.add_broker(broker_name => 'TEST');

--For the add_coordinator call, if coordinator is co-located with broker, dblink_to_broker should be NULL or equal to the dblink_to_participant/coordinator.
exec dbms_saga_adm.add_coordinator( coordinator_name => 'TravelCoordinator',  dblink_to_broker => null,   mailbox_schema => 'admin',  broker_name => 'TEST',  dblink_to_coordinator => 'travelagencyadminlink');

create table travelagencytest(text VARCHAR2(100));
create or replace package dbms_ta_cbk as
function request(saga_id in raw, saga_sender in varchar2, payload in JSON default null) return JSON;
procedure response(saga_id in raw, saga_sender in varchar2, payload in JSON default null);
end dbms_ta_cbk;
/
create or replace package body dbms_ta_cbk as
function request(saga_id in raw, saga_sender in varchar2, payload in JSON default null) return JSON as
begin
  null;
end;

procedure response(saga_id in raw, saga_sender in varchar2, payload in JSON default null) as
begin
  insert into travelagencytest values(saga_sender);
  insert into travelagencytest values(json_serialize(payload));
end;
end dbms_ta_cbk;
/
exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyPLSQL',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => 'dbms_ta_cbk' ,   dblink_to_participant => null);
exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyJava',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => null ,   dblink_to_participant => null);


