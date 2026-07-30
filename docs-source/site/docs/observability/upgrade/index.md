---
title: Upgrade SigNoZ
sidebar_position: 9
---

# Upgrade SigNoZ

SigNoZ recommends backing up configuration and persistent data before an
upgrade. Its ClickHouse upgrade guidance explains that ClickHouse updates its
on-disk format in place and that downgrades are not guaranteed. See the official
[SigNoZ ClickHouse 25.12.5 upgrade guide](https://signoz.io/docs/operate/migration/upgrade-0-131/)
and [standard upgrade guide](https://signoz.io/docs/operate/migration/upgrade-standard/).

OBaaS provides separate upgrade paths so that each procedure can be followed
from beginning to end without branching.

## When to use these guides

Use these guides when upgrading an existing OBaaS installation that has SigNoZ
enabled. Fresh installations do not use an upgrade path; install the current
OBaaS chart normally.

## Choose an upgrade path

| Existing environment | Recovery requirement | Guide |
|---|---|---|
| OBaaS 2.0.0 or 2.1.x with a SigNoZ version earlier than `0.134.0` | Historical telemetry, dashboards, and users must be recoverable | [Upgrade with protected recovery](./protected-recovery.md) **(recommended)** |
| Any supported SigNoZ version earlier than `0.134.0` | Historical data does not require a protected recovery point | [Upgrade without protected recovery](./without-protected-recovery.md) |

If you are unsure which path applies, use the protected recovery guide.

## Common requirements

Before selecting a guide:

1. Confirm the Kubernetes context, Helm release name, and application namespace.
1. Confirm that SigNoZ, ClickHouse, and ZooKeeper are healthy.
1. Retain the customer values files and all database, secret, image, storage,
   and private-registry settings used by the existing release.
1. Do not use an older ClickHouse version against a persistent volume whose
   on-disk format has already been upgraded.
