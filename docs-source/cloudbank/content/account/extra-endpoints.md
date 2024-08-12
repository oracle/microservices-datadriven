+++
archetype = "page"
title = "Extra Account Endpoints"
weight = 8
+++

If you would like to learn more about endpoints and implement the remainder of the account-related endpoints, this task provides the necessary details.

1. Implement Get Accounts for Customer ID endpoint

    Add a new method to your `AccountController.java` class that responds to the HTTP GET method.  This method should accept a customer ID as a path variable and return a list of accounts for that customer ID.  If no accounts are found, return an empty body and set the HTTP Status Code to 204 (No Content).

      Here is the code to implement this endpoint:

    ```java
    import java.util.ArrayList;
    
    // ...

    @GetMapping("/account/getAccounts/{customerId}")
    public ResponseEntity<List<Account>> getAccountsByCustomerId(@PathVariable("customerId") String customerId) {
        try {
            List<Account> accountData = new ArrayList<Account>();
            accountData.addAll(accountRepository.findByAccountCustomerId(customerId));
            if (accountData.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return new ResponseEntity<>(accountData, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

    You will also need to update your `AccountRepository.java` class to add the extra find method you need for this endpoint.

    ```java
    import java.util.List; 

    // ...

    public interface AccountRepository extends JpaRepository <Account, Long> {
        List<Account> findByAccountCustomerId(String customerId);
    }
    ```

1. Test the `/account/getAccounts/{customerId}` endpoint

    Restart the application and test the new endpoint with this command (note that you created this account and customer ID earlier):

    ```shell
    $ curl -s http://localhost:8080/api/v1/account/getAccounts/bkzLp8cozi | jq .
    [
      {
        "accountId": 2,
        "accountName": "Mark's CCard",
        "accountType": "CC",
        "accountCustomerId": "bkzLp8cozi",
        "accountOpenedDate": "2023-02-26T02:04:56.000+00:00",
        "accountOtherDetails": "Mastercard account",
        "accountBalance": 1000
      }
    ]
    ```

1. Implement a Delete Account API endpoint

    Add a new method to your `AccountController.java` file that responds to the HTTP DELETE method and accepts an account ID as a path variable.  You can use the `@DeleteMapping` annotation to respond to HTTP DELETE.  This method should delete the account specified and return an empty body and HTTP Status Code 204 (No Content) which is generally accepted to mean the deletion was successful (some people also use 200 (OK) for this purpose).

    Here is the code to implement this endpoint:

    ```java
    import org.springframework.web.bind.annotation.DeleteMapping;
    
    // ...

    @DeleteMapping("/account/{accountId}")
    public ResponseEntity<HttpStatus> deleteAccount(@PathVariable("accountId") long accountId) {
        try {
            accountRepository.deleteById(accountId);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

1. Test the Delete `/account/{accountId}` endpoint

    Restart the application and test this new endpoint by creating and deleting an account. First create an account:

    ```shell
    $ curl -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"accountName": "Bob", "accountType": "CH", "accountOtherDetail": "", "accountCustomerId": "bob808bob"}' \
        http://localhost:8080/api/v1/account
    HTTP/1.1 201 
    Content-Type: application/json
    Transfer-Encoding: chunked
    Date: Wed, 01 Mar 2023 13:23:44 GMT

    {"accountId":42,"accountName":"Bob","accountType":"CH","accountCustomerId":"bob808bob","accountOpenedDate":"2023-03-01T18:23:44.000+00:00","accountOtherDetails":null,"accountBalance":0}
    ```

    Verify that account exists:

    ```shell
    $ curl -s http://localhost:8080/api/v1/account/getAccounts/bob808bob | jq .
    [
      {
        "accountId": 42,
        "accountName": "Bob",
        "accountType": "CH",
        "accountCustomerId": "bob808bob",
        "accountOpenedDate": "2023-03-01T18:23:44.000+00:00",
        "accountOtherDetails": null,
        "accountBalance": 0
      }
    ]
    ```

    Delete the account. **Note** that your account ID may be different, check the output from the previous command to get the right ID and replace `42` at the end of the URL with your ID:

    ```shell
    $ curl -i -X DELETE http://localhost:8080/api/v1/account/42
    HTTP/1.1 204 
    Date: Wed, 01 Mar 2023 13:23:56 GMT
    ```

    Verify the account no longer exists:

    ```shell
    $ curl -s http://localhost:8080/api/v1/account/getAccounts/bob808bob | jq .
    ```

   That completes the account endpoints.  Now it is time to deploy your service to the backend.

