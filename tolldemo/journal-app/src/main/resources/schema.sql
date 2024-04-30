drop table if exists journal cascade constraints;

create table if not exists journal (
    JOURNAL_ID NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 CACHE 20),
    account_number varchar2(10),
    tag_id varchar2(64),
    license_plate varchar2(10),
    vehicle_type varchar2(10),
    toll_date varchar2(25),
    primary_key(journal_id)
);

-- ALTER TABLE journal ADD CONSTRAINT journal_PK PRIMARY KEY (journal_id) USING INDEX LOGGING;

drop table if exists customer cascade constraints;

create table if not exists customer (
    customer_id varchar2(256),
    account_number varchar2(256),
    first_name varchar2(256),
    last_name varchar2(256),
    address varchar2(256),
    city varchar2(256),
    zipcode varchar2(256),
    primary key(customer_id)
);

-- alter table customer add constraint customer_pk primary key(customer_id) using index logging;

drop table if exists vehicle cascade constraints;

create table if not exists vehicle (
    vehicle_id varchar2(256),
    customer_id varchar2(256),
    tag_id varchar2(256),
    state varchar2(256),
    license_plate varchar2(256),
    vehicle_type varchar2(256),
    image varchar2(256),
    primary key(vehicle_id),
    foreign key(customer_id) references customer(customer_id)
);

-- alter table vehicle add constraint vehicle_pk primary key(vehicle_id) using index logging;

-- alter table "TOLLDEMO"."VEHICLE" add constraint customer_fk foreign key("CUSTOMER_ID") references "CUSTOMER"("CUSTOMER_ID")