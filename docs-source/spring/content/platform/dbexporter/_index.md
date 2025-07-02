---
title: "Unified Observability for Oracle Database"
description: "Observability for the Oracle Database"
keywords: "observability performance metrics oracle database"
---

This project aims to provide observability for the Oracle Database so that users can understand performance and diagnose issues easily across applications and database. Over time, this project will provide not just metrics, but also logging and tracing support, and integration into popular frameworks like Spring Boot. The project aims to deliver functionality to support both cloud and on-premises databases, including those running in Kubernetes and containers.

## Main Features

The main features of the exporter are:

- Exports Oracle Database metrics in de facto standard Prometheus format
- Works with many types of Oracle Database deployment including single instance and Oracle Autonomous Database
- Supports wallet-based authentication
- Supports both OCI and Azure Vault integration (for database username, password)
- Multiple database support allows a single instance of the exporter to connect to, and export metrics from, - multiple databases
- Can export the Alert Log in JSON format for easy ingest by log aggregators
- Can run as a local binary, in a container, or in Kubernetes
- Pre-buit AMD64 and ARM64 images provided
- A set of standard metrics included "out of the box"
- Easily define custom metrics
- Define the scrape interval, down to a per-metric level
- Define the query timeout
- Control connection pool settings, can use with go-sql or Oracle Database connection pools, also works with Database Resident Connection Pools
- Sample dashboard provided for Grafana

Full documentation is [here](https://github.com/oracle/oracle-db-appdev-monitoring).

### Oracle Database Dashboard:

![Oracle Database Dashboard](images/exporter-running-against-basedb.png)

### Transactional Event Queue Dashboard:

![Oracle Database Dashboard](images/txeventq-dashboard-v2.png)