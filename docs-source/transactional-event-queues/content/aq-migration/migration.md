+++
archetype = "page"
title = "AQ Migration"
weight = 1
+++


This section provides a detailed guide for migrating from Oracle Advanced Queuing (AQ) to Transactional Event Queues (TxEventQ). The migration process uses the [DBMS_AQMIGTOOL](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html) package to ensure minimal disruption of existing messaging workflows.

Users of AQ are recommended to migrate to TxEventQ for increased support, performance, and access to new database features. It is recommended to read through the document fully before attempting migration.

* [DBMS_AQMIGTOOL Overview](#dbms_aqmigtool-overview)
* [Migration Workflow](#migration-workflow)
  * [Checking Compatibility](#checking-compatibility)
  * [Initiating Migration](#initiating-migration)
  * [Checking Migration Status](#checking-migration-status)
  * [Commit the Migration](#commit-the-migration)
  * [Checking and Handling Migration Errors](#checking-and-handling-migration-errors)
  * [Cancelling and Recovering Migration](#cancelling-and-recovering-migration)
* [Limitations and Workarounds](#limitations-and-workarounds)


## DBMS_AQMIGTOOL Overview

The migration tool interface provides the following functionalities:

- Migration may be performed in AUTOMATIC, INTERACTIVE, OFFLINE, or ONLY_DEFINITION mode, each mode providing specific use cases and benefits.
  - DBMS_AQMIGTOOL.AUTOMATIC: Enqueue and dequeue operations are allowed during migration, and a background job will commit the migration once the AQ is empty and no unsupported features are detected. 
  - DBMS_AQMIGTOOL.INTERACTIVE (Default): Enqueue and dequeue operations are allowed, and the user must commit the migration. 
  - DBMS_AQMIGTOOL.OFFLINE: Only dequeue operations are allowed during migration, which can help in draining the AQ. 
  - DBMS_AQMIGTOOL.ONLY_DEFINITION: A TxEventQ copy is made from the AQ configuration, and messages are not migrated. Both the AQ and TxEventQ remain in the system after migration is committed with separate message streams. This option is recommended for users who prefer a more manual or custom migration.
- Users may decide to commit the migration or revert to AQ via the migration interface.
- During migration, in-flight messages can be tracked by viewing messages not in the PROCESSED state for both the AQ and TxEventQ.
- A migration history is recorded for all queues.
- Users may optionally purge old AQ messages if they wish to discard the data after migration.
- AQ Migration supports both rolling upgrades and Oracle GoldenGate (OGG) replication.
- During online migrations, it is safe for applications to continue enqueue/dequeue operations as normal.

## Migration Workflow

1. Check compatibility of migration and review the [limitations and workarounds](#limitations-and-workarounds).

2. Start the migration with the DBMS_AQMIGTOOL.INIT_MIGRATION procedure, which creates an interim TxEventQ by copying the AQ's configuration, including payload type, rules, subscribers, privileges, notifications, and more. Administrative queue changes (`alter queue`) are restricted until the migration is completed or canceled.

3. During migration, queue messages transition to the TxEventQ. New messages go to TxEventQ, and dequeue requests go to AQ until it is drained of messages at which point dequeue requests switch to TxEventQ. Migration status can be monitored and any errors addressed or rolled back.

4. Once the AQ is drained or purged, the DBMS_AQMIGTOOL.COMMIT_MIGRATION procedure drops the AQ and renames the interim TxEventQ to the AQ's name, ensuring application compatibility.
   1. If using DBMS_AQMIGTOOL.AUTOMATIC migration mode, commit is not required.

In the event of an error the prevents migration from continuing, AQ migration may be cancelled and the in-flight messages restored to the AQ without data loss.

### Checking Compatibility

The [CHECK_MIGRATION_TO_TXEVENTQ](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-6DE10CAB-63DA-49F9-A29B-682050DAEA80) procedure is used to verify an AQ is suitable for migration to TxEventQ and should be run before any migration is attempted. 

The following SQL script creates a migration report for the AQ `my_queue` and prints the count of events in the migration report. If all features are supported, the `migration_report` will be empty.

```sql
declare
  migration_report sys.TxEventQ_MigReport_Array := sys.TxEventQ_MigReport_Array();
begin
  DBMS_AQMIGTOOL.CHECK_MIGRATION_TO_TXEVENTQ('testuser', 'my_queue', migration_report);
  dbms_output.put_line('Migration report unsupported events count: ' || migration_report.COUNT);
end;
/
```

If the output is similar to "Migration report unsupported events count: 0", then it is safe to initiate the migration. 

### Initiating Migration

The [INIT_MIGRATION](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-4D2A3314-9ADF-43DE-9201-74A8F9DB03FE) procedure is used to begin AQ migration to TxEventQ. The `mig_mode` parameter is used to control the migration type and defaults to `DBMS_AQMIGTOOL.INTERACTIVE` which allows both enqueue and dequeue during migration. A full description of `mig_mode` options is available in the procedure documentation.

The following SQL script starts migration for the AQ `my_queue` in the `testuser` schema. Once migration starts, an interim TxEventQ will be created named `my_queue_m` the includes a copy of the existing AQ configuration.

```sql
begin
  DBMS_AQMIGTOOL.INIT_MIGRATION(
    cqschema => 'testuser',
    cqname   => 'my_queue'
  );
end;
/
```

`INIT_MIGRATION` is non-blocking may be executed concurrently on multiple queues. If `DBMS_AQMIGTOOL.INTERACTIVE` is used as the migration mode, messages may be enqueued and dequeued during migration.

### Checking Migration Status

While migration is occurring, dequeue will pull from the AQ until it is empty, at which point it will switch to the TxEventQ.

The following SQL statement uses the [CHECK_MIGRATED_MESSAGES](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-FECA1B81-8C0E-4ACA-B878-EFD558B33843) procedure to print the count of remaining `READY` state messages in the AQ and the count messages migrated to TxEventQ. Once the `aq_msg_cnt` reaches zero, the AQ has been fully drained and the migration can be committed. If we attempt to commit the migration before the AQ is drained of `READY` state messages, an exception will be raised.

```sql
declare
  migrated_q_msg_cnt number := 0;
  aq_msg_cnt         number := 0;
begin
  DBMS_AQMIGTOOL.CHECK_MIGRATED_MESSAGES(
    cqschema                  => 'testuser',
    cqname                    => 'my_queue',
    txeventq_migrated_message => migrated_q_msg_cnt,
    cq_pending_messages       => aq_msg_cnt
  );
  dbms_output.put_line('AQ ready state message count: ' || aq_msg_cnt);
  dbms_output.put_line('Migrated TxEventQ message count: ' || migrated_q_msg_cnt);
end;
/
```

The [USER_TXEVENTQ_MIGRATION_STATUS](https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/USER_TXEVENTQ_MIGRATION_STATUS.html#REFRN-GUID-07BAF678-A893-4616-B559-E78E90EE1972) view is used to check the status of in-process migrations for all queues owned by the current user. Queue information, migration status, and error events are available in this view. 

### Commit the Migration

Once the count of `READY` state messages in the AQ reach zero, the [COMMIT_MIGRATION](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-6E7611A4-0702-4090-B8F8-BA5BDA3E1144) procedure is used to finalize the migration operation.

The following SQL script commits the migration for the `my_queue` queue in the `testuser` schema. Once the migration is committed, `my_queue` becomes a TxEventQ.

```sql
begin
  DBMS_AQMIGTOOL.COMMIT_MIGRATION(
    cqschema => 'testuser',
    cqname   => 'my_queue'
  );
end;
/
```

If you wish to purge all messages from the AQ rather than dequeuing them, the [PURGE_QUEUE_MESSAGES](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-DFE7E6F6-0143-4998-A970-3A90800AFCB0) procedure can be used to empty the queue.

The following SQL script purges messages from the `my_queue` queue in the `testuser` schema, allowing migration commit without dequeuing the AQ.

```sql
begin
    DBMS_AQMIGTOOL.PURGE_QUEUE_MESSAGES(
        cqschema => 'testuser',
        cqname   => 'my_queue'
    );
end;
```

### Checking and Handling Migration Errors

If you encounter an error during AQ migration or are using an AQ feature that is unsupported in TxEventQ, the [CHECK_STATUS](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-F6318675-B7B7-4F2A-B0D1-2DC287C6A0EA) procedure can be used to query the current migration status and report any errors.

The following SQL script checks the migration status of the `my_queue` queue. In the event of migration incompatibilities, application changes may be required before continuing migration.

```sql
declare
    mig_STATUS    VARCHAR2(128);
    mig_comments  VARCHAR2(1024);
begin
    DBMS_AQMIGTOOL.CHECK_STATUS(
        cqschema                 => 'testuser',
        cqname                   => 'my_queue',
        status                   => mig_STATUS,
        migration_comment        => mig_comments
    );
    dbms_output.put_line('Migration Status: ' || mig_STATUS);
    dbms_output.put_line('Migration comments: ' || mig_comments);
end;
/
```

Example of an error output due to unsupported TxEventQ enqueue operations:

```
Migration Status: Compatibility Error: Transformation in Enq Unsupported Feature
Migration comments: Unsupported parameter in Enqueue
```

### Cancelling and Recovering Migration

The [CANCEL_MIGRATION](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-A3C934C4-7827-407B-ABE2-F3842D3A6267) procedure is used to cancel an in-progress migration. Use `DBMS_AQMIGTOOL.RESTORE` as the cancellation mode (default) to preserve messages during cancellation.

The following SQL script cancels migration for the AQ `my_queue` in the `testuser` schema:

```sql
begin
    DBMS_AQMIGTOOL.CANCEL_MIGRATION(
        cqschema => 'testuser', 
        cqname => 'my_queue', 
        cancelmode => DBMS_AQMIGTOOL.RESTORE
    );
end;
/
```

The [RECOVER_MIGRATION](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html#GUID-755EEB52-BFAE-4FEA-A933-07546D72DD98) procedure can be used to restore a migration to the nearest safe point, either before or after the execution of DBMS_AQMIGTOOL.CANCEL_MIGRATION, DBMS_AQMIGTOOL.COMMIT_MIGRATION, or DBMS_AQMIGTOOL.INIT_MIGRATION.

The following SQL script recovers migration to the nearest safe point, and outputs the recovery message:

```sql
declare
    recovery_message  VARCHAR2(1024);
begin
    DBMS_AQMIGTOOL.RECOVER_MIGRATION(
        cqschema          => 'testuser',
        cqname            => 'my_queue',
        recovery_message  => recovery_message
    );
    dbms_output.put_line('Recovery message: ' || recovery_message);
end;
/
```

## Limitations and Workarounds

The following features are unsupported in TxEventQ, and should be mitigated before migration:

- Queue Retry Delay: Set `retry_delay` to zero using DBMS_AQADM.ALTER_QUEUE.
- Message transactions on enqueue/dequeue: Move the transformation to the application layer.
- Multi-queue listeners: Implement single queue listening with dequeue browse.
- Priority values outside the range 0-9: Adjust priority values to the range 0-9.

The following features do support migration. Applications using these features must be modified before migration:

- Message grouping.
- Sequence deviation and relative message id.
- Message recipient lists.
