+++
archetype = "page"
title = "Test the end-to-end flow"
weight = 7
+++


Now you can test the full end-to-end flow for the Check Processing scenario.

1. Simulate a check deposit

  The Test Runner service is not exposed outside your Kubernetes cluster, so you must create a port-forwarding tunnel to access it.  Create a tunnel using this command:

    ```shell
    $ kubectl -n application port-forward svc/testrunner 8084:8080
    ```

   Simulate a check being deposited at the ATM using the Test Runner service:

    ```shell
    $ curl -i -X POST -H 'Content-Type: application/json' -d '{"accountId": 2, "amount": 256}' http://localhost:8084/api/v1/testrunner/deposit
    HTTP/1.1 201
    Date: Wed, 31 May 2023 15:11:55 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"accountId":2,"amount":256}
    ```

1. Check the logs for the Check Processing service

  Check the logs for the Check Processing service using this command.  You should see a log message indicating that the message was received and processed:

    ```shell
    $ kubectl -n application logs svc/checks
    ( ... lines omitted ...)
    Received deposit <CheckDeposit(accountId=2, amount=256)>
    ( ... lines omitted ...)
    ```

1. Check the journal entries for this account

  In the next commands, you need to provide the correct IP address for the API Gateway in your backend environment.  You can find the IP address using this command, you need the one listed in the **`EXTERNAL-IP`** column:

    ```shell
    $ kubectl -n ingress-nginx get service ingress-nginx-controller
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
    ```

  Use this command to retrieve the journal entries for this account.  Your output may contain more entries.  Find the entry corresponding to the deposit you just simulated (it was for $256) and note the `journalId` - you will need it in the next step:

    ```shell
    $ curl -i http://[EXTERNAL-IP]/api/v1/account/2/journal
    HTTP/1.1 200
    Date: Wed, 31 May 2023 13:03:22 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    [{"journalId":6,"journalType":"PENDING","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]
    ```

1. Simulate the Back Office clearance of that check

  Using the `journalId` you received in the output of the previous command (in this example it is `6`), update and then run this command to simulate the Back Office clearing that check:

    ```shell
    $ curl -i -X POST -H 'Content-Type: application/json' -d '{"journalId": 6}' http://localhost:8084/api/v1/testrunner/clear
    HTTP/1.1 201
    Date: Wed, 31 May 2023 15:12:54 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"journalId":6}
    ```

1. Check the logs for the Check Processing service

  Check the logs for the Check Processing service using this command.  You should see a log message indicating that the message was received and processed:

    ```shell
    $ kubectl -n application logs svc/checks
    ( ... lines omitted ...)
    Received clearance <Clearance(journalId=6)>
    ( ... lines omitted ...)
    ```

1. Retrieve the journal entries again

  Retrieve the journal entries again to confirm the `PENDING` entry was updated to a `DEPOSIT`:

    ```shell
    $ curl -i http://[EXTERNAL-IP]/api/v1/account/2/journal
    HTTP/1.1 200
    Date: Wed, 31 May 2023 13:03:22 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    [{"journalId":6,"journalType":"DEPOSIT","accountId":2,"lraId":"0","lraState":null,"journalAmount":256}]
    ```

  That completes this lab, congratulations, you learned how to use JMS to create loosely coupled services that process asynchronous messages, and also how to use service discovery with OpenFeign.
