-- Only for local development
create user customer identified by Welcome1234## default TABLESPACE users QUOTA UNLIMITED on users;
grant connect, resource to customer;