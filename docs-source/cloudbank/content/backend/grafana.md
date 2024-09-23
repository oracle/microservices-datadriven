+++
archetype = "page"
title = "Explore Grafana"
weight = 8
+++

Grafana provides an easy way to access the metrics collected in the backend and to view them in dashboards.  It can be used to monitor performance, as well as to identify and analyze problems and to create alerts.

1. Explore the pre-installed Spring Boot Dashboard

    Get the password for the Grafana admin user using this command (your output will be different):

    ```shell
    $ kubectl -n grafana get secret grafana -o jsonpath='{.data.admin-password}' | base64 -d
    fusHDM7xdwJXyUM2bLmydmN1V6b3IyPVRUxDtqu7
    ```

   Start the tunnel using this command.  You can run this in the background if you prefer.

    ```shell
    $ kubectl -n grafana port-forward svc/grafana 8080:80
    ```

   Open a web browser to [http://localhost:8080/grafana/](http://localhost:8080/grafana/) to view the Grafana web user interface.  It will appear similar to the image below.  Log in with the username **admin** and the password you just got.

   ![Grafana Sign-in](../images/obaas-grafana-signin.png " ")

   After signing in you will get to the Grafana homepage.

   ![picture](../images/obaas-grafana-home-page.png " ")

   On the left, click on Dashboards to set the list of pre-installed dashboards.

   ![Grafana Dashboards](../images/obaas-grafana-dashboards.png " ")

    click on the link to **Spring Boot 3.x Statistics** to see Spring Boot information.

   The Spring Boot Dashboard looks like the image below.  Use the **Instance** selector at the top to choose which microservice you wish to view information for.

   ![picture](../images/obaas-grafana-spring-dashboard.png " ")

   Feel free to explore the other dashboards that are preinstalled.

