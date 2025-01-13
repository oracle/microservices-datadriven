+++
archetype = "chapter"
title = "Performance and Observability"
weight = 4
+++

Oracle TxEventQ offers powerful performance tuning and monitoring capabilities. This module explores advanced techniques for optimizing queue performance and enhancing observability.

## TxEventQ Administrative Views

TxEventQ provides [administrative views](https://docs.oracle.com/en/database/oracle/oracle-database/23/adque/aq-messaging-gateway-views.html#GUID-B86548B9-55B7-4CCE-8B85-FE902B948BE5) for monitoring performance, including insights into message cache statistics, partition level metrics, and subscriber load. This module will dive into accessing and understanding these database views and their content.

## Oracle Database Metrics Exporter

[The Oracle Database Metrics Exporter](https://github.com/oracle/oracle-db-appdev-monitoring) can be configured to export metrics about TxEventQ, providing access to the real-time broker, producer, and consumer metrics in a Grafana dashboard that allows teams to receive alerts for issues and understand the state of their system.

## Performance Tuning

This module will cover several methods of optimizing TxEventQ performance, including the message cache, Streams pool size, and more.

By leveraging these techniques, you can ensure optimal performance and visibility for your TxEventQ implementations.
