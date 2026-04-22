create table customer if not exists (
    CUSTOMER_ID varchar2(256),
    CUSTOMER_NAME varchar2(256),
    CUSTOMER_EMAIL varchar2(256),
    DATE_BECAME_CUSTOMER date,
    CUSTOMER_OTHER_DETAILS varchar2(256),
    PASSWORD varchar2(256)
);
insert into customer (customer_id, customer_name, customer_email, customer_other_details, password)
values ('abc123', 'Bob Drake', 'bob@drake.com', '', '$2b$12$JFwSbCFoLsVQZ32hHnbFqerr7Ig8ge6icazT03K6p.npeOIzyI3ia');
commit;
