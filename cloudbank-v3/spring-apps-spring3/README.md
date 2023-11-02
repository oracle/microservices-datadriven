# CloudBank Version 3

This Spring Boot project is used in the [Oracle Backend Platform for Microservices with Oracle Database](https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/view-workshop?wid=3607) Live Lab.

Please visit the Live Lab for more information.

## Build cloudbank

   `mvn clean package`

   ```text
   [INFO] ------------------------------------------------------------------------
   [INFO] Reactor Summary for cloudbank 0.0.1-SNAPSHOT:
   [INFO]
   [INFO] cloudbank .......................................... SUCCESS [  0.948 s]
   [INFO] account ............................................ SUCCESS [  2.837 s]
   [INFO] customer ........................................... SUCCESS [  1.051 s]
   [INFO] creditscore ........................................ SUCCESS [  0.859 s]
   [INFO] transfer ........................................... SUCCESS [  0.760 s]
   [INFO] testrunner ......................................... SUCCESS [  0.947 s]
   [INFO] checks ............................................. SUCCESS [  0.969 s]
   [INFO] ------------------------------------------------------------------------
   [INFO] BUILD SUCCESS
   [INFO] ------------------------------------------------------------------------
   [INFO] Total time:  8.689 s
   [INFO] Finished at: 2023-11-02T11:40:25-05:00
   [INFO] ------------------------------------------------------------------------
   ```

## Deploying Cloudbank

1. Start the tunnel

   ```shell
   kubectl port-forward -n obaas-admin svc/obaas-admin 8080
   ```

1. Get the password for the `obaas-admin` user

   ```shell
   kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
   ```

1. Start `oractl` and Login

   ```text
   oractl
    _   _           __    _    ___
   / \ |_)  _.  _. (_    /  |   |
   \_/ |_) (_| (_| __)   \_ |_ _|_
   =============================================================================================================================
   Application Name: Oracle Backend Platform :: Command Line Interface
   Application Version: (1.0.1)
   :: Spring Boot (v3.1.3) ::


   oractl:>connect
   username: obaas-admin
   password: **************
   obaas-cli: Successful connected.
   oractl:>
   ```

1. Create namespace

    ```shell
    oractl:>create --app-name cbv3
    application/namespace created successfully and image pull secret (registry-auth) created successfully and database TNSAdmin/wallet secret created successfully
    ```

1. Deploy account service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name account
      Database/Service Password: *************
      Schema {account} was successfully created and Kubernetes Secret {cbv3/account} was successfully created.
      ```

   1. deploy

      ```shell
      deploy --app-name cbv3 --service-name account --artifact-path account/target/account-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --liquibase-db admin
      uploading: account/target/account-0.0.1-SNAPSHOT.jar
      building and pushing image...

      creating deployment and service...
      obaas-cli [deploy]: Application was successfully deployed.
      ```

   1. Verify deployment success

      ```shell
      kubectl logs -n cbv3 svc/account
      ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:24:04.883Z  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
      2023-11-02T17:24:04.909Z  INFO 1 --- [           main] c.example.accounts.AccountsApplication   : Started AccountsApplication in 22.621 seconds (process running for 23.78)
      2023-11-02T17:24:33.383Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:24:33.384Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:24:33.386Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 2 ms
      ```

1. Deploy customer service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name customer
      database password/servicePassword (defaults to Welcome12345): *************
      Kubernetes secret for Datasource was created successfully.
      ```

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name customer --artifact-path customer/target/customer-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --liquibase-db admin
      uploading: customer/target/customer-0.0.1-SNAPSHOT.jar
      building and pushing image...
      
      creating deployment and service...
      obaas-cli [deploy]: Application was successfully
      ```

   1. Verify deployment success

         ```shell
         kubectl logs -n cbv3 svc/customer
         ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:30:22.607Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CUSTOMERS/customer-6787db57dc-lbncs:customers - registration status: 204
      2023-11-02T17:30:22.669Z  INFO 1 --- [           main] c.example.customer.CustomerApplication   : Started CustomerApplication in 18.57 seconds (process running for 19.755)
      2023-11-02T17:30:33.631Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:30:33.632Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:30:33.634Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 2 ms
      ```

1. Deploy creditscore service

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name creditscore --artifact-path creditscore/target/creditscore-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: creditscore/target/creditscore-0.0.1-SNAPSHOT.jar
      building and pushing image...

      creating deployment and service...
      obaas-cli [deploy]: Application was successfully deployed.
      ```

   1. Verify deployment success

         ```shell
         kubectl logs -n cbv3 svc/creditscore
         ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:33:14.983Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CREDITSCORE/creditscore-779bbcf848-th8nd:creditscore - registration status: 204
      2023-11-02T17:33:14.999Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
      2023-11-02T17:33:15.000Z  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
      2023-11-02T17:33:15.035Z  INFO 1 --- [           main] c.e.creditscore.CreditscoreApplication   : Started CreditscoreApplication in 6.304 seconds (process running for 7.479)
      2023-11-02T17:33:33.728Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:33:33.729Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:33:33.731Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 2 ms
      ```

