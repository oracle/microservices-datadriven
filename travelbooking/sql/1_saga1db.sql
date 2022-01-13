

--Create Broker
exec dbms_saga_adm.add_broker(broker_name => 'TEST');

--Create Coordinator (Note that if the coordinator is co-located with the broker, dblink_to_broker should be NULL)
exec dbms_saga_adm.add_coordinator( coordinator_name => 'TravelCoordinator',  dblink_to_broker => null,   mailbox_schema => 'admin',  broker_name => 'TEST',  dblink_to_coordinator => 'travelagencyadminlink');

--Add TravelAgency callback package
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

--Add participant
exec dbms_saga_adm.add_participant(  participant_name => 'TravelAgencyPLSQL',   coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => 'dbms_ta_cbk' ,   dblink_to_participant => null);


