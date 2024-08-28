+++
archetype = "page"
title = "Query and Create Accounts"
weight = 7
+++

1. Create a service to list all accounts

    Open your `AccountsController.java` file and add a final field in the class of type `AccountRepository`.  And update the constructor to accept an argument of this type and set the field to that value.  This tells Spring Boot to inject the JPA repository class we just created into this class.  That will make it available to use in our services.  The updated parts of your class should look like this:

    ```java
    import com.example.accounts.repository.AccountRepository;
    
    // ...
    
    final AccountRepository accountRepository;
    
    public AccountController(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }
    ```

    Now, add a method to get all the accounts from the database and return them.  This method should respond to the HTTP GET method.  You can use the built-in `findAll` method on `JpaRepository` to get the data.  Your new additions to your class should look like this:

    ```java
    import java.util.List;
    import com.example.accounts.model.Account;
    
    // ...

    @GetMapping("/accounts")
    public List<Account> getAllAccounts() {
        return accountRepository.findAll();
    }
    ```

1. Rebuild and restart your application and test your new endpoint

    If your application is still running, stop it with Ctrl+C (or equivalent) and then rebuild and restart it with this command:

    ```shell
    $ mvn spring-boot:run
    ```

    This time, when it starts up you will see some new log messages that were not there before.  These tell you that it connected to the database successfully.

    ```text
    2023-02-25 15:58:16.852  INFO 29041 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
    2023-02-25 15:58:16.872  INFO 29041 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 5.6.15.Final
    2023-02-25 15:58:16.936  INFO 29041 --- [           main] o.hibernate.annotations.common.Version   : HCANN000001: Hibernate Commons Annotations {5.1.2.Final}
    2023-02-25 15:58:17.658  INFO 29041 --- [           main] org.hibernate.dialect.Dialect            : HHH000400: Using dialect: org.hibernate.dialect.Oracle12cDialect
    2023-02-25 15:58:17.972  INFO 29041 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000490: Using JtaPlatform implementation: [org.hibernate.engine.transaction.jta.platform.internal.NoJtaPlatform]
    2023-02-25 15:58:17.977  INFO 29041 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
    ```

    Now you can test the new service with this command. It will not return any data as we haven't loaded any data yet.

    ```shell
    $ curl http://localhost:8080/api/v1/accounts
    HTTP/1.1 200 
    Content-Type: application/json
    Transfer-Encoding: chunked
    Date: Sat, 25 Feb 2023 21:00:40 GMT
    
    []
    ```

1. Add data to `ACCOUNTS` table

    Notice that Spring Boot automatically set the `Content-Type` to `application/json` for us.  The result is an empty JSON array `[]` as you might expect.  Add some accounts to the database using these SQL statements (run these in your SQLcl terminal):

    ```sql
    insert into account.accounts (account_name,account_type,customer_id,account_other_details,account_balance)
    values ('Andy''s checking','CH','abcDe7ged','Account Info',-20);
    insert into account.accounts (account_name,account_type,customer_id,account_other_details,account_balance)
    values ('Mark''s CCard','CC','bkzLp8cozi','Mastercard account',1000);
    commit;
    ```

