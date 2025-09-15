---
title: Introduction and Installation Flow
sidebar_position: 1
---
## Introduction and Installation flow

:::important
This content is TBD
:::

This guide explains how to deploy an application to OBaaS using Eclipse [Eclipse JKube](https://eclipse.dev/jkube/) to build and push a container image, and Helm to install and configure the application on a Kubernetes cluster.

### Prerequisites

- Access to a container image repository (e.g., OCIR or another approved registry).
- Kubernetes cluster access with the correct context set.
- Helm installed locally.
- Maven build configured for your project.

### High Level Installation Flow

Too deploy an application to OBaaS, you will follow this high-level flow:

- Obtain Image Repository metadata or Create the repository needed for the deployment.
- Add [Eclipse JKube](https://eclipse.dev/jkube/) to the pom.xml file.
- Build the Application using Maven.
- Obtain the deployment Helm chart.
- If you're using a database, create a secret with database credentials etc.
- Create the database application user using the 'sqljob.yaml' file. **Add to Helm dir with 'if' statement**
- Edit the `Chart.yaml` file to reflect the application name.
- Install the Helm chart.
