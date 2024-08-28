+++
archetype = "page"
title = "Run LRA test cases"
weight = 11
+++


Now you can test your LRA to verify it performs correctly under various circumstances.

1. Start a tunnel to access the transfer service

  Since the transfer service is not exposed outside the Kubernetes cluster, you will need to start a **kubectl** port forwarding tunnel to access its endpoints.

    > **Note**: If you prefer, you can create a route in the APISIX API Gateway to expose the service.  The service will normally only be invoked from within the cluster, so you did not create a route for it.  However, you have learned how to create routes, so you may do that if you prefer.

    Run this command to start the tunnel:

    ```shell
    $ kubectl -n application port-forward svc/transfer 7000:8080
    ```

  Now the transfer service will be accessible at [http://localhost:7000/api/v1/transfer](http://localhost:7000/api/v1/transfer).

1. Check the starting account balances

  In several of the next few commands, you need to provide the correct IP address for the API Gateway in your backend environment.  Not the ones that use `localhost`, just those where the example uses `100.20.30.40` as the address. You can find the IP address using this command, you need the one listed in the `EXTERNAL-IP` column:

    ```shell
    $ kubectl -n ingress-nginx get service ingress-nginx-controller
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
    ```

  Before you start, check the balances of the two accounts that you will be transferring money between using this command (make sure you are using the EXTERNAL-IP of your environment). Note that these accounts were created in an earlier step.

    ```shell
    $ curl -s http://100.20.30.40/api/v1/account/1 | jq ; curl -s http://100.20.30.40/api/v1/account/2 | jq
    {
        "accountId": 1,
        "accountName": "Andy's checking",
        "accountType": "CH",
        "accountCustomerId": "abcDe7ged",
        "accountOpenedDate": "2023-03-06T13:56:43.000+00:00",
        "accountOtherDetails": "Account Info",
        "accountBalance": -20
    }
    {
        "accountId": 2,
        "accountName": "Mark's CCard",
        "accountType": "CC",
        "accountCustomerId": "bkzLp8cozi",
        "accountOpenedDate": "2023-03-06T13:56:44.000+00:00",
        "accountOtherDetails": "Mastercard account",
        "accountBalance": 1000
    }
    ```

  Note that account 1 has -$20 in this example, and account 2 has $1,000.  Your results may be different.

1. Perform a transfer that should succeed

  Run this command to perform a transfer that should succeed.  Note that both accounts exist and the amount of the transfer is less than the balance of the source account.

    ```shell
    $ curl -X POST "http://localhost:7000/transfer?fromAccount=2&toAccount=1&amount=100"
    transfer status:withdraw succeeded deposit succeeded
    ```  

  Check the two accounts again to confirm the transfer behaved as expected:

    ```shell
    $ curl -s http://100.20.30.40/api/v1/account/1 | jq ; curl -s http://100.20.30.40/api/v1/account/2 | jq
    {
        "accountId": 1,
        "accountName": "Andy's checking",
        "accountType": "CH",
        "accountCustomerId": "abcDe7ged",
        "accountOpenedDate": "2023-03-06T13:56:43.000+00:00",
        "accountOtherDetails": "Account Info",
        "accountBalance": 80
    }
    {
        "accountId": 2,
        "accountName": "Mark's CCard",
        "accountType": "CC",
        "accountCustomerId": "bkzLp8cozi",
        "accountOpenedDate": "2023-03-06T13:56:44.000+00:00",
        "accountOtherDetails": "Mastercard account",
        "accountBalance": 900
    }
    ```

  Notice that account 2 now has only $900 and account 1 has $80.  So the $100 was successfully transferred as expected.

1. Perform a transfer that should fail due to insufficient funds in the source account

  Run this command to attempt to transfer $100,000 from account 2 to account 1.  This should fail because account 2 does not have enough funds.

    ```shell
    $ curl -X POST "http://localhost:7000/transfer?fromAccount=2&toAccount=1&amount=100000"
    transfer status:withdraw failed: insufficient funds
    ```

1. Perform a transfer that should fail due to the destination account not existing.

  Execute the following command to perform a `failed` transfer:
  
    ```shell
    $ curl -X POST "http://localhost:7000/transfer?fromAccount=2&toAccount=6799999&amount=100"
    transfer status:withdraw succeeded deposit failed: account does not exist%  
    ```

1. Access the applications logs to verify what happened in each case

  Access the Transfer application log with this command.  Your output will be different:

    ```shell
    $ kubectl -n application logs svc/transfer
    2023-03-04 21:52:12.421  INFO 1 --- [nio-8080-exec-3] TransferService                          : Started new LRA/transfer Id: http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/18a093ef-beb6-4065-bb6c-b9328c8bb3e5
    2023-03-04 21:52:12.422  INFO 1 --- [nio-8080-exec-3] TransferService                          : withdraw accountId = 2, amount = 100
    2023-03-04 21:52:12.426  INFO 1 --- [nio-8080-exec-3] TransferService                          : withdraw lraId = http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/18a093ef-beb6-4065-bb6c-b9328c8bb3e5
    2023-03-04 21:52:12.615  INFO 1 --- [nio-8080-exec-3] TransferService                          : withdraw succeeded
    2023-03-04 21:52:12.616  INFO 1 --- [nio-8080-exec-3] TransferService                          : deposit accountId = 6799999, amount = 100
    2023-03-04 21:52:12.619  INFO 1 --- [nio-8080-exec-3] TransferService                          : deposit lraId = http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/18a093ef-beb6-4065-bb6c-b9328c8bb3e5
    2023-03-04 21:52:12.726  INFO 1 --- [nio-8080-exec-3] TransferService                          : withdraw succeeded deposit failed: account does not exist
    2023-03-04 21:52:12.726  INFO 1 --- [nio-8080-exec-3] TransferService                          : LRA/transfer action will be cancel
    2023-03-04 21:52:12.757  INFO 1 --- [nio-8080-exec-1] TransferService                          : Received cancel for transfer : http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/18a093ef-beb6-4065-bb6c-b9328c8bb3e5
    2023-03-04 21:52:12.817  INFO 1 --- [nio-8080-exec-2] TransferService                          : Process cancel for transfer : http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/18a093ef-beb6-4065-bb6c-b9328c8bb3e5
    ```

  In the example output above you can see one what happened during that last test you ran a moment ago.  Notice that the LRA started, the withdrawal succeeded, then the deposit failed because the account did not exist.  Then you can see that the next action is cancel, and then the LRA being canceled/compensated.

In this module you have learned about the Saga pattern by implementing an account transfer scenarios.
 You did this by implementing the long running activity, including `transfer` and `account` services that connect to a coordinator, according to the Long Running Action specification.
