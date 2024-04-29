drop table if exists journal cascade constraints;

create table if not exists journal (
    journal_id INTEGER generated as identity not null,
    tag_id varchar2(64),
    license_plate varchar2(10),
    vehicle_type varchar2(10),
    toll_date date
);