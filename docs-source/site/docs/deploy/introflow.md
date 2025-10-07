---
title: Introduction and Installation Flow
sidebar_position: 1
---
## Introduction and Installation flow

:::important
This content is TBD
:::

This guide explains how to deploy an application to OBaaS using [Eclipse JKube](https://eclipse.dev/jkube/) to build and push a container image, and using Helm to install and configure the application on a Kubernetes cluster.

### Prerequisites

- Access to a container image repository (e.g., OCIR or another approved registry)
- Docker running locally (and authenticated to your registry)
- Kubernetes cluster access with the correct context set
- Helm installed locally
- Maven build configured for your project

### High Level Installation Flow

To deploy an application to OBaaS, follow this high-level workflow:

- Obtain image repository metadata or create the required repository.
- Configure database access and run the SQL job, if needed.
- Add Eclipse JKube to the pom.xml.
- Build and push the application with Maven.
- Retrieve the deployment Helm chart.
- Update Chart.yaml with the application name.
- Update values.yaml to match your configuration.
- Install the Helm chart.
