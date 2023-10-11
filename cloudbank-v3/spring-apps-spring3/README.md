# CloudBank Version 3

This Spring Boot project is used in the [Oracle Backend Platform for Microservices with Oracle Database](https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/view-workshop?wid=3607) Live Lab.

Please visit the Live Lab for more information.

## Build cloudbank

   `mvn clean package -Dmaven.test.skip=true`

   ```text
   [INFO] ------------------------------------------------------------------------
   [INFO] Reactor Summary for cloudbank 0.0.1-SNAPSHOT:
   [INFO]
   [INFO] cloudbank .......................................... SUCCESS [  0.456 s]
   [INFO] account ............................................ SUCCESS [  0.507 s]
   [INFO] customer ........................................... SUCCESS [  0.079 s]
   [INFO] creditscore ........................................ SUCCESS [  0.049 s]
   [INFO] transfer ........................................... SUCCESS [  0.053 s]
   [INFO] testrunner ......................................... SUCCESS [  0.050 s]
   [INFO] checks ............................................. SUCCESS [  0.245 s]
   [INFO] ------------------------------------------------------------------------
   [INFO] BUILD SUCCESS
   [INFO] ------------------------------------------------------------------------
   [INFO] Total time:  1.633 s
   [INFO] Finished at: 2023-10-09T09:34:43-05:00
   [INFO] ------------------------------------------------------------------------
   ```

## Deploying Cloudbank

1. Start the tunnel

   `kpf -n obaas-admin svc/obaas-admin 8080`

1. Login

   ```shell
   oractl:>connect
   password (defaults to oractl):
   using default value...
   connect successful server version:0.3.0
   ```

1. Create namespace

    ```shell
    oractl:>create --app-name cbv3
    ```

1. Deploy account service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name account
      database password/servicePassword (defaults to Welcome12345): *************
      Kubernetes secret for Datasource was created successfully.
      ```

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name account --artifact-path account/target/account-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --redeploy true
      uploading: account/target/account-0.0.1-SNAPSHOT.jarbuilding and pushing image...
      creating deployment and service... successfully deployed
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
      oractl:>deploy --app-name cbv3 --service-name customer --artifact-path customer/target/customer-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: customer/target/customer-0.0.1-SNAPSHOT.jarbuilding and pushing image...
      creating deployment and service... successfully deployed
      ```

1. Deploy creditscore service

   ```shell
   oractl:>deploy --app-name cbv3 --service-name creditscore --artifact-path creditscore/target/creditscore-0.0.1-SNAPSHOT.jar --image-version 0.0.1
   uploading: creditscore/target/creditscore-0.0.1-SNAPSHOT.jarbuilding and pushing image...
   creating deployment and service... successfully deployed```
   ```

1. Deploy testrunner service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name testrunner --username account
      database password/servicePassword (defaults to Welcome12345): *************
      Kubernetes secret for Datasource was created successfully.
      ```

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name testrunner --artifact-path testrunner/target/testrunner-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: testrunner/target/testrunner-0.0.1-SNAPSHOT.jarbuilding and pushing image...
      creating deployment and service... successfully deployed
      ```

1. Deploy transfer service

   ```shell
   oractl:>deploy --app-name cbv3 --service-name transfer --artifact-path transfer/target/transfer-0.0.1-SNAPSHOT.jar --image-version 0.0.1
   uploading: transfer/target/transfer-0.0.1-SNAPSHOT.jarbuilding and pushing image...
   creating deployment and service... successfully deployed
   ```

1. Deploy checks service

   1. bind

      ```shell
      oractl:>bind --app-name cbv3 --service-name checks --username account
      database password/servicePassword (defaults to Welcome12345): *************
      Kubernetes secret for Datasource was created successfully.
      ```

   1. deploy

      ```shell
      oractl:>deploy --app-name cbv3 --service-name checks --artifact-path checks/target/checks-0.0.1-SNAPSHOT.jar --image-version 0.0.1
      uploading: checks/target/checks-0.0.1-SNAPSHOT.jarbuilding and pushing image...
      creating deployment and service... successfully deployed
      ```

1. Verify pods are running

   `kgp -n cbv3`

   ```text
   NAME                           READY   STATUS    RESTARTS   AGE
   account-5b68b6dbb6-l5sbd       1/1     Running   0          18m
   checks-848c7c8898-cqpss        1/1     Running   0          36s
   creditscore-5fd9f975c5-s5zlp   1/1     Running   0          11m
   customer-665d64bbbd-mnm4h      1/1     Running   0          13m
   testrunner-7cd7cb8f76-fg9ph    1/1     Running   0          4m10s
   transfer-55c4664759-2tfvl      1/1     Running   0          7m33s
   ```

## Test Cloudbank

1. Test account service

   1. Port forward
   `kpf -n cbv3 svc/account 8081:8080`
   
   1. Rest endpoint
   `http --body :8081/api/v1/accounts`

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
   ...
   ...
   ```

