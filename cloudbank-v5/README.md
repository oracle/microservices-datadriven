# CloudBank Version 5 - 9/17/25

**NOTE:** This document and application is WIP.

To run Cloud Bank you need OBaaS version 2.0.0 [Oracle Backend for Microservices and AI](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/138899911) and Java 21 installed.

1. Create or obtain Image Repo details
2. Clone the repo from here http://
3. Got to the cloudbank-v5 directory
4. Build depndencies and install  -- `mvn clean install -pl common,buildtools`
5. Build and push  -- `mvn clean package k8s:build k8s:push -pl account,customer,transfer,checks,creditscore,chatbot,testrunner`
6. Edit the sqljob.yaml file, change the metadata.namespace to reflect your OBaaS installation (namespace, username, passwords for example)
7. Create DB secrets for account and customer (account-db-secret and customer-sb-secret)
8. For each application modify the pom.xml
  a. Account (image name to use the image repository from step 1)
  b. Checks (image name to use the image repository from step 1)
  c. Customer (image name to use the image repository from step 1)
  d. Creditscore (image name to use the image repository from step 1)
  e. Testrunner (image name to use the image repository from step 1)
  f. Transfer (image name to use the image repository from step 1)
9. For each application modify the chart.yaml
  a. Account (name: account)
  b. Checks (name: checks)
  c. Customer (name: customer)
  d. Creditscore (name: creditscore)
  e. Testrunner (name: testrunner)
  f. Transfer (name: transfer)
10. For each application modify the values.yaml
  a. Account (database credentials account, all services enabled)
  b. Checks (database credentuals account, all service enabled)
  c. Customer (database credentials customer, all services enabled)
  d. Creditscore (no db credentials, no mp_lra)
  e. Testrunner (db creds account, all servcies enabled)
  f. Transfer (no db creds, all services enabled)
11. For each application apply the helm chart.
12. For each application create APISIX
13. Test each application using curl

TBD below -----

## Create APISIX Routes

1. Get APISIX Gateway Admin Key

    ```shell
    kubectl -n apisix get configmap apisix -o yaml
    ```

1. Create tunnel to APISIX

    ```shell
    kubectl port-forward -n apisix svc/apisix-admin 9180
    ```

1. Create routes

    In the CloudBank directory run the following command. *NOTE*, you must add the API-KEY to the command

    ```shell
    (cd apisix-routes; source ./create-all-routes.sh <YOUR-API-KEY>)
    ```

## Optional - autoscaling

Create autoscalers for CloudBank.

```text
oractl:>script --file deploy-cmds/autoscale-cmd.txt
```

The following commands are executed:

```script
create-autoscaler --service-name account --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80 
create-autoscaler --service-name checks --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80
create-autoscaler --service-name customer --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80
create-autoscaler --service-name creditscore --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80
create-autoscaler --service-name testrunner --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80
create-autoscaler --service-name transfer --min-replicas 1 --max-replicas 4 --cpu-request 100m --cpu-percent 80
```

## OpenAPI

