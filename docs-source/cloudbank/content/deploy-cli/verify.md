+++
archetype = "page"
title = "Verify the deployment"
weight = 6
+++


1. Verification of the services deployment

    Verify that the services are running properly by executing this command:

    ```shell
    kubectl get pods -n application
    ```

    The output should be similar to this, all pods should have `STATUS` as `Running`. If not then you need to look at the logs for the pods/service to determine what is wrong for example `kubectl logs -n application svc/customer`.

    ```text
    NAME                           READY   STATUS    RESTARTS   AGE
    account-65cdc68dd7-k5ntz       1/1     Running   0          8m2s
    checks-78c988bdcf-n59qz        1/1     Running   0          42m
    creditscore-7b89d567cd-nm4p6   1/1     Running   0          38m
    customer-6f4dc67985-nf5kz      1/1     Running   0          41s
    testrunner-78d679575f-ch4k7    1/1     Running   0          33m
    transfer-869d796755-gn9lf      1/1     Running   0          27m
    ```



1. Verify the all the Cloud Bank services deployed

   In the next few commands, you need to provide the correct IP address for the API Gateway in your backend environment. You can find the IP address using this command, you need the one listed in the `EXTERNAL-IP` column. In the example below the IP address is `100.20.30.40`

    1. Get external IP Address

        You can find the IP address using this command, you need the one listed in the `EXTERNAL-IP` column. In the example below the IP address is `100.20.30.40`

        ```shell
        $ kubectl -n ingress-nginx get service ingress-nginx-controller
        NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
        ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
        ```

    1. Test the create account REST endpoint with this command, use the external IP address for your API Gateway. Make a note of the `accountID` in the output:

        ```shell
        $ curl -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"accountName": "Sanjay''s Savings", "accountType": "SA", "accountCustomerId": "bkzLp8cozi", "accountOtherDetails": "Savings Account"}' \
        http://API-ADDRESS-OF-API-GW/api/v1/account
        HTTP/1.1 201
        Date: Wed, 01 Mar 2023 18:35:31 GMT
        Content-Type: application/json
        Transfer-Encoding: chunked
        Connection: keep-alive

        {"accountId":24,"accountName":"Sanjays Savings","accountType":"SA","accountCustomerId":"bkzLp8cozi","accountOpenedDate":null,"accountOtherDetails":"Savings Account","accountBalance":0}
        ```

    1. Test the get account REST endpoint with this command, use the IP address for your API Gateway and the `accountId` that was returned in the previous command:

        ```shell
        curl -s http://API-ADDRESS-OF-API-GW/api/v1/account/<accountId> | jq .
        ```

        Output should be similar to this:

        ```json
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

    1. Test on of the customer REST endpoints with this command, use the IP Address for your API Gateway.

        ```shell
        curl -s http://API-ADDRESS-OF-API-GW/api/v1/customer | jq
        ```

        Output should be similar to this:

        ```json
        [
            {
                "customerId": "qwertysdwr",
                "customerName": "Andy",
                "customerEmail": "andy@andy.com",
                "dateBecameCustomer": "2023-11-06T20:06:19.000+00:00",
                "customerOtherDetails": "Somekind of Info",
                "customerPassword": "SuperSecret"
            },
            {
                "customerId": "aerg45sffd",
                "customerName": "Sanjay",
                "customerEmail": "sanjay@sanjay.com",
                "dateBecameCustomer": "2023-11-06T20:06:19.000+00:00",
                "customerOtherDetails": "Information",
                "customerPassword": "Welcome"
            },
            {
                "customerId": "bkzLp8cozi",
                "customerName": "Mark",
                "customerEmail": "mark@mark.com",
                "dateBecameCustomer": "2023-11-06T20:06:19.000+00:00",
                "customerOtherDetails": "Important Info",
                "customerPassword": "Secret"
            }
        ]
        ```

    1. Test the creditscore REST endpoint with this command

        ```shell
        curl -s http://API-ADDRESS-OF-API-GW/api/v1/creditscore | jq
        ```

        Output should be similar to this:

        ```json
        {
            "Date": "2023-11-06",
            "Credit Score": "686"
        }
        ```

    1. Test the check service

        1. Start a tunnel to the testrunner service.

            ```shell
            $ kubectl -n application port-forward svc/testrunner 8084:8080
            Forwarding from 127.0.0.1:8084 -> 8080
            Forwarding from [::1]:8084 -> 8080
            ```

        1. Deposit a check using the *deposit* REST endpoint

            Run this command to deposit a check, make sure you use the *accountId* from the account you created earlier.

            ```shell
            $ curl -i -X POST -H 'Content-Type: application/json' -d '{"accountId": 2, "amount": 256}' http://localhost:8084/api/v1/testrunner/deposit
            HTTP/1.1 201
            Content-Type: application/json
            Transfer-Encoding: chunked
            Date: Thu, 02 Nov 2023 18:02:06 GMT

            {"accountId":2,"amount":256}
            ```

        1. Check the log of the *check* service

            Execute this command to check the log file of the *check* service:

            ```shell
            kubectl -n application logs svc/checks
            ```

            The log file should contain something similar to this (with your accountId):

            ```log
            Received deposit <CheckDeposit(accountId=2, amount=256)>
            ```

        1. Check the Journal entries using the *journal* REST endpoint. Replace `API-ADDRESS-OF-API-GW` with your external IP Address.

            ```shell
            curl -i http://API-ADDRESS-OF-API-GW/api/v1/account/2/journal
            ```

            The output should be similar to this (with your AccountId). Note the *journalId*, you're going to need it in the next step.

            ```log
            HTTP/1.1 200 
            Content-Type: application/json
            Transfer-Encoding: chunked
            Date: Thu, 02 Nov 2023 18:06:45 GMT

            [{"journalId":1,"journalType":"PENDING","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]
            ```

        1. Clearance of a check using the *clear* REST endpoint using your *journalId*:

            ```shell
            curl -i -X POST -H 'Content-Type: application/json' -d '{"journalId": 1}' http://localhost:8084/api/v1/testrunner/clear
            ```

            ```logs
            HTTP/1.1 201 
            Content-Type: application/json
            Transfer-Encoding: chunked
            Date: Thu, 02 Nov 2023 18:09:17 GMT

            {"journalId":1}
            ```

        1. Check the logs of the *checks* service

            Execute this command to check the log file of the *check* service:

            ```shell
            kubectl -n application logs svc/checks
            ```

            The log file should contain something similar to this (with your journalId):

            ```log
            Received clearance <Clearance(journalId=1)>
            ```

        1. Check the *journal* REST endpoint

            Execute this command to check the Journal. Replace `API-ADDRESS-OF-API-GW` with your External IP Address and `ACCOUNT-ID` with your account id.

            ```shell
            curl -i http://API-ADDRESS-OF-API-GW/api/v1/account/ACCOUNT-ID/journal
            ```

            The output should look like this (with your accountId):

            ```log
            `HTTP/1.1 200
            Content-Type: application/json
            Transfer-Encoding: chunked
            Date: Thu, 02 Nov 2023 18:36:31 GMT

            [{"journalId":1,"journalType":"DEPOSIT","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]`
            ```

    1. Test Saga transactions across Microservices using the *transfer* service.

        1. Start a tunnel to the testrunner service.

            ```shell
            $ kubectl -n application port-forward svc/transfer 8085:8080
            Forwarding from 127.0.0.1:8085 -> 8080
            Forwarding from [::1]:8085 -> 8080
            ```

        1. Check the account balances for two accounts, in this example the account numbers are 1 and 2. Replace `API-ADDRESS-OF-API-GW` with your External IP Address

            ```shell
            curl -s http://API-ADDRESS-OF-API-GW/api/v1/account/1 | jq ; curl -s http://API-ADDRESS-OF-API-GW/api/v1/account/2 | jq
            ```

            The output should be similar to this. Make a note of the `accountBalance` values.

            ```json
            {
                "accountId": 1,
                "accountName": "Andy's checking",
                "accountType": "CH",
                "accountCustomerId": "qwertysdwr",
                "accountOpenedDate": "2023-11-06T19:58:58.000+00:00",
                "accountOtherDetails": "Account Info",
                "accountBalance": -20
                }
                {
                "accountId": 2,
                "accountName": "Mark's CCard",
                "accountType": "CC",
                "accountCustomerId": "bkzLp8cozi",
                "accountOpenedDate": "2023-11-06T19:58:58.000+00:00",
                "accountOtherDetails": "Mastercard account",
                "accountBalance": 1000
                }
            ```

        1. Perform a transfer between the accounts (transfer $100 from account 2 to account 1)

            ```shell
            $ curl -X POST "http://localhost:8085/transfer?fromAccount=2&toAccount=1&amount=100"
            transfer status:withdraw succeeded deposit succeeded
            ```

        1. Check that the transfer has been made.

            ```shell
            curl -s http://API-ADDRESS-OF-API-GW/api/v1/account/1 | jq ; curl -s http://API-ADDRESS-OF-API-GW/api/v1/account/2 | jq
            ```

            The output should be similar to this. Make a note of the `accountBalance` values.

            ```json
            {
                "accountId": 1,
                "accountName": "Andy's checking",
                "accountType": "CH",
                "accountCustomerId": "qwertysdwr",
                "accountOpenedDate": "2023-11-06T19:58:58.000+00:00",
                "accountOtherDetails": "Account Info",
                "accountBalance": 80
                }
                {
                "accountId": 2,
                "accountName": "Mark's CCard",
                "accountType": "CC",
                "accountCustomerId": "bkzLp8cozi",
                "accountOpenedDate": "2023-11-06T19:58:58.000+00:00",
                "accountOtherDetails": "Mastercard account",
                "accountBalance": 900
                }
            ```

This concludes the module *Deploy the full CloudBank Application* using the `oractl` CLI interface.