curl -i -X POST \
-H 'Content-Type: application/json' \
-d '{"journalType": "PENDING", "accountId": 149, "journalAmount": 100.00, "lraId": "0", "lraState": ""}' \
http://localhost:8081/api/v1/account/journal

```json
{"journalId":21,"journalType":"PENDING","accountId":149,"lraId":"0","lraState":"","journalAmount":100}
```

`http --body :8081/api/v1/account/149/journal`

```json
[
    {
        "accountId": 149,
        "journalAmount": 100,
        "journalId": 21,
        "journalType": "PENDING",
        "lraId": "0",
        "lraState": null
    },
    {
        "accountId": 149,
        "journalAmount": 100,
        "journalId": 22,
        "journalType": "PENDING",
        "lraId": "0",
        "lraState": null
    },
    {
        "accountId": 149,
        "journalAmount": 100,
        "journalId": 23,
        "journalType": "PENDING",
        "lraId": "0",
        "lraState": null
    }
]
```

`curl -i -X POST http://localhost:8081/api/v1/account/journal/21/clear`

```json
{"journalId":21,"journalType":"DEPOSIT","accountId":149,"lraId":"0","lraState":null,"journalAmount":100}
```


1. Test customer service

   1. Port forward
   `kpf -n cbv3 svc/customer 8082:8080`

   1. Rest points
   `http --body :8082/api/v1/customer`

   ```json
   [
   {
   "customerEmail": "sanjay@sanjay.com",
   "customerId": "aerg45sffd",
   "customerName": "Sanjay",
   "customerOtherDetails": "Information",
   "customerPassword": "Welcome",
   "dateBecameCustomer": "2023-06-26T17:44:49.000+00:00"
   },
   ... 
   ... 
   ```

1. Test creditscore service

   1. Port forward
   `kpf -n cbv3 svc/creditscore 8081:8080`

   1. REST call to endpoint
   `http --body :8081/api/v1/creditscore`
   
   ```json
   {
       "Credit Score": "844",
       "Date": "2023-06-26"
   }
   ```

1. Test check processing services
`curl -i -X POST -H 'Content-Type: application/json' -d '{"journalId": 4}' http://localhost:8083/api/v1/testrunner/clear`

http POST :8083/api/v1/testrunner/clear journalId:=4

```json
{"journalId":4}
```

1. Test the transfer service

http :9090/api/v1/accounts

curl -X POST "http://localhost:7000/transfer?fromAccount=594&toAccount=596&amount=100"

curl -X POST "http://localhost:7000/transfer?fromAccount=594&toAccount=596&amount=100000"

http POST :7000/transfer fromAccount==594 toAccount==596 amount==1000000

http :9090/api/v1/account/596

http :9090/api/v1/account/594

klf -n cbv3 svc/transfer

## Verify Monitoring of Cloudbank