All services have OpenAPI documentation and can be reached via the Swagger UI. For example after starting a port forward to anyone of the services you can the URL ![OPenAPI](http://localhost:*port*/)swagger-ui/index.html to see the documentation. Replace *port* with the port used in the port forward command. For example, to see the API documentation for the `customer32` application do the following:

```shell
kubectl port-forward -n application svc/customer32 8080
```

And open a browser window and go to [Swagger UI](http://localhost:8080)

This is an example of the `customer32` application:

![Swagger UI](images/swagger-example.png  " ")

## Test CloudBank Services

1. Get the external IP address

    ```shell
    kubectl -n ingress-nginx get service ingress-nginx-controller
    ```

    Result. Create a variable called IP with the value of the **EXTERNAL-IP** it will be used in the tests.

    ```text
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.96.172.148   146.235.207.230   80:31393/TCP,443:30506/TCP   158m
    ```

1. Test `account` service

   1. Rest endpoint

      ```shell
      curl -s http://$IP/api/v1/accounts | jq
      ```

      Should return:

      ```json
      [
        {
          "accountBalance": -20,
          "accountCustomerId": "qwertysdwr",
          "accountId": 1,
          "accountName": "Andy's checking",
          "accountOpenedDate": "2023-06-26T17:39:37.000+00:00",
          "accountOtherDetails": "Account Info",
          "accountType": "CH"
        },
        {...}
      ]
      ```

1. Test `customer` service

   1. GET REST endpoint.

      ```shell
      curl -s http://$IP/api/v1/customer | jq
      ```

      Should return:

      ```json
      [
        {
          "customerEmail": "andy@andy.com",
          "customerId": "qwertysdwr",
          "customerName": "Andy",
          "customerOtherDetails": "Somekind of Info",
          "customerPassword": "SuperSecret",
          "dateBecameCustomer": "2023-11-02T17:30:12.000+00:00"
        },
        {...}
      ]
      ```

   1. POST endpoint to create a customer.

      ```shell
      curl -i -X POST -H 'Content-Type: application/json' -d '{"customerId": "bobsmith", "customerName": "Bob Smith", "customerEmail": "bob@smith.com"}' http://$IP/api/v1/customer
      ```

      Should return the URI of the created object:

      ```text
      HTTP/1.1 201
      Location: http://localhost:8080/api/v1/customer/bobsmith
      Content-Length: 0
      Date: Tue, 03 Sep 2024 21:01:25 GMT
      ```

1. Test `creditscore` service

    1. REST endpoint

       ```shell
       curl -s http://$IP/api/v1/creditscore | jq
       ```

       Should return:

       ```json
       {
         "Date": "2023-12-26",
         "Credit Score": "574"
       }
       ```

1. Test `check` service

    1. REST endpoint - deposit check. *NOTE*: Make sure you use an existing account number

       ```shell
       curl -i -X POST -H 'Content-Type: application/json' -d '{"accountId": 1, "amount": 256}' http://$IP/api/v1/testrunner/deposit
       ```

       Should return:

       ```text
       HTTP/1.1 201
       Content-Type: application/json
       Transfer-Encoding: chunked
       Date: Thu, 02 Nov 2023 18:02:06 GMT

       {"accountId":1,"amount":256}
       ```

    1. Check application log

         ```shell
         kubectl logs -n application svc/checks
         ```

         Should contain:

         ```log
         Received deposit <CheckDeposit(accountId=1, amount=256)>
         ```

    1. Check journal entries. Replace '1' with the account number you used.

        ```shell
        curl -i http://$IP/api/v1/account/1/journal
        ```

        output should be similar to:

        ```log
        HTTP/1.1 200 
        Content-Type: application/json
        Transfer-Encoding: chunked
        Date: Thu, 02 Nov 2023 18:06:45 GMT

        [{"journalId":1,"journalType":"PENDING","accountId":1,"lraId":"0","lraState":null,"journalAmount":256}]
        ```

    1. Clearance of check - Note the JournalID from earlier step

         ```shell
         curl -i -X POST -H 'Content-Type: application/json' -d '{"journalId": 1}' http://$IP/api/v1/testrunner/clear
         ```

        output should be similar to:

        ```text
         HTTP/1.1 201 
         Content-Type: application/json
         Transfer-Encoding: chunked
         Date: Thu, 02 Nov 2023 18:09:17 GMT

         {"journalId":1}
         ```

    1. Check application log

       ```shell
       kubectl logs -n application svc/checks
       ```

       Output should be similar to:

       ```log
       ...
       Received clearance <Clearance(journalId=1)>
       ...
       ```

    1. Check journal -- DEPOSIT. Replace '1' with the account number you used.

       ```shell
       curl -i http://$IP/api/v1/account/1/journal
       ```

       Output should look like this -- DEPOSIT

       ```text
       HTTP/1.1 200
       Content-Type: application/json
       Transfer-Encoding: chunked
       Date: Thu, 02 Nov 2023 18:36:31 GMT

       [{"journalId":1,"journalType":"DEPOSIT","accountId":1,"lraId":"0","lraState":null,"journalAmount":256}]`
       ```

1. Run LRA Test Cases

    1. Check account balances. Note that the account numbers 1 and 2 can be different in your environment

       ```shell
       curl -s http://$IP/api/v1/account/1 | jq ; curl -s http://$IP/api/v1/account/2 | jq 
       ```

       Output should be similar to this, make a note of the account balance:

       ```json
       {
         "accountId": 1,
         "accountName": "Andy's checking",
         "accountType": "CH",
         "accountCustomerId": "qwertysdwr",
         "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
         "accountOtherDetails": "Account Info",
         "accountBalance": -20
       },
       {
         "accountId": 2,
         "accountName": "Mark's CCard",
         "accountType": "CC",
         "accountCustomerId": "bkzLp8cozi",
         "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
         "accountOtherDetails": "Mastercard account",
         "accountBalance": 1000
       }
       ```

    1. Perform transfer between two accounts. Note account numbers

       ```shell
       curl -X POST "http://$IP/transfer?fromAccount=2&toAccount=1&amount=100"
       ```

       Output should look like this:

       ```text
       transfer status:withdraw succeeded deposit succeeded
       ```

    1. Check accounts to see that the transfer have occurred

       ```shell
       curl -s http://$IP/api/v1/account/1 | jq ; curl -s http://$IP/api/v1/account/2 | jq 
       ```

       Output should be similar to this:

       ```json
       {
         "accountId": 1,
         "accountName": "Andy's checking",
         "accountType": "CH",
         "accountCustomerId": "qwertysdwr",
         "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
         "accountOtherDetails": "Account Info",
         "accountBalance": 80
       },
       {
         "accountId": 2,
         "accountName": "Mark's CCard",
         "accountType": "CC",
         "accountCustomerId": "bkzLp8cozi",
         "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
         "accountOtherDetails": "Mastercard account",
         "accountBalance": 900
       }
       ```

    1. Check the application log to confirm

       ```shell
       kubectl logs -n application svc/transfer
       ```

       Output should look similar to this:

       ```text
       2023-12-26T16:50:45.138Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : Started new LRA/transfer Id: http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
       2023-12-26T16:50:45.139Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw accountId = 2, amount = 100
       2023-12-26T16:50:45.139Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw lraId = http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
       2023-12-26T16:50:45.183Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw succeeded
       2023-12-26T16:50:45.183Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : deposit accountId = 1, amount = 100
       2023-12-26T16:50:45.183Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : deposit lraId = http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
       2023-12-26T16:50:45.216Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw succeeded deposit succeeded
       2023-12-26T16:50:45.216Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : LRA/transfer action will be confirm
       2023-12-26T16:50:45.226Z  INFO 1 --- [transfer] [nio-8080-exec-1] [] com.example.transfer.TransferService     : Received confirm for transfer : http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
       2023-12-26T16:50:45.233Z  INFO 1 --- [transfer] [io-8080-exec-10] [] com.example.transfer.TransferService     : Process confirm for transfer : http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
       ```

## Observability and Tracing

1. Check the ServiceOPS Center

   1. Get the external IP

      ```shell
      kubectl -n ingress-nginx get service ingress-nginx-controller
      ```

   1. Get the *obaas-admin* user password

      ```shell
      kubectl get secret  -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
      ```

   1. Login into [ServiceOPS Dashboard](https://EXTERNAL-IP/soc)

      ![ServiceOPS Login](images/serviceops_login.png  " ")

   1. Explore the dashboard

      ![ServiceOPS Dashboard](images/serviceops_dashboard.png  " ")

1. Check Eureka dashboard

   1. Port forward

      ```shell
      kubectl -n eureka port-forward svc/eureka 8761
      ```

   1. Open [Eureka Dashboard](http://localhost:8761) in a browser and verify that all services are registered

      ![Eureka Dashboard](images/eureka.png  " ")

1. Check Admin Server dashboard

   1. Port forward

      ```shell
      kubectl port-forward -n admin-server svc/admin-server 8989
      ```

   1. Open [Admin Server Dashboard](http://localhost:8989) in a browser and verify that all services are registered

      ![Admin Server Dashboard](images/admin_server.png  " ")

2. Check the SigNoz Dashboard

   1. Get the *admin* email and password for SigNoz

      ```shell
      kubectl -n observability get secret signoz-authn -o jsonpath='{.data.email}' | base64 -d
      kubectl -n observability get secret signoz-authn -o jsonpath='{.data.password}' | base64 -d
      ```

   1. Port forward

      ```shell
      kubectl -n observability port-forward svc/obaas-signoz-frontend 3301:3301
      ```

   2. Open [SigNoz Login](http://localhost:3301/login) in a browser and login with the *admin* email and the password you have retrieved.

      ![SigNoz Login](images/signoz_login.png  " ")

   3. Explore the pre-installed dashboards.

      ![SigNoz](images/signoz-dashboard.png  " ")

   4. Explore the traces view. Choose `customer` Service to view traces related to Customer microservice.

      ![Trace Explorer](images/traces.png  " ")
      
      Click any of the traces to expand its details.

      ![Customer](images/traces-expand.png  " ")
   5. Explore the logs view. Choose `customer` Service to view logs related to Customer microservice.

      ![Logs Explorer](images/logs.png  " ")
      
      Click any of the log lines to expand its details.

      ![Customer](images/logs-expand.png  " ")