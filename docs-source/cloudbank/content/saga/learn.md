+++
archetype = "page"
title = "Learn about the Saga pattern"
weight = 2
+++

When you adopt microservices architecture and start to apply the patterns, you rapidly run into a situation where you have a business transaction that spans across multiple services.  

### Database per service

The [Database per service](https://microservices.io/patterns/data/database-per-service.html) pattern is a generally accepted best practice which dictates that each service must have its own "database" and that the only way other services can access its data is through its public API.  This helps to create loose coupling between services, which in turn makes it easier to evolve them independently and prevents the creation of a web of dependencies that make application changes increasingly difficult over time.  In reality, this pattern may be implemented with database containers, or even schema within one database with strong security isolation, to prevent the proliferation of database instances and the associated management and maintenance cost explosion.

### Transactions that span services

The obvious challenge with the Database per service pattern is that a database transaction cannot span databases, or services.  So if you have a scenario where you need to perform operations in more than one service's database, you need a solution for this challenge.

A saga is a sequence of local transactions.  Each service performs local transactions and then triggers the next step in the saga.  If there is a failure due to violating a business rule (e.g. trying to withdraw more money than is in an account) then the saga executes a series of compensating transactions to undo the changes that were already made.

### Saga coordination

There are two ways to coordinate sagas:

* Choreography - each local transaction publishes domain events that trigger local transactions in other services
* Orchestration - an orchestrator (object) tells the participants what local transactions to execute

You will use the orchestration approach in this module.

> **Note**: You can learn more about the saga pattern at [microservices.io](https://microservices.io/patterns/data/saga.html).

### The Cloud Cash Transfer Saga

In this module you will implement a saga that will manage transferring funds from one user to another.

When the user submits their request, a microservice will pick up the request and invoke the **Transfer** service (which you will write in this module) to process the transfer.

