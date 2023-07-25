---
title: "Spring Admin"
resources:
  - name: obaas-springadmin-apps
    src: "obaas-springadmin-apps.png"
    title: "Spring Admin DashboardI"
  - name: obaas-springadmin-svc-details
    src: "obaas-springadmin-svc-details.png"
    title: "Spring Admin Service Details"
  - name: obaas-eureka-dashboard
    src: "obaas-eureka-dashboard.png"
    title: "Eureka Dashboard"
---

## View application details using the Spring Admin Dashboard

Spring Boot Admin is a web application used for managing and monitoring Spring Boot applications. Applications are discovered from the service registry.
Most of the information displayed in the web user interface comes from the Spring Boot Actuator endpoints exposed by the applications.

1. Exposing Spring Admin Dashboard using `port-forward`

    ```shell
    kubectl -n admin-server port-forward svc/admin-server 8989:8989
    ```

2. Open the Spring Admin Dashboard URL: <http://localhost:8989>

    * username: `admin`
    * password: `admin`

    **Note:** Oracle recommends that you change the default password when you first login.  Even though the dashboard is not accessible externally,
    we still recommend using strong passwords to maximize security.

    <!-- spellchecker-disable -->
    {{< img name="obaas-springadmin-apps" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. On the web page, navigate to the applications tab:

    * If you deployed the [sample apps](../../sample-apps), Find the "slow" entry and click on it to expand it
    * Click on the instance of the service
    * Notice you can see details about the service instance, metrics, configuration, etc.

    <!-- spellchecker-disable -->
    {{< img name="obaas-springadmin-svc-details" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->
