+++
archetype = "page"
title = "Learn about Long Running Actions"
weight = 3
+++

There are different models that can be used to coordinate transactions across services.  Three of the most common are XA (Extended Architecture) which focuses on strong consistency, LRA (Long Running Action) which provides eventual consistency, and TCC (Try-Confirm/Cancel) which uses a reservation model. Oracle Backend for Spring Boot and Microservices includes [Oracle Transaction Manager for Microservices](https://www.oracle.com/database/transaction-manager-for-microservices/) which supports all three of these options.

In this module, you will explore the Long Running Action model.  In this model there is a logical coordinator and a number of participants.  Each participant is responsible for performing work and being able to compensate if necessary.  The coordinator essentially manages the lifecycle of the LRA, for example by telling participants when to cancel or complete.

![The Cloud Cash LRA](../images/obaas-lra.png)

You will create the **Transfer service** in the diagram above, and the participant endpoints in the Account service (**deposit** and **withdraw**).  Oracle Transaction Manager for Microservices (also known as "MicroTx") will coordinate the LRA.

You will implement the LRA using the Eclipse Microprofile LRA library which provides an annotation-based approach to managing the LRA, which is very familiar for Spring Boot developers.  

The main annotations used in an LRA application are as follows:

* `@LRA` - Controls the life cycle of an LRA.
* `@Compensate` - Indicates that the method should be invoked if the LRA is cancelled.
* `@Complete` - Indicates that the method should be invoked if the LRA is closed.
* `@Forget` - Indicates that the method may release any resources that were allocated for this LRA.
* `@Leave` - Indicates that this class is no longer interested in this LRA.
* `@Status` - When the annotated method is invoked it should report the status.

If you would like to learn more, there is a lot of detail in the [Long Running Action](https://download.eclipse.org/microprofile/microprofile-lra-1.0-M1/microprofile-lra-spec.html) specification.

### Keeping track of local transactions made in an LRA

Microservices are often designed to be stateless, to push all the state into the datastore.  This makes it easier to scale by running more instances of services, and it makes it easier to debug issues because there is no state stored in process memory.  It also means you need a way to correlate transactions with the LRA they were performed by.

You will add a `JOURNAL` table to the account microservice's database.  This table will contain the "bank account transactions" (deposits, withdrawals, interest payments, etc.) for this account (not to be confused with "database transactions" as in the two-phase commit protocol).  The account service will track LRA's associated with each journal entry (bank account transaction) in a column in the journal table.

As LRA is an eventual consistency model, the approach you will take in the account service will be to store bank account transactions as "pending" in the journal table.  Pending transactions will not be considered when calculating the account balance until they are finalized ("completed").  When the LRA reaches the "complete" phase, the pending transactions will be considered finalized and the account balance will be updated to reflect those transactions.

> **Note**: Unlike Java Transaction Architecture (JTA) where "in-doubt" tables are created automatically to keep track of pending transactions, LRA is only concerned with the orchestration of the API calls, so participants need to track transactions themselves.  In this module you will use the journal table both to store the transactions and to track the lRA.  Of course, this could also be done with separate tables if desired.

You will now start implementing the Cloud Cash Payment LRA.
