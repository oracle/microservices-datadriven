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
---

The Oracle Backend for Spring Boot and Microservices includes an Oracle database. An instance of Oracle Autonomous Database Serverless is created during installation.

> **_NOTE:_** Oracle recommends that you install your own databases for your production applications. The database provisioned is used for Oracle Backend for Spring Boot metadata and can be used for developement.

If you chose the **Secure Access from Anywhere** option for your database during installation (or just accepted the default), then you can use the **Database Actions** web user interface to work with your database. If you chose the **Private** option, you need to use Bastion to access the database.

## Using Database Actions

To work with data in the database, you can use the **Database Actions** web user interface, which can be accessed from the Oracle Cloud
Infrastructure Console (OCI Console). The Oracle database is created in the same compartments as OCI Container Engine for Kubernetes (OKE).
In the OCI Console, navigate to Oracle Autonomous Database (ADB) in the main menu and select the database with the application name that you
configured during installation with the suffix `DB`. For example, `OBAASTSTPSDB`.

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Click on the link to access the **Database Details** page, and then click on **Database Actions**:

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal-details" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

This opens the **Database Actions** page where you have access to many database functions, including the ability to
work with the schemas where your Oracle Backend for Spring Boot and Microservices data is stored.

## Accessing the Database From a Local Machine

After creating the Oracle Backend for Spring Boot and Microservices environment, you have access to Oracle Autonomous Database. For example, you can access the `CONFIGSERVER.PROPERTIES` table where applications should add their properties. Also, each application can use the same database instance to host its data.

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

    a. First, export the Oracle Net port by processing this commmand:

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
