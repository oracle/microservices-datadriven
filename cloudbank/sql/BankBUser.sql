


create table accounts (
  accountid varchar(16) PRIMARY KEY NOT NULL,
  accountname varchar(32),
  accountvalue integer CONSTRAINT positive_inventory CHECK (accountvalue >= 0) );