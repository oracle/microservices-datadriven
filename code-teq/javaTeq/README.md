# Transactional Event Queues (TxEventQ) example in Java

Transactional Event Queues (TxEventQ) is a messaging platform built into Oracle Database that is used for application workflows, microservices, and event-triggered actions.

## Setup
1. Install an Oracle Database 23ai.
1. Execute the `user_perm.sql` as the `SYS` or `SYSTEM` user.

## Test
1. Create the TxEventQ by running the `CreateTxEventQ` class.
1. Publish a message to the TxEventQ by running the `PublishTxEventQ` class.
1. Consume the published message by running the `ConsumeTXEventQ` class.
