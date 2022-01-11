
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

exec dbms_saga_adm.add_participant(participant_name=> 'CarPLSQL' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => 'dbms_car_cbk' , dblink_to_participant=> 'participantadminlink');


exec dbms_saga_adm.add_participant(participant_name=> 'HotelJava' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink');
exec dbms_saga_adm.add_participant(participant_name=> 'CarJava' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink');
exec dbms_saga_adm.add_participant(participant_name=> 'FlightJava' ,  dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink');
