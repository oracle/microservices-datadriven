---
title: "Workflow"
resources:
- name: conductor_ui_workflows
  src: "conductor_ui_workflows.png"
  title: "Conductor UI Workflows"
---

Oracle Backend as a Service for Spring Cloud includes Netflix Conductor Server. Conductor is a popular workflow solution that works well with Spring Boot microservices and the Oracle database.

Full documentation on Conductor can be found here:

* [Netflix Conductor Documentation](https://conductor.netflix.com/)

### Accessing Server UI

1. Expose the Oracle Spring Cloud Admin Server that the CLI will call by using `port-forward`

    ```shell
    kubectl port-forward services/conductor-server -n conductor-server 8080:8080
    ```

2. Access the Conductor Server UI.

    ```shell
    http://localhost:8080
    ```

<!-- spellchecker-disable -->
{{< img name="conductor_server_ui" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

3. Access the Swagger Documentation

    ```shell
    http://localhost:8080/swagger-ui/index.html
    ```

<!-- spellchecker-disable -->
{{< img name="conductor_server_swagger" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

### API Specification

The API Specification can be found here:

* [API Specification](https://conductor.netflix.com/apispec.html)
