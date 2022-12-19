
# Oracle Mobile Backend as a Service - Developer Preview

Oracle Mobile Backend as a Service (MBaaS) allows developers to build and deploy mobile applications using Parse mobile APIs, and provision a backend as a service with the Oracle Database and other infrastructure components that operate on multiple clouds. This service vastly simplifies the task of building, testing, and operating a mobile app dev platform for reliable, secure, and scalable enterprise applications. This version includes an Oracle Database storage adapter for Parse (Parse already has MongoDB and Postgres adapters), and a quick demo of Google Firebase APIs emulated using Parse APIs.

The MBaaS is based on the [Parse Platform](https://parseplatform.org/).

**> > > Put video intro here < < <**

In addition to an Oracle Autonomus Database Shared instance, the following software components are deployed in an Oracle Cloud Infrastructure Container Engine for Kubernetes (OKE) for customer usage with Oracle MBaaS:

* Parse Server, plus the Oracle Database storage adapter for Parse
* Parse Dashboard

## Developer Preview

This release is a *Developer Preview*. This means that not all functionality is complete. In this release, approximately 80% of the Parse APIs are working. For
interested developers, approximately 2100 of 2700 tests run successfully. This release is based on Parse Server version 5.2.7 and Parse Dashboard 5.0.0. We are
releasing this as a developer preview to allow interested developers to try it and give feedback.

The following API families are mostly working: 

* Database, including query
* Identity/Security
* File
* Caching
* GeoPoints
* Config
* Data

The following API families are not expected to work in this release:

* Cloud Functions
* GraphQL
* Live Query
* Push Notifications

The Parse API exposed is exactly the same as an upstream Parse Server (version 5.2.7) - there are no changes to the public facing API.
All existing Parse SDKs *should* work as-is with this developer preview (for those APIs that are working).


## About the Oracle Database storage adapter for Parse

This developer preview includes an Oracle Database storage adapter for Parse based on the Parse Server 5.2.7 code line. The storage
adapter is implemented using the [Node.js node-oracledb](https://oracle.github.io/node-oracledb/) library. Data are stored in the
database in JSON collections, using the [Simple Oracle Document Access (SODA)](https://docs.oracle.com/en/database/oracle/simple-oracle-document-access/)
API.

