--todo install saga


grant all on dbms_saga_adm to admin;


begin
 DBMS_CLOUD.GET_OBJECT(
    object_uri => 'https://objectstorage.us-phoenix-1.oraclecloud.com/p/hyWE8lAKMz_FJgbnAVQHam83_CIWTzI4Zt6Xn6WRbTeMAp1CGLs1ez0DNloDiQNs/n/ax2mkfmpukkx/b/testbucket/o/cwallet.sso',
    directory_name => 'DATA_PUMP_DIR');
-- or directory_name => 'dblink_wallet_dir'
end;
/

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


exec dbms_saga_adm.add_broker(broker_name => 'TEST');

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

--do saga2db.sql then this test...

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
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
