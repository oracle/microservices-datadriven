---
title: "Database Access"
resources:
  - name: oci-adb-cloud-portal
    src: "oci-adb-cloud-portal.png"
    title: "Oracle Autonomous DB Cloud Portal"
  - name: oci-adb-cloud-portal-details
    src: "oci-adb-cloud-portal-details.png"
    title: "Oracle Autonomous DB Details"
  - name: oci-bastion-session-create
    src: "oci-bastion-session-create.png"
    title: "Download ADB client credential"
  - name: oci-adb-download-wallet
    src: "oci-adb-download-wallet.png"
    title: "Download ADB client credential"
  - name: oci-adb-select-db
    src: "oci-adb-select-db.png"
    title: "Select ADB Database"
---

The Oracle Backend for Spring Boot and Microservices includes an Oracle database. An instance of Oracle Autonomous Database Serverless is created during installation.

If you selected the **PRIVATE_ENDPOINT** option, you need to use a Bastion to access the database.

> **_NOTE:_** Oracle recommends that you install your own databases for your production applications. The database provisioned is used for Oracle Backend for Spring Boot metadata and can be used for development.

## Accessing the Database

> **_NOTE:_** Oracle recommends that you install SQLcl to access the database from a local machine. [SQLcl installation guide](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/). Other tools can be used but is not documented here.

- [Using Database Actions from the OCI Console](#access-the-oracle-autonomous-database-using-database-actions)
- [Local access using Database Wallet and SQLcl (**SECURE_ACCESS** installation)](#accessing-the-oracle-autonomous-database-from-a-local-machine-using-database-wallet-and-sqlcl)
- [Local access using Wallet and SQLcl using a Bastion (**PRIVATE_ENDPOINT** installation)](#accessing-the-oracle-autonomous-database-from-a-local-machine-using-database-wallet-and-sqlcl-using-a-bastion)

## Access the Oracle Autonomous Database using Database Actions

You can use the **Database Actions** web user interface, which can be accessed from the Oracle Cloud Infrastructure Console (OCI Console) to access the database. The Oracle database is created in the compartment specified during installation of Oracle Backend for Spring Boot and Microservices.

In the OCI Console, navigate to Oracle Autonomous Database (ADB) in the main menu.

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal" size="large" lazy=false >}}
<!-- spellchecker-enable -->

Click on the link **Autonomous Transaction Processing**, and then select the database with the application name that you configured during installation with the suffix `DB`. In this example the Database name is `CALFDB` (make sure that you have selected the correct Compartment).

<!-- spellchecker-disable -->
{{< img name="oci-adb-select-db" size="large" lazy=false >}}
<!-- spellchecker-enable -->

Click on **Database Actions**. This opens the **Database Actions** page where you have access to many database functions, including the ability to work with data stored by Oracle Backend for Spring Boot and Microservices.

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal-details" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

## Accessing the Oracle Autonomous Database From a Local Machine using Database Wallet and SQLcl

If **SECURE_ACCESS** was selected during installation you can access the database using the following steps.

### Download the Oracle Autonomous Database Wallet

### Connect to the Oracle Autonomous Database

## Accessing the Oracle Autonomous Database From a Local Machine using Database Wallet and SQLcl using a Bastion

If **PRIVATE_ENDPOINT** was selected during installation you can access the database using the following steps.

If you chose the **Secure Access from Anywhere** option for database access during installation (or accepted this default), then you must
[download the wallet](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/connect-download-wallet.html) to access the database from your local machine.

If you chose the **Private** option for database access during installation, the database is configured so that it is only accessible from
the private Virtual Cloud Network (VCN), and access is only possible using the Bastion service provisioned during installation.

Process the following steps:

1. Create a Dynamic Port Forwarding (SOCKS5) Session using the Bastion service.

    Start with Autonomous Database (ADB) access that was created with private endpoint access only in accordance with security guidelines.  For ADB to run SQL commands, you need to establish a session between your local machine and ADB using the Bastion service.

    A [Dynamic Port Forwarding (SOCKS5) Session](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingsessions.htm#) is created.

    For example:

    <!-- spellchecker-disable -->
    {{< img name="oci-bastion-session-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. After the session is created, you can establish the tunnel with your ADB instance by issuing an `ssh` command that you obtain by clicking on the three dots symbol on right side of the created session. For example:

    ```shell
    ssh -i <privateKey> -N -D 127.0.0.1:<localPort> -p 22 ocid1.bastionsession.oc1.phx....@host.bastion.us-phoenix-1.oci.oraclecloud.com
    ```

1. Connect with the ADB instance using the Oracle SQL Developer Command Line (`SQLcl`) interface. With the tunnel established, you can connect to the ADB instance:

    a. First, export the Oracle Net port by processing this command:

    ```shell
    export CUSTOM_JDBC="-Doracle.net.socksProxyHost=127.0.0.1 -Doracle.net.socksProxyPort=<PORT> -Doracle.net.socksRemoteDNS=true"
    ```

    b. Download the ADB client credentials (wallet files). For example:
       <!-- spellchecker-disable -->
       {{< img name="oci-adb-download-wallet" size="medium" lazy=false >}}
       <!-- spellchecker-enable -->

    c. Connect with `SQLcl` by processing this command:

      ```shell
       sql /nolog
      ```

    d. Connect to the database using the wallet:

      ```sql
      set cloudconfig <WALLET>.zip
      connect ADMIN@<TNS_NAME>
      ```
