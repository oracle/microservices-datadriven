+++
archetype = "page"
title = "Explore SigNoz"
weight = 8
+++

SigNoz provides an easy way to access the logs, traces and metrics collected in the backend and to view them in dashboards.  It can be used to monitor performance, as well as to identify and analyze problems and to create alerts.

1. Explore the pre-installed Spring Boot Dashboard

    Get the admin email and password for SigNoz using this command (your output could be different):

    ```shell
    $ kubectl -n observability get secret signoz-authn -o jsonpath='{.data.email}' | base64 -d
    admin@nodomain.com
    $ kubectl -n observability get secret signoz-authn -o jsonpath='{.data.password}' | base64 -d
    3INgb%T63KM$HN
    ```

   Start the tunnel using this command.  You can run this in the background if you prefer.

    ```shell
    $ kubectl -n observability port-forward svc/obaas-signoz-frontend 3301:3301
    ```

   Open a web browser to [http://localhost:3301/login](http://localhost:3301/login) to view the SigNoz web user interface.  It will appear similar to the image below.  Log in with the admin email and the password you just got.

   ![SigNoz Sign-in](../images/obaas-signoz-signin.png " ")

   After signing in you will get to the SigNoz homepage.

   ![picture](../images/obaas-signoz-home-page.png " ")ma

   On the left, click on Dashboards to set the list of pre-installed dashboards.

   ![SigNoz Dashboards](../images/obaas-signoz-dashboards.png " ")

    click on the link to **Spring Boot 3.x Statistics** to see Spring Boot information.

   The Spring Boot Dashboard looks like the image below.  Use the **app_name** selector at the top to choose which microservice you wish to view information for.

   ![picture](../images/obaas-signoz-spring-dashboard.png " ")

   Feel free to explore the other dashboards that are preinstalled.