1. Deploy testrunner service

   1. bind

         ```shell
         oractl:>bind --app-name cbv3 --service-name testrunner --username account
         Database/Service Password: *************
         Schema {account} was successfully Not_Modified and Kubernetes Secret {cbv3/testrunner} was successfully Created.
         ```

   1. deploy

         ```shell
         oractl:>deploy --app-name cbv3 --service-name testrunner --artifact-path testrunner/target/testrunner-0.0.1-SNAPSHOT.jar --image-version 0.0.1
         uploading: testrunner/target/testrunner-0.0.1-SNAPSHOT.jar
         building and pushing image...
         
         creating deployment and service...
         obaas-cli [deploy]: Application was successfully deployed.
         ```

   1. Verify deployment success

         ```shell
         kubectl logs -n cbv3 svc/testrunner
         ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:36:28.647Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_TESTRUNNER/testrunner-66f8f66d57-bpwwr:testrunner - registration status: 204
      2023-11-02T17:36:28.670Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
      2023-11-02T17:36:28.674Z  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
      2023-11-02T17:36:28.717Z  INFO 1 --- [           main] c.e.testrunner.TestrunnerApplication     : Started TestrunnerApplication in 7.441 seconds (process running for 8.6)
      2023-11-02T17:36:33.921Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:36:33.921Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:36:33.923Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 2 ms
      ```

1. Deploy transfer service

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name transfer --artifact-path transfer/target/transfer-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: transfer/target/transfer-0.0.1-SNAPSHOT.jar
      building and pushing image...
      
      creating deployment and service...
      obaas-cli [deploy]: Application was successfully deployed.
      ```

   1. Verify deployment success

         ```shell
         kubectl logs -n cbv3 svc/transfer
         ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:39:53.088Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_TRANSFER/transfer-776567f8c6-zk8ts:transfer - registration status: 204
      2023-11-02T17:39:53.094Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
      2023-11-02T17:39:53.095Z  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
      2023-11-02T17:39:53.153Z  INFO 1 --- [           main] c.example.transfer.TransferApplication   : Started TransferApplication in 8.893 seconds (process running for 10.294)
      2023-11-02T17:40:04.081Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:40:04.083Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:40:04.088Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 5 ms
      ```

1. Deploy checks service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name checks --username account
      Database/Service Password: *************
      Schema {account} was successfully Not_Modified and Kubernetes Secret {cbv3/checks} was successfully Created.
      ```

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name checks --artifact-path checks/target/checks-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: checks/target/checks-0.0.1-SNAPSHOT.jar
      building and pushing image...
      
      creating deployment and service...
      obaas-cli [deploy]: Application was successfully deployed.
      ```

   1. Verify deployment success

         ```shell
         kubectl logs -n cbv3 svc/checks
         ```

      Successful deployment should be look similar to this:

      ```log
      2023-11-02T17:43:16.088Z  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
      2023-11-02T17:43:16.140Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CHECKS/checks-86df47898f-d6hhn:checks - registration status: 204
      2023-11-02T17:43:19.435Z  INFO 1 --- [           main] com.example.checks.ChecksApplication     : Started ChecksApplication in 11.646 seconds (process running for 12.726)
      2023-11-02T17:43:34.216Z  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
      2023-11-02T17:43:34.217Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
      2023-11-02T17:43:34.221Z  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 4 ms
      ```

1. Verify pods are running

   `kubectl get pods -n cbv3`

   ```text
   NAME                           READY   STATUS    RESTARTS   AGE
   account-6d7bcd9549-69wps       1/1     Running   0          21m
   checks-86df47898f-d6hhn        1/1     Running   0          94s
   creditscore-779bbcf848-th8nd   1/1     Running   0          11m
   customer-6787db57dc-lbncs      1/1     Running   0          14m
   testrunner-66f8f66d57-bpwwr    1/1     Running   0          8m17s
   transfer-776567f8c6-zk8ts      1/1     Running   0          4m54s
   ```

## Test Cloudbank Services

1. Test account service

   1. Port forward

      `kubectl port-forward -n cbv3 svc/account 8081:8080`

   1. Rest endpoint

      `curl -s http://localhost:8081/api/v1/accounts | jq` or `http --body :8081/api/v1/accounts`

      Should return:

      ```json
      [
      {
      "accountBalance": -20,
      "accountCustomerId": "qwertysdwr",
      "accountId": 149,
      "accountName": "Andy's checking",
      "accountOpenedDate": "2023-06-26T17:39:37.000+00:00",
      "accountOtherDetails": "Account Info",
      "accountType": "CH"
      },
      ```

