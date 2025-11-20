---
title: Conductor Workflow Orchestration
sidebar_position: 4
---
## Conductor

:::important
Conductor will be replaced with Oracle Transaction Manager for Microservices, which will include the Conductor Server as a component of the product
:::

Conductor is a workflow orchestration platform, originally developed at Netflix, designed to coordinate long-running, distributed workflows across microservices by defining tasks, dependencies, and retries, while providing scalability, fault tolerance, and operational visibility through a centralized engine.

[Conductor OSS Documentation](https://docs.conductor-oss.org)

### Installing Conductor

Conductor will be installed if the `conductor-server.enabled` is set to `true` in the `values.yaml` file. The default namespace for Conductor is `conductor-server`.

### API Specification

[API Specification](https://docs.conductor-oss.org/documentation/api/index.html)

### Accessing Conductor APIs

:::note Namespace Configuration
All `kubectl` commands in this guide use `-n conductor-server` as the default namespace. If Conductor is installed in a different namespace, replace `conductor-server` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep conductor
```
:::

To access the Conductor APIs, use kubectl port-forward to create a secure channel to `service/conductor-server`. Run the following command to establish the secure tunnel:

```shell
kubectl port-forward -n conductor-server svc/conductor-server 8080
```

### Testing the Conductor service

You can test the Conductor service by running the sample workflow provided. Save the content into a file called `first_simple_workflow.json` and then execute the following command:

```shell
curl -X POST 'http://localhost:8080/api/metadata/workflow' \
-H 'Content-Type: application/json' \
-d @first_sample_workflow.json
```

```json
 
    {
        "name": "first_sample_workflow",
        "description": "First Sample Workflow",
        "version": 1,
        "tasks": [
            {
                "name": "get_population_data",
                "taskReferenceName": "get_population_data",
                "inputParameters": {
                    "http_request": {
                        "uri": "https://restcountries.com/v3.1/name/united%20states?fields=name,population",
                        "method": "GET"
                    }
                },
                "type": "HTTP"
            }
        ],
        "inputParameters": [],
        "outputParameters": {
            "data": "${get_population_data.output.response.body.data}",
            "source": "${get_population_data.output.response.body.source}"
        },
        "schemaVersion": 2,
        "restartable": true,
        "workflowStatusListenerEnabled": false,
        "ownerEmail": "example@email.com",
        "timeoutPolicy": "ALERT_ONLY",
        "timeoutSeconds": 0
    }

```

Execute the workflow by using this command and capture the Workflow ID:

```shell
WORKFLOW_ID=$(curl -s -X POST 'http://localhost:8080/api/workflow/first_sample_workflow' \
-H 'Content-Type: application/json' \
-d '{}' | tr -d '"')
```

Check the Workflow ID; it should return a string similar to this: `46cbbaef-7133-451b-9334-2ccfc4e270c5`

```shell
echo "Workflow ID: $WORKFLOW_ID"
```

Check the status of the workflow. This will return the data from https://restcountries.com/v3.1/name/united%20states?fields=name,population.

```shell
curl -s -X GET "http://localhost:8080/api/workflow/$WORKFLOW_ID" | jq
```

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
