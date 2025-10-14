# CloudBank Services Testing Guide

## Overview

This guide walks you through testing your CloudBank microservices deployment in an Oracle Backend as a Service (OBaaS) environment. You'll verify that all services are functioning correctly, test the distributed transaction capabilities using Long Running Actions (LRA), and explore the observability features built into the platform.

## Prerequisites

Before beginning these tests, ensure you have:

- A running OBaaS environment with CloudBank services deployed
- `kubectl` command-line tool installed and configured
- `curl` command-line tool for making HTTP requests
- `jq` for parsing JSON responses (optional but recommended)
- Access to the Kubernetes cluster where CloudBank is deployed

## Step 1: Getting Started

### 1.1 Retrieving the External IP Address

First, you need to obtain the external IP address of your ingress controller. This IP address will be used as the base URL for all API requests.

**1.1.1 Get the ingress controller information:**

Run the following command:

   ```shell
   kubectl -n ingress-nginx get service ingress-nginx-controller
   ```

**1.1.2 Review the output:**

You should see output similar to this:

   ```text
   NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
   ingress-nginx-controller   LoadBalancer   10.96.172.148   146.235.207.230   80:31393/TCP,443:30506/TCP   158m
   ```

**1.1.3 Create an environment variable:**

Use the following command to automatically extract and set the external IP address:

   ```shell
   export IP=$(kubectl -n ingress-nginx get service ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   ```

You can verify the IP was set correctly by running:

   ```shell
   echo $IP
   ```

This should display the external IP address (e.g., `146.235.207.230`).

---

## Step 2: Testing Core Services

### 2.1 Account Service

The Account service manages customer bank accounts including checking and credit card accounts.

**2.1.1 Test the REST Endpoint:**

Execute the following command to retrieve all accounts:

```shell
curl -s http://$IP/api/v1/accounts | jq
```

**2.1.2 Verify the Response:**

You should receive a JSON array containing account objects. Each account includes details such as account ID, customer ID, account type, balance, and opening date:

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
  {
    "accountBalance": 1000,
    "accountCustomerId": "bkzLp8cozi",
    "accountId": 2,
    "accountName": "Mark's CCard",
    "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
    "accountOtherDetails": "Mastercard account",
    "accountType": "CC"
  }
]
```

**Note:** Account types include "CH" for checking accounts and "CC" for credit card accounts.

---

### 2.2 Customer Service

The Customer service handles customer information and profile management.

**2.2.1 Retrieve All Customers:**

To view all customers in the system:

```shell
curl -s http://$IP/api/v1/customer | jq
```

**Expected Response:**

```json
[
  {
    "customerEmail": "andy@andy.com",
    "customerId": "qwertysdwr",
    "customerName": "Andy",
    "customerOtherDetails": "Somekind of Info",
    "customerPassword": "SuperSecret",
    "dateBecameCustomer": "2023-11-02T17:30:12.000+00:00"
  }
]
```

**2.2.2 Create a New Customer:**

To create a new customer, send a POST request with customer details:

```shell
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"customerId": "bobsmith", "customerName": "Bob Smith", "customerEmail": "bob@smith.com"}' \
  http://$IP/api/v1/customer
```

**Expected Response:**

A successful creation returns HTTP status 201 with a Location header pointing to the newly created resource:

```text
HTTP/1.1 201
Location: http://localhost:8080/api/v1/customer/bobsmith
Content-Length: 0
Date: Tue, 03 Sep 2024 21:01:25 GMT
```

---

### 2.3 Credit Score Service

The Credit Score service provides credit scoring information for customers.

**2.3.1 Check Credit Score:**

Retrieve the current credit score data:

```shell
curl -s http://$IP/api/v1/creditscore | jq
```

**Expected Response:**

```json
{
  "Date": "2023-12-26",
  "Credit Score": "574"
}
```

---

### 2.4 Check Processing Service

The Check service handles check deposits and clearances through a multi-step workflow involving journal entries.

**2.4.1 Deposit a Check:**

Initiate a check deposit for an existing account:

```shell
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"accountId": 1, "amount": 256}' \
  http://$IP/api/v1/testrunner/deposit
