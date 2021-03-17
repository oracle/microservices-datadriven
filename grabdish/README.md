# Simplify microservices architecture with Oracle Converged Database

GrabDish is a sample application for mobile-food ordering. This code illustrates
the simplicity in designing a data-driven microservices platform using the
Oracle converged database and OCI services.

Often there are tough architecture choices for setting up the infrastructure,
operating it, tuning it, upgrading it and scaling it. In this workshop you will
simplify the process by setting up Transactional Event Queues in the
Oracle Autonomous Database which brings the best of JMS messaging and Kafka
produce/consume together with transactions.
This combination of data and and events delivered with notifications is ideal to
build scalable microservices using a multi-model, multi-tenant architecture.

This workshop will help you understand the technical capabilities inside and
outside the Oracle database to support scalable data and event-driven
microservices architecture.

You will create a highly scalable application that runs on
Oracle Container Engine for Kubernetes and will build,
deploy and manage the Helidon microservices that interact through
REST and messaging as well as back-end datastores deployed as Oracle
pluggable databases inside Oracle Autonomous Transaction Processing.
You will see the scaling of both application layer and data platform layer,
as well as polyglot support –
programming in Java with Helidon MP and SE, Python, and node.js.

The steps followed in the labs above follow the order of scripts being executed below

| Step   | Description   |
| ------ | ------        |
| 1      | #download src |
| 2      | #create compartment and k8s cluster, note compartment and region |
| 3      | setCompartmentId.sh COMPARMENT_OCID REGION_ID   |
| 4      | create vault secrets, note ocids |
| 5      | createATPPDBs.sh ADMIN_PW_OCID FRONTEND_AUTH_PW_OCID  |
| 6      | #create OCIR registry in console, note namespace and repos name  |
| 7      | addOCIRInfo.sh OCIR_NAMESPACE OCIR_REPOS_NAME |
| 8      | #create auth token in console, note it |
| 9      | dockerLogin.sh USERNAME "AUTH_TOKEN"  |
| 10     | installGraalVMJaegerAndFrontendLB.sh  |
| 11     | setJaegerAddress.sh |
| 12     | build.sh #builds and pushes images |
| 13     | frontend-helidon/deploy.sh #deploy and verify frontend ms |
| 14     | #download wallet from console, create and note objectstore link |
| 15     | atp-secrets-setup/createAll.sh DB_WALLET_OBJECTSTORAGE_LINK  |
| 16     | atpaqadmin/deploy.sh #create DB and AQ queue setup with admin service|
| 17     | #deploy.sh other microservices and test app |

## Resources

[Workshops]: https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/livelabs-workshop-cards?p100_role=12&p100_focus_area=35&me=126
[Livelabs page of the Groundbreakers Developer Community]: https://community.oracle.com/tech/developers/categories/building-microservices-with-oracle-converged-database
[Helidon]: https://helidon.slack.com/archives/CCS216A5A

## License

Copyright (c) 2021 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at <https://oss.oracle.com/licenses/upl>.