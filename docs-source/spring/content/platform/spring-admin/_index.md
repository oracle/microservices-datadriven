---
title: "Spring Boot Admin"
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

## View Application Details Using the Spring Boot Admin Dashboard

Spring Boot Admin is a web application used for managing and monitoring Spring Boot applications. Applications are discovered from the
service registry. Most of the information displayed in the web user interface comes from the Spring Boot Actuator endpoints exposed by
the applications:

1. Expose the Spring Boot Admin dashboard using this command:

    ```shell
    kubectl -n admin-server port-forward svc/admin-server 8989:8989
    ```

2. Open the Spring Boot Admin dashboard URL: <http://localhost:8989>

    * username: `admin`
    * password: `admin`

    **NOTE:** Oracle recommends that you change the default password when you log in for the first time. Even though the dashboard is not
	accessible externally, Oracle still recommends using strong passwords to maximize security.

    <!-- spellchecker-disable -->
    {{< img name="obaas-springadmin-apps" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. On the web page, navigate to the **Applications** tab:

    * If you deployed the [Sample Applications](../../sample-apps), find and click the **SLOW** entry to expand it.
    * Click on the instance of the service.
    * Notice that you can see details about the service instance, metrics, configuration, and so on.

    <!-- spellchecker-disable -->
    {{< img name="obaas-springadmin-svc-details" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->


