+++
archetype = "chapter"
title = "Migrating From AQ"
weight = 5
+++

Oracle Database 23ai includes a migration path from Advanced Queuing (AQ) to Transactional Event Queues (TxEventQ), to take advantage of enhanced performance and scalability for event-driven architectures.

The [DBMS_AQMIGTOOL](https://docs.oracle.com/en/database/oracle/oracle-database/23/arpls/DBMS_AQMIGTOOL.html) package facilitates a smooth migration process, designed to be non-disruptive and allowing the parallel operation of AQ and TxEventQ during the transition, enabling a smooth cut-over with minimal downtime for your applications.

The migration from AQ to TxEventQ is suitable for various scenarios:

- Scaling up existing AQ-based applications
- Modernizing legacy messaging systems
- Improving performance for high-volume event processing
