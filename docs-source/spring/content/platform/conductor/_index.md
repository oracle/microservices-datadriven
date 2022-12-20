---
title: "Netflix Conductor Workflow"
resources:
- name: conductor_ui_workflows
  src: "conductor_ui_workflows.png"
  title: "Conductor UI Workflows"
- name: conductor_ui_tasks
  src: "conductor_ui_tasks.png"
  title: "Conductor UI Tasks"
---

Oracle Backend as a Service for Spring Cloud includes Netflix Conductor along with the Netflix Conductor UI.
Conductor is a popular workflow solution that works well with Spring Boot microservices and the Oracle database.

Full documentation on Conductor can be found here:

* [Spring Config Server](../../platform/config/)

### Accessing Conductor UI

1. Expose the Oracle Spring Cloud Admin Server that the CLI will call by using `port-forward`

    ```shell
    kubectl port-forward services/conductor-ui -n conductor-ui  5000:5000
    ```

2. Access the Conductor UI.

```shell
http://localhost:5000
```

### Using Conductor UI

The UI can be used to view and exercise workflows.
* [Conductor Workflow Documentation](https://conductor.netflix.com/configuration/workflowdef.html)

<!-- spellchecker-disable -->
{{< img name="conductor_ui_workflows" size="medium" lazy=false >}}
<!-- spellchecker-enable -->


Workflows consist of tasks and Spring Boot microservices can be called as/from tasks in order to participate in these workflows.
* [Conductor Task Documentation](https://conductor.netflix.com/configuration/taskdef.html) 

The UI can also be used to view these tasks.

<!-- spellchecker-disable -->
{{< img name="conductor_ui_tasks" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

### Samples 

"A First Workflow" example can  be found here:
* [running-first-workflow](https://conductor.netflix.com/labs/running-first-workflow.html)
