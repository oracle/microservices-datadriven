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

The Oracle Backend for Spring Boot includes an Oracle Database. An instance of the Oracle Autonomous Database Serverless is created during installation.

If you chose the "secure access from anywhere" option for your database during installation (or just accepted the default), then you can use
the Database Actions web user interface to work with your database.
If you chose the "private" option, you need to use a bastion to access the database.

## Using Database Actions

To work with data in the database, you can use the Database Actions web user interface, which can be accessed from the Oracle Cloud
Infrastructure (OCI) Console. The Oracle database is created in the same compartments as Oracle Container Engine for Kubernetes (OKE). In the OCI Console,
navigate to Oracle Autonomous Database (ADB) in the main menu and select the database with the application name that you configured during installation
with the suffix “DB”. For example, `OBAASTSTPSDB`.

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Click on the link to access the database details page, and then click on **Database Actions**:

<!-- spellchecker-disable -->
{{< img name="oci-adb-cloud-portal-details" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

This opens the **Database Actions** page where you have access to many database functions, including the ability to
work with the schemas where your Oracle Backend for Spring Boot data are stored.

## Accessing the Database From a Local Workstation

After creating the Oracle Backend for Spring Boot environment, you have access to Oracle Autonomous Database. For example,
the `CONFIGSERVER.PROPERTIES` table where applications should add their properties. Also, each application can use the same database instance to host its data.

If you chose the `secure access from anywhere` option for database access during installation (or accepted this default), then you can
[download the wallet](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/connect-download-wallet.html) to access
the database from your local machine.

If you chose the `private` option for database access during installation, the database is configured so that it is only accessible from the private
VCN, and access is only possible using the Bastion service provisioned during installation.

1. Create a dynamic port forwarding (SOCKS5) session using the Bastion service.

    Start with ADB access that was created with private end point access only in accordance with security guide lines. For ADB to run SQL commands, you
	need to establish a session between your local workstation and ADB passing by the Bastion service.

    A [Dynamic port forwarding (SOCKS5) session](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingsessions.htm#) is created.

    <!-- spellchecker-disable -->
    {{< img name="oci-bastion-session-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    After the session is created, you can establish the tunnel with your ADB instance by issuing an `ssh` command that you obtain by clicking on
	three dots symbol on right side of the created session. For example:

    ```shell
    ssh -i <privateKey> -N -D 127.0.0.1:<localPort> -p 22 ocid1.bastionsession.oc1.phx....@host.bastion.us-phoenix-1.oci.oraclecloud.com
    ```

2. Connect with the ADB instance using the Oracle SQL Developer Command Line (SQLcl) interface.

    With the tunnel established, you can connect to the ADB instance. 
	
	* First, export the Oracle Net port by processing this commmand:

      ```shell
      export CUSTOM_JDBC="-Doracle.net.socksProxyHost=127.0.0.1 -Doracle.net.socksProxyPort=<PORT> -Doracle.net.socksRemoteDNS=true"
      ```

    * Download the ADB client credentials (wallet files). For example:

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-download-wallet" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    * Connect with SQLcl by processing this command:

      ```shell
      sql /nolog
     ```

      ```sql
      set cloudconfig <WALLET>.zip
      connect ADMIN@<TNS_NAME>
      ```
