
drop table vehicle;
drop table customer;

create table customer (
    customer_id varchar2(42) primary key not null, 
    account_number varchar2(42),
    first_name varchar2(32), 
    last_name varchar2(32), 
    address varchar2(64), 
    city varchar2(32), 
    zipcode varchar2(6)
);

create table vehicle (
    vehicle_id varchar2(42) primary key not null,  
    customer_id varchar2(42), 
    tag_id varchar2(42), 
    state varchar2(16), 
    license_plate varchar2(10), 
    vehicle_type varchar2(10), 
    image varchar2(64)
);

alter table vehicle add constraint customer_fk foreign key (customer_id) references customer(customer_id);