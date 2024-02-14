---
title: "Database"
description: "Database Options and Configuration"
keywords: "database spring springboot microservices oracle"
resources:
  - name: oci-byo-db-other
    src: "byo-db-other.png"
    title: "Bring Your Own Database - Other"
  - name: oci-byo-db-adb-s
    src: "byo-db-adb-s.png"
    title: "Bring Your Own Database - ADB-S"
---
The Oracle Backend for Spring Boot and Microservices has specific networking requirements to ensure resource communication while providing security through isolation and networking rules.  

The **standard installation** will provision a new Virtual Cloud Network (VCN) with the required subnets all networking rules to get started using the Oracle Backend for Spring Boot and Microservices quickly.  To use an existing VCN, please follow the [Bring Your Own VCN](#bring-your-own-oci-vcn) instructions.

> For **custom installations**, including On-Premises, it is the responsibility of the customer to ensure network access controls to provide both operational access and security.  The Oracle Cloud Infrastructure (OCI) **standard installation** setup can be used as a general template.

# Bring Your Own Database

Using the **Standard Edition** you can use a pre-created Oracle Database for the Oracle Backend for Spring Boot and Microservices **Metadata Database**.  

The following are minimum requirements for a BYO Oracle Database:

* Version: 19c+
* Network Access to the Database Listener
* Database User with appropriate privileges (see below)

## Database User Privileges

The database user for the the Oracle Backend for Spring Boot and Microservices **Metadata Database** is used to create other users and allow them to proxy through this user for database access.  While the `SYSTEM` or `ADMIN` (for ADB-S) will work, they are over-privileged and should not be used in production environments.


## Configuration

1. During the configuration of the Oracle Backend for Spring Boot and Microservices, ensure that the **Edition** is set to **Standard**:

    ![Standard Edition](../images/standard_edition.png "Standard Edition")

1. Enable and Configure *Bring Your Own Virtual Network*

1. Tick the Bring Your Own Database" checkbox and, depending on the *Bring Your Own Database - Type*, provide the appropriate values.

### ADB-S

   - `BYO ADB-S Compartment` : The compartment of the existing ADB-S.
   - `Bring Your Own Database - Autonomous Database` : The ADB-S name.
   - `Bring Your Own Database - Username` : The existing database user with the appropriate privileges.
   - `Bring Your Own Database - Password` : The password for the existing database user.

    <!-- spellchecker-disable -->
    {{< img name="oci-byo-db-adb-s" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

### Other

   - `Bring Your Own Database - Connect String` : The connect string for the database (PDB) in Long Format.
   - `Bring Your Own Database - Username` : The existing database user with the appropriate privileges.
   - `Bring Your Own Database - Password` : The password for the existing database user.

    <!-- spellchecker-disable -->
    {{< img name="oci-byo-db-other" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

   The *Connect String* should be in Long Format, for example:
   ```bash
   (DESCRIPTION=(ADDRESS=(host=oracle://somedb.example.com)(protocol=TCP)(port=1521))
      (CONNECT_DATA=(SERVICE_NAME=orclpdb)))
   ```