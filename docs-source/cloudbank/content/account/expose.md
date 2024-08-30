+++
archetype = "page"
title = "Expose using APISIX"
weight = 10
+++

Now that the account service is deployed, you need to expose it through the API Gateway so that clients will be able to access it.  This is done by creating a "route" in APISIX Dashboard.

1. Retrieve the admin password for the APISIX API Gateway.

    Execute the following command to get the password for the `admin` user for the APISIX API Gateway:

    ```shell
    $ kubectl get secret -n apisix apisix-dashboard -o jsonpath='{.data.conf\.yaml}' | base64 -d | grep 'password:'
    ```

1. Access the APISIX Dashboard

    The APISIX Dashboard isn't exposed outside the cluster. You need to start a tunnel to be able to access APISIX Dashboard. Start the tunnel using this command in a new terminal window:

    ```shell
    $ kubectl -n apisix port-forward svc/apisix-dashboard 8090:80
    ```

    Open a web browser to [APISIX Dashboard](http://localhost:8090) to view the APISIX Dashboard web user interface.  It will appear similar to the image below.

    If prompted to login, login with username `admin` and the password you retrieved earlier. Note that Oracle strongly recommends that you change the password, even though this interface is not accessible outside the cluster without a tunnel.

    Open the **routes** page from the left hand side menu.  You will not have any routes yet.

   ![APISIX Dashboard route list](../images/obaas-apisix-route-list.png " ")

1. Create the route

    Click on the **Create** button to start creating a route.  The **Create route** page will appear. Enter `account` in the **Name** field:

    ![APISIX Create route](../images/obaas-apisix-create-route-1.png " ")

    Scroll down to the **Request Basic Define** section.  Set the **Path** to `/api/v1/account*`.  This tells APISIX API Gateway that any incoming request for that URL path (on any host or just IP address) should use this route.  In the **HTTP Method** select `GET`, `POST`, `DELETE`, and `OPTIONS`.  The first three you will recall using directly in the implementation of the account service during this lab.  User interfaces and other clients will often send an `OPTIONS` request before a "real" request to see if the service exists and check headers and so on, so it is a good practice to allow `OPTIONS` as well.

    ![APISIX Create route](../images/obaas-apisix-create-route-2.png " ")

    Click on the **Next** button to move to the **Define API Backend Server** page.  On this page you configure where to route requests to. In the **Upstream Type** field, select **Service Discovery**.  Then in the **Discovery Type** field, select **Eureka**.  In the **Service Name** field enter `ACCOUNT`.  This tells APISIX to lookup the service in Spring Eureka Service Registry with the key `ACCOUNT` and route requests to that service using a Round Robin algorithm to distribute requests.

    ![APISIX Create route](../images/obaas-apisix-create-route-3.png " ")

    Click on **Next** to go to the **Plugin Config** page.  You will not add any plugins right now.  You may wish to browse through the list of available plugins on this page.  When you are ready, click on **Next** to go to the **Preview** page.  Check the details and then click on **Submit** to create the route.

    When you return to the route list page, you will see your new `account` route in the list now.

   ![APISIX Route Created](../images/obaas-apisix-route-created.png " ")

1. Verify the account service

    In the next two commands, you need to provide the correct IP address for the API Gateway in your backend environment.  You can find the IP address using this command, you need the one listed in the **`EXTERNAL-IP`** column:

    ```shell
    $ kubectl -n ingress-nginx get service ingress-nginx-controller
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
    ```

    Test the create account endpoint with this command, use the IP address (**EXTERNAL-IP** in the table above) for your API Gateway:

    ```shell
    $ curl -i -X POST \
      -H 'Content-Type: application/json' \
      -d '{"accountName": "Sanjay''s Savings", "accountType": "SA", "accountCustomerId": "bkzLp8cozi", "accountOtherDetails": "Savings Account"}' \
      http://<EXTERNAL-IP>/api/v1/account
    HTTP/1.1 201
    Date: Wed, 01 Mar 2023 18:35:31 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"accountId":24,"accountName":"Sanjays Savings","accountType":"SA","accountCustomerId":"bkzLp8cozi","accountOpenedDate":null,"accountOtherDetails":"Savings Account","accountBalance":0}
    ```

    Test the get account endpoint with this command, use the IP address for your API Gateway and the `accountId` that was returned in the previous command:

    ```shell
    $ curl -s http://<EXTERNAL-IP>/api/v1/account/24 | jq .
    {
      "accountId": 24,
      "accountName": "Sanjay's Savings",
      "accountType": "SA",
      "accountCustomerId": "bkzLp8cozi",
      "accountOpenedDate": null,
      "accountOtherDetails": "Savings Account",
      "accountBalance": 1040
    }
    ```

    Your service is deployed in the Oracle Backend for Spring Boot and Microservices environment and using the Oracle Autonomous Database instance associated with the backend.

