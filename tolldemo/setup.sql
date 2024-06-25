-- Create tolldemo user and grants, must be done as SYS/ADMIN
create user tolldemo identified by "WelcomE-12345#";
grant resource, connect, unlimited tablespace to tolldemo;
grant execute on dbms_aq to tolldemo;
grant execute on dbms_aqadm to tolldemo;
grant execute on dbms_aqin to tolldemo;
grant execute on dbms_aqjms_internal to tolldemo;
grant execute on dbms_teqk to tolldemo;
grant execute on DBMS_RESOURCE_MANAGER to tolldemo;
grant select_catalog_role to tolldemo;
grant select on sys.aq$_queue_shards to tolldemo;
grant select on user_queue_partition_assignment_table to tolldemo;
commit;

connect tolldemo/Welcome12345

begin
  dbms_aqadm.create_transactional_event_queue (queue_name => 'TollGate', multiple_consumers => true);
  dbms_aqadm.start_queue(tname) ;
end;

-- dodgy bodgy sql slower downer
create or replace function remove_state(plate in varchar2)
return varchar2
is
begin
  dbms_lock.sleep(dbms_random.value(0.004,0.005));
  return regexp_replace(plate, '[A-Z]+-', '', 1, 1);
end;

-- Helper SQL
-- select msg_id, utl_raw.cast_to_varchar2(dbms_lob.substr(user_data)), msg_state from aq$tollgate;

drop table if exists journal cascade constraints;

create table if not exists journal (
    JOURNAL_ID NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 CACHE 20) primary key not null,
    account_number varchar2(10),
    tag_id varchar2(64),
    license_plate varchar2(10),
    vehicle_type varchar2(10),
    toll_date varchar2(25),
    toll_cost number,
    detected_vehicle_type varchar2(10)
);


drop table if exists vehicle cascade constraints;
drop table if exists customer cascade constraints;

create table if not exists customer (
    customer_id varchar2(42) primary key not null, 
    account_number varchar2(42),
    first_name varchar2(32), 
    last_name varchar2(32), 
    address varchar2(64), 
    city varchar2(32), 
    zipcode varchar2(6)
);

create table if not exists vehicle (
    vehicle_id varchar2(42) primary key not null,  
    customer_id varchar2(42), 
    tag_id varchar2(42), 
    state varchar2(16), 
    license_plate varchar2(10), 
    vehicle_type varchar2(10), 
    image varchar2(64)
);

alter table vehicle add constraint customer_fk foreign key (customer_id) references customer(customer_id);

