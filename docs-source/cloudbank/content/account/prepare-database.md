+++
archetype = "page"
title = "Prepare Database Objects"
weight = 5
+++

1. Get the database user `ADMIN` password

    The ADMIN password can be retrieved from a k8s secret using this command. Replace the **DBNAME** with the name of your database. Save the password as it will be needed in later steps.

    ```shell
    $ kubectl -n application get secret DBNAME-db-secrets -o jsonpath='{.data.db\.password}' | base64 -d
    ```

    If you don't know the name of the database, execute the following command and look for the line **DBNAME-db-secrets**.

    ```shell
    $ kubectl -n application get secrets
    ```

1. Start SQLcl and load the Wallet

    The Accounts service is going to have two main objects - an `account` and a `journal`. Here are the necessary steps to create the objects in the database

    If you installed SQLcl as recommended, you can connect to your database using this SQLcl (or use the SQLcl session created during module two, Setup). Start SQLcl in a new terminal window.

    ```shell
    $ sql /nolog

    SQLcl: Release 22.4 Production on Fri Mar 03 12:25:24 2023

    Copyright (c) 1982, 2023, Oracle.  All rights reserved.

    SQL>
    ```

1. Load the Wallet

    When you are connected, run the following command to load the Wallet you downloaded during the Setup lab. Replace the name of the waller and location of the Wallet to match your environment.

    ```sql
    SQL> set cloudconfig /path/to/wallet/wallet-name.zip
    ```

1. Connect to the Database

    If you need to see what TNS Entries you have run the `show tns` command. For example:

    ```sql
    SQL> show tns
    CLOUD CONFIG set to: /Users/atael/tmp/wallet/Wallet_CBANKDB.zip

    TNS Lookup Locations
    --------------------

    TNS Locations Used
    ------------------
    1.  /Users/atael/tmp/wallet/Wallet_CBANKDB.zip
    2.  /Users/atael

    Available TNS Entries
    ---------------------
    CBANKDB_HIGH
    CBANKDB_LOW
    CBANKDB_MEDIUM
    CBANKDB_TP
    CBANKDB_TPURGENT
    ```

    Connect to the database using the `ADMIN` user, the password you retrieved earlier and the TNS name `DBNAME_tp`.

    ```sql
    SQL> connect ADMIN/your-ADMIN-password@your-TNS-entry
    Connected.
    ```

1. Create Database Objects

    Run the SQL statements below to create the database objects:

    ```sql
    
    -- create a database user for the account service
    create user account identified by "Welcome1234##";

    -- add roles and quota
    grant connect to account;
    grant resource to account;
    alter user account default role connect, resource;
    alter user account quota unlimited on users;

    -- create accounts table
    create table account.accounts (
      account_id            number generated always as identity (start with 1 cache 20),
      account_name          varchar2(40) not null,
      account_type          varchar2(2) check (account_type in ('CH', 'SA', 'CC', 'LO')),
      customer_id           varchar2 (20),
      account_opened_date   date default sysdate not null,
      account_other_details varchar2(4000),
      account_balance       number
    ) logging;

    alter table account.accounts add constraint accounts_pk primary key (account_id) using index logging;
    
    comment on table account.accounts is 'CloudBank accounts table';

    -- create journal table
    create table account.journal (
      journal_id      number generated always as identity (start with 1 cache 20),
      journal_type    varchar2(20),
      account_id      number,
      lra_id          varchar2(1024) not null,
      lra_state       varchar2(40),
      journal_amount  number
    ) logging;

    alter table account.journal add constraint journal_pk primary key (journal_id) using index logging;

    comment on table account.journal is 'CloudBank accounts journal table';
    /
    ```

  Now that the database objects are created, you can configure Spring Data JPA to use them in your microservice.

