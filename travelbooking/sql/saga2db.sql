--todo install saga


GRANT ALL ON dbms_saga_adm TO admin;


BEGIN
 DBMS_CLOUD.GET_OBJECT(
    object_uri => 'https://objectstorage.us-phoenix-1.oraclecloud.com/p/hyWE8lAKMz_FJgbnAVQHam83_CIWTzI4Zt6Xn6WRbTeMAp1CGLs1ez0DNloDiQNs/n/ax2mkfmpukkx/b/testbucket/o/cwallet.sso',
    directory_name => 'DATA_PUMP_DIR');
-- or directory_name => 'dblink_wallet_dir'
END;
/

BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'TRAVELAGENCYADMINCRED',
    username => 'ADMIN',
    password => 'Welcome12345');
END;
/


BEGIN
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'travelagencyadminlink',
    hostname => 'adb.us-phoenix-1.oraclecloud.com',
    port => '1522',
    service_name => 'fcnesu1k4xmzwf1_sagadb1_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'TRAVELAGENCYADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
select sysdate from dual@travelagencyadminlink;





create table cartest(text VARCHAR2(100));
create table cars(id NUMBER, available NUMBER);
insert into cars values(1,2);
create or replace package dbms_car_cbk as
function request(saga_id in RAW, saga_sender IN VARCHAR2, payload IN JSON DEFAULT NULL) return JSON;
procedure after_rollback(saga_id in RAW, saga_sender IN varchar2, payload IN JSON DEFAULT NULL);
end dbms_car_cbk;
/
create or replace package body dbms_car_cbk as
function request(saga_id in RAW, saga_sender IN VARCHAR2, payload IN JSON DEFAULT NULL) return JSON as
response JSON;
tickets NUMBER;
begin
  insert into cartest values(saga_sender);
  insert into cartest values(json_serialize(payload));
  select available into tickets from cars where id = 1;
  IF tickets > 0 THEN
    response := json('[{"result":"success"}]');
  ELSE
    response := json('[{"result":"failure"}]');
  END IF;
  update cars set available = available - 1 where id = 1;
  return response;
end;

procedure after_rollback(saga_id in RAW, saga_sender IN varchar2, payload IN JSON DEFAULT NULL)as
begin
  update cars set available = available + 1 where id = 1;
end;
end dbms_car_cbk;
/

--exec dbms_saga_adm.add_participant(participant_name=> 'CarPLSQL' , coordinator_name => 'TravelCoordinator' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => 'dbms_car_cbk' , dblink_to_participant=> 'participantadminlink');
--exec dbms_saga_adm.drop_participant(participant_name=> 'CarPLSQL');

exec dbms_saga_adm.add_participant(participant_name=> 'CarPLSQL' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => 'dbms_car_cbk' , dblink_to_participant=> 'participantadminlink');

--- do begin and enroll on pdb1 then...
--- status will be 0, saga_sender and request payload will be TRAVELAGENCYPLSQL and car:Venza available will be 1 ...
select * from cars;
select * from cartest;
select id, initiator, coordinator, owner, begin_time, status from saga$;

--- do rollback on pdb1 then...
--- status will be 3, available will be 2
select * from cars;
select * from cartest;
select id, initiator, coordinator, owner, begin_time, status from saga$;

exec dbms_saga_adm.add_participant(participant_name=> 'CarJava' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink');