```

**Important:** Replace `1` with an actual account ID from your environment.

**Expected Response:**

```text
HTTP/1.1 201
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 02 Nov 2023 18:02:06 GMT

{"accountId":1,"amount":256}
```

**2.4.2 Verify Check Service Logs:**

Confirm the deposit was received by checking the service logs:

```shell
kubectl logs -n application svc/checks
```

**Expected Log Entry:**

```log
Received deposit <CheckDeposit(accountId=1, amount=256)>
```

**2.4.3 Check Journal Entries:**

View the journal entries for the account to see the pending deposit:

```shell
curl -i http://$IP/api/v1/account/1/journal
```

Replace `1` with your account number.

**Expected Response:**

```text
HTTP/1.1 200
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 02 Nov 2023 18:06:45 GMT

[{"journalId":1,"journalType":"PENDING","accountId":1,"lraId":"0","lraState":null,"journalAmount":256}]
```

**Note:** The journal type is "PENDING" at this stage, indicating the check has not yet cleared.

**2.4.4 Clear the Check:**

Process the check clearance using the journal ID from the previous step:

```shell
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"journalId": 1}' \
  http://$IP/api/v1/testrunner/clear
```

Replace `1` with the actual journal ID.

**Expected Response:**

```text
HTTP/1.1 201
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 02 Nov 2023 18:09:17 GMT

{"journalId":1}
```

**2.4.5 Verify Clearance in Logs:**

Check the service logs again to confirm clearance was processed:

```shell
kubectl logs -n application svc/checks
```

**Expected Log Entry:**

```log
Received clearance <Clearance(journalId=1)>
```

**2.4.6 Verify Final Journal Entry:**

Check the journal entries again to confirm the deposit has been completed:

```shell
curl -i http://$IP/api/v1/account/1/journal
```

**Expected Response:**

```text
HTTP/1.1 200
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 02 Nov 2023 18:36:31 GMT

[{"journalId":1,"journalType":"DEPOSIT","accountId":1,"lraId":"0","lraState":null,"journalAmount":256}]
```

**Note:** The journal type has changed from "PENDING" to "DEPOSIT", indicating successful clearance.

---

## Step 3: Testing Long Running Actions (LRA)

Long Running Actions provide distributed transaction coordination across microservices. This test demonstrates a fund transfer between two accounts using the LRA pattern.

### 3.1 Check Initial Account Balances

Before performing the transfer, record the initial balances of both accounts:

```shell
curl -s http://$IP/api/v1/account/1 | jq
curl -s http://$IP/api/v1/account/2 | jq
```

**Note:** Account numbers may differ in your environment. Adjust the account IDs as needed.

**Example Output:**

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
```

```json
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

### 3.2 Perform the Transfer

Execute a transfer of funds from one account to another:

```shell
curl -X POST "http://$IP/transfer?fromAccount=2&toAccount=1&amount=100"
```

Adjust the account numbers and amount as needed.

**Expected Response:**

```text
transfer status:withdraw succeeded deposit succeeded
```

This indicates that both the withdrawal from the source account and the deposit to the destination account completed successfully.

### 3.3 Verify Account Balances

Check both accounts again to confirm the transfer was applied correctly:

```shell
curl -s http://$IP/api/v1/account/1 | jq
curl -s http://$IP/api/v1/account/2 | jq
```

**Expected Output:**

Account 1 balance should have increased by 100:

```json
{
  "accountId": 1,
  "accountName": "Andy's checking",
  "accountType": "CH",
  "accountCustomerId": "qwertysdwr",
  "accountOpenedDate": "2023-11-02T17:23:53.000+00:00",
  "accountOtherDetails": "Account Info",
  "accountBalance": 80
}
```

Account 2 balance should have decreased by 100:

```json
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

### 3.4 Review Transfer Service Logs

Examine the detailed LRA coordination logs:

```shell
kubectl logs -n application svc/transfer
```

**Expected Log Output:**

