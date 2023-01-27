---
title: Database Access
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

The Oracle Backend for Spring Boot includes an Oracle Database. An instance of the Oracle Autonomous Database (Shared) is created during installation.

If you chose the "secure access from anywhere" option for your database during installation (or just accepted the default), then you can use
the Database Actions web user interface to work with your database.
If you chose the "private" option, you need to use a bastion to access the database.

## Using Database Actions

To work with data in the database, you can use the Database Actions interface, which can be accessed from the OCI Console. The Oracle Database is created in the same compartments as OKE. In the OCI Console, navigate to Autonomous Database in the main menu and select the database with the Application Name you configured during install, with the suffix “DB”, for example “OBAASTSTPSDB”.

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Click on the link to access the database details page, and then click on the “Database Actions” button:

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal-details" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

This will open the Database Actions page, where you have access to many database functions, including the ability to
work with the schemas where your Oracle Backend for Spring Boot data are stored.

## Accessing the database from a local workstation

After creating the Oracle Backend for Spring Boot environment, you will have to access to Autonomous Database for access, for example, the `CONFIGSERVER.PROPERTIES`, a table where Applications should add their properties. Also, each application can use the same database instance to host its data.

If you chose the "secure access from anywhere" option for database access during installation (or accepted this default), you can
[download the wallet](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/connect-download-wallet.html) to access
the database from your local machine.

If you chose the "private" option for database access during installation, the database will be configure so that it is only accessible from the private VCN, and access will only be possible using the Bastion Service provisioned during installation.

1. Create Dynamic port forwarding (SOCKS5) session using Bastion service.

    Let's start with ADB access that was created with private end point access only following security guidance. To allow you get access to ADB to run sql commands you will need to stablish an session between your local workstation and ADB passing by the Bastion service.

    We will create a [Dynamic port forwarding (SOCKS5) session](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingsessions.htm#).

    <!-- spellchecker-disable -->
    {{< img name="oci-bastion-session-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    After session create you will be able to stablish the tunnel with your ADB Instance issuing a SSH command that you can obtain clicking on three dots menu on right side of the session created.

    ```shell
    ssh -i <privateKey> -N -D 127.0.0.1:<localPort> -p 22 ocid1.bastionsession.oc1.phx....@host.bastion.us-phoenix-1.oci.oraclecloud.com
    ```

2. Connect with ADB Instance using SQLcl

    With tunnel stablished, you will be able to connect with ADB instance. First export the Oracle Net port executing the next commmand:

    ```shell
    export CUSTOM_JDBC="-Doracle.net.socksProxyHost=127.0.0.1 -Doracle.net.socksProxyPort=<PORT> -Doracle.net.socksRemoteDNS=true"
    ```

    Download ADB client credentials (Wallet):

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-download-wallet" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Connect with SQLcl

    ```shell
    sql /nolog
    ```

    ```sql
    set cloudconfig <WALLET>.zip
    connect ADMIN@<TNS_NAME>
    ```
