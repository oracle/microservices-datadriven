drop table if exists journal cascade constraints;

create table if not exists journal (
    JOURNAL_ID NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 CACHE 20) primary key not null,
    account_number varchar2(10),
    tag_id varchar2(64),
    license_plate varchar2(10),
    vehicle_type varchar2(10),
    toll_date varchar2(25),
    toll_cost number
);