```text
2023-12-26T16:50:45.138Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : Started new LRA/transfer Id: http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/ea98ebae-2358-4dd1-9d7c-09f4550d7567
2023-12-26T16:50:45.139Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw accountId = 2, amount = 100
2023-12-26T16:50:45.183Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw succeeded
2023-12-26T16:50:45.183Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : deposit accountId = 1, amount = 100
2023-12-26T16:50:45.216Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : withdraw succeeded deposit succeeded
2023-12-26T16:50:45.216Z  INFO 1 --- [transfer] [nio-8080-exec-9] [] com.example.transfer.TransferService     : LRA/transfer action will be confirm
2023-12-26T16:50:45.226Z  INFO 1 --- [transfer] [nio-8080-exec-1] [] com.example.transfer.TransferService     : Received confirm for transfer
2023-12-26T16:50:45.233Z  INFO 1 --- [transfer] [io-8080-exec-10] [] com.example.transfer.TransferService     : Process confirm for transfer
```

These logs show the complete LRA lifecycle: initiation, withdrawal, deposit, and confirmation.

---

## Step 4: Observability and Monitoring

OBaaS includes several built-in observability tools to help you monitor and troubleshoot your microservices.

### 4.1 Eureka Service Registry

Eureka provides service discovery, showing all registered microservices.

**4.1.1 Create a Port Forward:**

Create a port forward to the Eureka service:

```shell
kubectl -n eureka port-forward svc/eureka 8761
```

**4.1.2 Access the Dashboard:**

Open your browser and navigate to:

```
http://localhost:8761
```

**4.1.3 Verify Service Registration:**

The dashboard displays all registered services, their health status, and instance information. Verify that all CloudBank services (account, customer, check, transfer, etc.) appear in the registry.

---

### 4.2 Spring Boot Admin Server

The Admin Server provides detailed management and monitoring capabilities for Spring Boot applications.

**4.2.1 Create a Port Forward:**

Create a port forward to the Admin Server:

```shell
kubectl port-forward -n admin-server svc/admin-server 8989
```

**4.2.2 Access the Dashboard:**

Open your browser and navigate to:

```
http://localhost:8989
```

**4.2.3 Explore Service Metrics:**

The dashboard shows detailed metrics, health checks, environment properties, and logging information for each registered service.

---

### 4.3 SigNoz - Distributed Tracing and Observability

SigNoz provides comprehensive observability including distributed tracing, metrics, and log aggregation.

**4.3.1 Retrieve Admin Credentials:**

Get the admin email and password:

```shell
kubectl -n observability get secret signoz-authn -o jsonpath='{.data.email}' | base64 -d
kubectl -n observability get secret signoz-authn -o jsonpath='{.data.password}' | base64 -d
```

**4.3.2 Create a Port Forward:**

Create a port forward to the SigNoz frontend:

```shell
kubectl -n observability port-forward svc/obaas-signoz-frontend 3301:3301
```

**4.3.3 Access the Login Page:**

Open your browser and navigate to:

```
http://localhost:3301/login
```

Log in using the email and password retrieved in step 4.3.1.

**4.3.4 Explore Pre-installed Dashboards:**

Navigate through the pre-configured dashboards to view system metrics, service performance, and infrastructure health.

**4.3.5 View Distributed Traces:**

To explore distributed traces:

1. Click on the "Traces" section in the navigation menu
2. Select the `customer` service from the service dropdown to view traces related to customer operations
3. Click on any trace to expand and view detailed timing information across all involved services
4. Use the trace visualization to identify performance bottlenecks and understand request flow

**4.3.6 Browse Application Logs:**

To view application logs:

1. Click on the "Logs" section in the navigation menu
2. Select the `customer` service from the service dropdown
3. Browse through application logs with full context and filtering capabilities
4. Click on any log line to expand and view complete details including trace correlation

---

## Troubleshooting Tips

- **Service Not Responding:** Check that all pods are running using `kubectl get pods -n application`
- **Connection Refused:** Verify the external IP is correct and accessible
- **401/403 Errors:** Ensure you're using the correct authentication credentials
- **Transaction Failures:** Review service logs for detailed error messages
- **Port Forward Issues:** Ensure no other process is using the specified port

---

## Next Steps

After successfully completing these tests, you can:

- Deploy additional microservices to your CloudBank application
- Configure custom observability dashboards
- Implement additional business logic and workflows
- Explore advanced LRA patterns for complex transactions
- Set up alerts and notifications for critical events

For more information about OBaaS and CloudBank, consult the official Oracle documentation.