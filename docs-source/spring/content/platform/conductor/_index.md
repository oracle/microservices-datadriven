---
title: "Workflow"
resources:
- name: conductor_ui_workflows
  src: "conductor_ui_workflows.png"
  title: "Conductor UI Workflows"
---

Oracle Backend as a Service for Spring Cloud includes the Netflix Conductor Server. Conductor is a popular workflow solution that
works with Spring Boot Microservices and Oracle Database.

Documentation on Conductor can be found here:

* [Netflix Conductor Documentation](https://conductor.netflix.com/)

## Accessing the Server User Interface (UI)

1. Expose the Oracle Spring Cloud Admin server that the CLI calls by using this command:

    ```shell
    kubectl port-forward services/conductor-server -n conductor-server 8080:8080
    ```

2. Access the Conductor server UI at this URL:

    ```shell
    http://localhost:8080
    ```

<!-- spellchecker-disable -->
{{< img name="conductor_server_ui" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

3. Access the Swagger documentation at this URL:

    ```shell
    http://localhost:8080/swagger-ui/index.html
    ```

<!-- spellchecker-disable -->
{{< img name="conductor_server_swagger" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

## API Specification

The API Specification can be found here:

* [API Specification](https://conductor.netflix.com/apispec.html)