1. Test the `/accounts` service

    Now, test the service again.  You may want to send the output to `jq` if you have it installed, so that it will be formatted for easier reading:

    ```shell
    $ curl -s http://localhost:8080/api/v1/accounts | jq .
    [
      {
        "accountId": 1,
        "accountName": "Andy's checking",
        "accountType": "CH",
        "accountCustomerId": "abcDe7ged",
        "accountOpenedDate": "2023-02-26T02:04:54.000+00:00",
        "accountOtherDetails": "Account Info",
        "accountBalance": -20
      },
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

    Now that you can query accounts, it is time to create an API endpoint to create an account.

1. Create an endpoint to create a new account.

    Now we want to create an endpoint to create a new account.  Open `AccountController.java` and add a new `createAccount` method.  This method should return `ResponseEntity<Account>` this will allow you to return the account object, but also gives you access to set headers, status code and so on.  The method needs to take an `Account` as an argument.  Add the `RequestBody` annotation to the argument to tell Spring Boot that the input data will be in the HTTP request's body.

    Inside the method, you should use the `saveAndFlush` method on the JPA Repository to save a new instance of `Account` in the database.  The `saveAndFlush` method returns the created object.  If the save was successful, return the created object and set the HTTP Status Code to 201 (Created).  If there is an error, set the HTTP Status Code to 500 (Internal Server Error).

    Here's what the new method (and imports) should look like:

    ```java
    
    import java.net.URI;
    ...
    ...
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.RequestBody;
    import org.springframework.http.HttpStatus;
    import org.springframework.http.ResponseEntity;
    import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

    // ...
    
    @PostMapping("/account")
    public ResponseEntity<Account> createAccount(@RequestBody Account account) {
        try {
            Account newAccount = accountRepository.saveAndFlush(account);
            URI location = ServletUriComponentsBuilder
                    .fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(newAccount.getAccountId())
                    .toUri();
            return ResponseEntity.created(location).build();
        } catch (Exception e) {
            return new ResponseEntity<>(account, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

1. Test the `/account` endpoint

    Rebuild and restart the application as you have previously.  Then test the new endpoint.  You will need to make an HTTP POST request, and you will need to set the `Content-Type` header to `application/json`.  Pass the data in as JSON in the HTTP request body.  Note that Spring Boot Web will handle mapping the JSON to the right fields in the type annotated with the `RequestBody` annotation.  So a JSON field called `accountName` will map to the `accountName` field in the JSON, and so on.

    Here is an example request and the expected output (yours will be slightly different):

    ```shell
    $ curl -i -X POST \
          -H 'Content-Type: application/json' \
          -d '{"accountName": "Dave", "accountType": "CH", "accountOtherDetail": "", "accountCustomerId": "abc123xyz"}' \
          http://localhost:8080/api/v1/account
    HTTP/1.1 201 
    Location: http://localhost:8080/api/v1/account/3
    Content-Length: 0
    Date: Wed, 14 Feb 2024 21:33:17 GMT
    ```

    Notice the HTTP Status Code is 201 (Created). The service returns the URI for the account was created in the header.

1. Test endpoint `/account` with bad data

    Now try a request with bad data that will not be able to be parsed and observe that the HTTP Status Code is 400 (Bad Request).  If there happened to be an exception thrown during the `save()` method, you would get back a 500 (Internal Server Error):

    ```shell
    $ curl -i -X POST -H 'Content-Type: application/json' -d '{"bad": "data"}'  http://localhost:8080/api/v1/account
    HTTP/1.1 400 
    Content-Type: application/json
    Transfer-Encoding: chunked
    Date: Sat, 25 Feb 2023 22:05:24 GMT
    Connection: close
    
    {"timestamp":"2023-02-25T22:05:24.350+00:00","status":400,"error":"Bad Request","path":"/api/v1/account"}
    ```

1. Implement Get Account by Account ID endpoint

    Add new method to your `AccountController.java` class that responds to the HTTP GET method.  This method should accept the account ID as a path variable.  To accept a path variable, you place the variable name in braces in the URL path in the `@GetMapping` annotation and then reference it in the method's arguments using the `@PathVariable` annotation.  This will map it to the annotated method argument.  If an account is found, you should return that account and set the HTTP Status Code to 200 (OK).  If an account is not found, return an empty body and set the HTTP Status Code to 404 (Not Found).

    Here is the code to implement this endpoint:

    ```java
    import org.springframework.http.HttpStatus;
    import org.springframework.http.ResponseEntity;
    import org.springframework.web.bind.annotation.PathVariable;
    import java.util.Optional;
    
    // ...

    @GetMapping("/account/{accountId}")
    public ResponseEntity<Account> getAccountById(@PathVariable("accountId") long accountId) {
        Optional<Account> accountData = accountRepository.findById(accountId);
        try {
            return accountData.map(account -> new ResponseEntity<>(account, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

1. Restart and test `/account/{accountId}` endpoint

    Restart the application and test this new endpoint with this command (note that you created account with ID 2 earlier):

    ```shell
    $ curl -s http://localhost:8080/api/v1/account/2 | jq .
    {
      "accountId": 2,
      "accountName": "Mark's CCard",
      "accountType": "CC",
      "accountCustomerId": "bkzLp8cozi",
      "accountOpenedDate": "2023-02-26T02:04:56.000+00:00",
      "accountOtherDetails": "Mastercard account",
      "accountBalance": 1000
    }
    ```

    That completes the basic endpoints.  In the next task, you can add some additional endpoints if you wish.  If you prefer, you can skip that task because you have the option to deploy the fully pre-built service in a later module (Deploy the full CloudBank Application) if you choose.

