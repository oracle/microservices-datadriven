# Transactional Event Queues (TxEventQ) example in Java

Transactional Event Queues (TxEventQ) is a messaging platform built into Oracle Database that is used for application workflows, microservices, and event-triggered actions.

## Setup
1. Install an Oracle Database 23ai.
1. Execute the `user_perm.sql` as the `SYS` or `SYSTEM` user. The script prompts for the `testuser` password without echoing it.
1. Set the database password in the environment before running the examples:

   ```bash
   export TEQ_DB_PASSWORD='<database-password>'
   ```

   Optional environment variables:

   ```bash
   export TEQ_DB_USER='testuser'
   export TEQ_DB_URL='jdbc:oracle:thin:@//localhost:1521/freepdb1'
   export TEQ_TOPIC_NAME='my_jms_teq'
   ```

## Test
1. Create the TxEventQ by running the `CreateTxEventQ` class.
1. Publish a message to the TxEventQ by running the `PublishTxEventQ` class.
1. Consume the published message by running the `ConsumeTXEventQ` class.
