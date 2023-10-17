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
  - name: oci-adb-download-wallet
    src: "oci-adb-download-wallet.png"
    title: "Download the ADB Wallet"
  - name: oci-adb-wallet-password
    src: "oci-adb-wallet-password.png"
    title: "Wallet Password"
  - name: oci-adb-sqlcl-load-wallet
    src: "oci-adb-sqlcl-load-wallet.png"
    title: "Load the Wallet"
  - name: oci-adb-show-tns
    src: "oci-adb-show-tns.png"
    title: "Load the Wallet"
  - name: oci-adb-admin-connect
    src: "oci-adb-admin-connect.png"
    title: "Load the Wallet"
  - name: oci-adb-bastion
    src: "oci-adb-bastion.png"
    title: "Load the Wallet"
  - name: oci-adb-private-ip
    src: "oci-adb-private-ip.png"
    title: "ADB-S Private IP Address"
---

The Oracle Backend for Spring Boot and Microservices includes an Oracle database. An instance of Oracle Autonomous Database Serverless (ADB-S) is created during installation. The ADB-S is used for Oracle Backend for SPring Boot and Microservices metadata and Spring Cloud Config Server.

If you selected the **PRIVATE_ENDPOINT_ACCESS** option, you need to use a [Bastion](#accessing-the-adb-s-from-a-local-machine-using-database-wallet-and-sqlcl-using-a-bastion) to access the database.

> **NOTE:** Oracle recommends that you install your own database and PDBs for your production applications. The database provisioned is used for Oracle Backend for Spring Boot metadata and can be used for development.

## Accessing the Database

> **_NOTE:_** Oracle recommends that you install SQLcl to access the database from a local machine. [SQLcl installation guide](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/). Other tools can be used but is not documented here.

- [Using Database Actions from the OCI Console](#access-the-oracle-adb-s-using-database-actions)
- [Local access using Database Wallet and SQLcl (**SECURE_ACCESS** installation)](#accessing-the-adb-s-from-a-local-machine-using-database-wallet-and-sqlcl)
- [Local access using Wallet and SQLcl using a Bastion (**PRIVATE_ENDPOINT_ACCESS** installation)](#accessing-the-adb-s-from-a-local-machine-using-database-wallet-and-sqlcl-using-a-bastion)

## Access the Oracle ADB-S using Database Actions

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
{{< img name="oci-adb-cloud-portal-details" size="large" lazy=false >}}
<!-- spellchecker-enable -->

## Accessing the ADB-S From a Local Machine using Database Wallet and SQLcl

If **SECURE_ACCESS** was selected during installation you can access the database using the following steps.

### Download the ADB-S Wallet

If you chose the **SECURE_ACCESS** option for database access during installation (or accepted this default), then you have to [download the wallet](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/connect-download-wallet.html) to access the database from your local machine.

The wallet can be downloaded from the OCI Console, by clicking **Database Connection**, followed by **Download Wallet**. Store the wallet in a safe place.

<!-- spellchecker-disable -->
{{< img name="oci-adb-download-wallet" lazy=false >}}
<!-- spellchecker-enable -->

You have to enter a password for the Wallet.

<!-- spellchecker-disable -->
{{< img name="oci-adb-wallet-password" lazy=false >}}
<!-- spellchecker-enable -->

### Connect to the ADB-S using SQLcl

1. Get the ADMIN user password from k8s secret. in the exa,ple below `calfdb` needs to be replaced with the name of database in the installation.

    ```shell
     kubectl -n application get secret calfdb-db-secrets -o jsonpath='{.data.db\.password}' | base64 -d
    ```

1. Open a terminal Window and start SQLcl with the `/nolog` option.

    ```shell
    sql /nolog
    ```

1. Load the Wallet using the command `set cloudconfig...`. In this example the wallet name is Wallet_CALFDB.zip.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-sqlcl-load-wallet" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Get the TNS name connection names from the wallet by executing this command:

    ```shell
    show tns
    ```
    <!-- spellchecker-disable -->
    {{< img name="oci-adb-show-tns" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Connect as the ADMIN user to the database using the password you obtained from the k8s secret previously using the command `connect` followed by `ADMIN`, password collected and the TNS Name.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-admin-connect" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    You are now connected to the database that is provided when installing Oracle Backend for Spring Boot and Microservices on OCI.

> **_NOTE:_** Oracle recommends that you install your own databases, PDBs for your production applications. The database provisioned is used for Oracle Backend for Spring Boot metadata and can be used for development.

## Accessing the ADB-S From a Local Machine using Database Wallet and SQLcl using a Bastion

If **PRIVATE_ENDPOINT_ACCESS** was selected during installation you can access the database using the following steps. You are going to need a Private Key pair to be able to use the Bastion Service to access the ADB-S.

### Download and modify the Wallet the ADB-S Wallet using Private Access

If you chose the **PRIVATE_ENDPOINT_ACCESS** option for database access during installation (or accepted this default), then you have to [download the wallet](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/connect-download-wallet.html) to access the database from your local machine.

1. The wallet can be downloaded from the OCI Console, by clicking **Database Connection**, followed by **Download Wallet**. Store the wallet in a safe place.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-download-wallet" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. You have to enter a password for the Wallet.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-wallet-password" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Go to the directory where you stored the Wallet and execute the following command. Replace `<Wallet-File>` with the name of your Wallet file including `.zip`:

    ```shell
    zip -oq <Wallet-File> tnsnames.ora && \
      sed -i '' 's/host=[^)]*/host=localhost/' tnsnames.ora && \
      zip -uq <Wallet-File> tnsnames.ora
    ```

    > **_NOTE:_** On certain platforms you may need to use `unzip` instead of `zip` as the command.

### Connect to the ADB-S using SQLcl via a Bastion

1. Get the IP address of the deployed Autonomous Database. T=You can find the IP address in the OCI Console:

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-private-ip" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Create a SSH Port Forwarding Session using the Bastion service.

    A Bastion service is deployed when selecting **PRIVATE_ENDPOINT_ACCESS** during installation. To access the Oracle Autonomous Database you need to create a session between your local machine and the Oracle Autonomous Database using the Bastion Service. [Create a Dynamic Port Forwarding (SOCKS5) Session](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingsessions.htm#).

    Select the Bastion Service in the **Identity & Security** Menu:

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-bastion" lazy=false >}}
    <!-- spellchecker-enable -->

    Select the Bastion service for your deployment and click **Create Session**. This will bring up a dialog box where you need to fill in the values for your installation.

    - `Session Type` : Select `SSH port forwarding session`.
    - `Session Name` : Enter a name for the session.
    - `IP Address` : Enter the Private IP Address for the ADB-S.
    - `Port` : Enter `1522` as the port number
    - `SSH Key` : Add a Public SSH Key that will be used for the session.

    <!-- spellchecker-disable -->
    {{< img name="oci-bastion-session-create" lazy=false >}}
    <!-- spellchecker-enable -->

1. After the session is created, establish a SSH tunnel your your ADB instance by issuing an `ssh` command in a terminal window. The SSH is obtained obtain by clicking on the three dots symbol on right side of the created session in the OCI COnsole. The session will run until you close the terminal window.

    Replace `<privateKey>` with path to your Private Key and `<localPort>` with the local port you want to use. For example:

    ```shell
    ssh -i <privateKey> -N -L <localPort>:10.113.0.28:1522 -p 22 ocid1.bastionsession.oc1.....@host.bastion......
    ```

1. Get the ADMIN user password from k8s secret. in the exa,ple below `bluegilldb` needs to be replaced with the name of database in the installation.

    ```shell
     kubectl -n application get secret bluegilldb-db-secrets -o jsonpath='{.data.db\.password}' | base64 -d
    ```

1. Open a terminal Window and start SQLcl with the `/nolog` option.

    ```shell
    sql /nolog
    ```

1. Load the Wallet using the command `set cloudconfig...`. In this example the wallet name is Wallet_CALFDB.zip.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-sqlcl-load-wallet" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Get the TNS name connection names from the wallet by executing this command:

    ```shell
    show tns
    ```
    <!-- spellchecker-disable -->
    {{< img name="oci-adb-show-tns" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Connect as the ADMIN user to the database using the password you obtained from the k8s secret previously using the command `connect` followed by `ADMIN`, password collected and the TNS Name.

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-admin-connect" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    You are now connected to the database that is provided when installing Oracle Backend for Spring Boot and Microservices on OCI.

> **_NOTE:_** Oracle recommends that you install your own databases, PDBs for your production applications. The database provisioned is used for Oracle Backend for Spring Boot metadata and can be used for development.
