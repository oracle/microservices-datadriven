+++
archetype = "page"
title = "Create the Deposit service"
weight = 5
+++


The Deposit service will process deposits into bank accounts.  In this task, you will create the basic structure for this service and learn about the endpoints required for an LRA participant, what HTTP Methods they process, the annotations used to define them and so on.  You will implement the actual business logic in a later task.

1. Create the Deposit service and scaffold methods

   Create a new directory in `src/main/java/com/example/accounts` called `services` and in that directory create a new Java file called `DepositService.java`.  This will be a Spring Boot component where you will implement the deposit operations.  Since the LRA library we are using only works with JAX-RS, you will be using JAX-RS annotations in this service, as opposed to the Spring Boot "web" REST annotations that you used in the previous module.  You can mix and match these styles in a single Spring Boot microservice application.

   Start by setting up endpoints and methods with the appropriate annotations.  You will implement the logic for each of these methods shortly.  Here is the class definition and all the imports you will need in this section, plus the logger and a constant `DEPOSIT` you will use later.  Notice that the class has the `@RequestScoped` annotation which tells Spring to create an instance of this class for each HTTP request (as opposed to for a whole session for example), the Spring Boot `@Component` annotation which marks this class as a bean that Spring can inject as a dependency when needed, and the `@Path` annotation to set the URL path for these endpoints.

    ```java
    package com.example.accounts.services;

    import com.example.accounts.model.Account;
    import com.example.accounts.model.Journal;

    import lombok.extern.slf4j.Slf4j;

    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RestController;

    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_CONTEXT_HEADER;
    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_ENDED_CONTEXT_HEADER;
    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_PARENT_CONTEXT_HEADER;

    @RestController
    @RequestMapping("/deposit")
    @Slf4j
    public class DepositService {

      private final static String DEPOSIT = "DEPOSIT";
    }
    ```

1. Create the LRA entry point

   The first method you need will be the main entry point, the `deposit()` method.  This will have the `@POST` annotation so that it will respond to the HTTP POST method. And, it has the `@LRA` annotation.

   In the `@LRA` annotation, which marks this as an LRA participant, the `value` property is set to `LRA.Type.MANDATORY` which means that this method will refuse to perform any work unless it is part of an LRA. The `end` property is set to `false` which means that successful completion of this method does not in and of itself constitute successful completion of the LRA, in other words, this method expects that it will not be the only participant in the LRA.

   The LRA coordinator will pass the LRA ID to this method (and any other participants) in an HTTP header.  Notice that the first argument of the method extracts that header and maps it to `lraId`. The other two arguments are mapped to HTTP Query parameters which identify the account and amount to deposit.  For now, this method will just return a response with the HTTP Status Code set to 200 (OK). You will implement the actual business logic shortly.

    ```java
    
    /**
     * Write journal entry re deposit amount.
     * Do not increase actual bank account amount
     */
    @PostMapping
    @LRA(value = LRA.Type.MANDATORY, end = false)
    public ResponseEntity<String> deposit(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
            @RequestParam("accountId") long accountId,
            @RequestParam("amount") long depositAmount) {

        log.info("...deposit " + depositAmount + " in account:" + accountId
                + " (lraId:" + lraId + ") finished (in pending state)");

        return null;
    }
    
    ```

1. Create the LRA complete endpoint

   Each LRA participant needs a "complete" endpoint.  This `completeWork` method implements that endpoint, as declared by the `@Complete` annotation. Note that this response to the HTTP PUT method and extracts the `lraId` from an HTTP header as in the previous method.

    ```java
    
    /**
     * Increase balance amount as recorded in journal during deposit call.
     * Update LRA state to ParticipantStatus.Completed.
     */
    @PutMapping("/complete")
    @Complete
    public ResponseEntity<String> completeWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {

        log.info("deposit complete called for LRA : " + lraId);

        return null;
    }
    
    ```

1. Create the LRA compensate endpoint

   Next, you need a compensation endpoint.  This `compensateWork` method is similar to the previous methods and is marked with the `@Compensate` annotation to mark it as the compensation handler for this participant. Note that this response to the HTTP PUT method and extracts the `lraId` from an HTTP header as in the previous method.

    ```java
    
    /**
     * Update LRA state to ParticipantStatus.Compensated.
     */
    @PutMapping("/compensate")
    @Compensate
    public ResponseEntity<String> compensateWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId)
            throws Exception {

        log.info("deposit compensate called for LRA : " + lraId);

        return null;
    }
    
    ```

1. Create the LRA status endpoint

   Next, you need to provide a status endpoint. This must respond to the HTTP GET method and extracts the `lraId` from an HTTP header as in the previous method. You can ignore the error `AccountTransferDAO` for now, we build that class in the next section.

    ```java
    
    /**
     * Return status.
     */
    @GetMapping(value = "/status", produces = "text/plain")
    @Status
    public ResponseEntity<ParticipantStatus> status(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
            @RequestHeader(LRA_HTTP_PARENT_CONTEXT_HEADER) String parentLRA) throws Exception {

        log.info("status called for LRA : " + lraId);
        
        return AccountTransferDAO.instance().status(lraId, DEPOSIT);
    }
    
    ```

1. Create the "after" LRA endpoint

   Finally, you need an "after LRA" endpoint that implements any clean up logic that needs to be run after the completion of the LRA. This method is called regardless of the outcome of the LRA and must respond to the HTTP PUT method and is marked with the `@AfterLRA` annotation. 

    ```java
    
    /**
     * Delete journal entry for LRA.
     */
    @PutMapping(value = "/after", consumes = "text/plain")
    @AfterLRA
    public ResponseEntity<String> afterLRA(@RequestHeader(LRA_HTTP_ENDED_CONTEXT_HEADER) String lraId,
            String status) throws Exception {

        log.info("After LRA Called : " + lraId);

        AccountTransferDAO.instance().afterLRA(lraId, status, DEPOSIT);
        return ResponseEntity.ok("");
    }
    
    ```
