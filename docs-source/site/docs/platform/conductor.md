---
title: MicroTx Workflow Orchestration
sidebar_position: 4
---

MicroTx Workflow is a workflow orchestration platform, based on Orkes Conductor, which was originally developed at Netflix.  It is designed to coordinate long-running, distributed workflows across microservices by defining tasks, dependencies, and retries, while providing scalability, fault tolerance, and operational visibility through a centralized engine.

For reference: [Conductor OSS Documentation](https://docs.conductor-oss.org)

## Installing MicroTx Workflow

MicroTx Workflow will be installed if `otmm.enabled` and `otmm.workflowServer.enabled` are set to `true` in the `values.yaml` file.  The web user interface will be installed if `otmm.console.enabled` is set to `true`.  Note that the web user interface is optional, you may choose to install just the workflow engine if you wish.