1. Test customer service

   1. Port forward

      `kubectl port-forward -n cbv3 svc/customer 8082:8080`

   1. Rest endpoint

      `curl -s http://localhost:8082/api/v1/customer | jq` or `http --body :8081/api/v1/customer`

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
      ```

1. Test creditscore service

   1. Port forward

      `kubectl port-forward -n cbv3 svc/creditscore 8083:8080`

   1. Rest endpoint

      `curl -s http://localhost:8083/api/v1/creditscore | jq` or `http --body :8081/api/v1/creditscore`

      Should return:

      ```json
      {
      "Date": "2023-11-02",
      "Credit Score": "574"
      }
      ```

1. Test check service

   1. Port forward
      
      `kubectl -n cbv3 port-forward svc/testrunner 8084:8080`

   1. Rest endpoint - deposit check

      `curl -i -X POST -H 'Content-Type: application/json' -d '{"accountId": 2, "amount": 256}' http://localhost:8084/api/v1/testrunner/deposit`
      Should return:

      ```text
      HTTP/1.1 201
      Content-Type: application/json
      Transfer-Encoding: chunked
      Date: Thu, 02 Nov 2023 18:02:06 GMT

      {"accountId":2,"amount":256}
      ```

   1. Check logs

      `kubectl -n cbv3 logs svc/checks`

      Should contain:

      ```log
      Received deposit <CheckDeposit(accountId=2, amount=256)>
      ```

   1. Check journal entries

      ```shell
      curl -i http://localhost:8081/api/v1/account/2/journal
      ```

      output should similar to:

      ```log
      HTTP/1.1 200 
      Content-Type: application/json
      Transfer-Encoding: chunked
      Date: Thu, 02 Nov 2023 18:06:45 GMT

      [{"journalId":1,"journalType":"PENDING","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]
      ```

   1. Clearance of check - Note the JournalID

      ```shell
      curl -i -X POST -H 'Content-Type: application/json' -d '{"journalId": 1}' http://localhost:8084/api/v1/testrunner/clear
      ```

      output should be similar to:

      ```text
      HTTP/1.1 201 
      Content-Type: application/json
      Transfer-Encoding: chunked
      Date: Thu, 02 Nov 2023 18:09:17 GMT

      {"journalId":1
      ```

   1. Check logs

      `kubectl -n cbv3 logs svc/checks`

      Output should be similar to:

      ```log
      ...
      Received clearance <Clearance(journalId=1)>
      ...
      ```

   1. Check journal -- DEPOSIT

      `curl -i http://localhost:8081/api/v1/account/2/journal`

      Output should look like this -- DEPOSIT

      ```text
      `HTTP/1.1 200
      Content-Type: application/json
      Transfer-Encoding: chunked
      Date: Thu, 02 Nov 2023 18:36:31 GMT

      [{"journalId":1,"journalType":"DEPOSIT","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]`
      ```

1. Run LRA Test Cases

   1. Port forward

      `kubectl -n cbv3 port-forward svc/transfer 8085:8080`

   1. Check account balances

      ```shell
      curl -s http://localhost:8081/api/v1/account/1 | jq ; curl -s http://localhost:8081/api/v1/account/2 | jq 
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
      "accountBalance": -20
      }
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

   1. Perform transfer

      ```shell
      curl -X POST "http://localhost:8085/transfer?fromAccount=2&toAccount=1&amount=100"
      ```

      Output due to namespace:

      ```json
      {"timestamp":"2023-11-02T18:17:19.300+00:00","status":500,"error":"Internal Server Error","path":"/transfer"}
      ```

      Wrong namespace that's why. Feign for transfer service?

      ```yaml
      account:
         deposit:
            url: http://account.application:8080/deposit
      ```
