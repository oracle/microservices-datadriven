+++
archetype = "page"
title = "Add Journal to the Account service"
weight = 3
+++

Starting with the account service that you built in the previous lab, you will the JPA model and repository for the journal and some new endpoints.

1. Create the Journal model

  Create a new Java file in `src/main/java/com/example/accounts/model` called `Journal.java`. In this class you can define the fields that make up the journal.  Note that you created the Journal table in the previous lab. You will not use the `lraId` and `lraState` fields until a later lab. To simplify this lab, create an additional constructor that defaults those fields to suitable values. Your new class should look like this:

    ```java
    package com.example.account.model;

    import jakarta.persistence.Column;
    import jakarta.persistence.Entity;
    import jakarta.persistence.GeneratedValue;
    import jakarta.persistence.GenerationType;
    import jakarta.persistence.Id;
    import jakarta.persistence.Table;

    import lombok.Data;
    import lombok.NoArgsConstructor;

    @Entity
    @Table(name = "JOURNAL")
    @Data
    @NoArgsConstructor
    public class Journal {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        @Column(name = "JOURNAL_ID")
        private long journalId;

        // type is withdraw or deposit
        @Column(name = "JOURNAL_TYPE")
        private String journalType;

        @Column(name = "ACCOUNT_ID")
        private long accountId;

        @Column(name = "LRA_ID")
        private String lraId;

        @Column(name = "LRA_STATE")
        private String lraState;

        @Column(name = "JOURNAL_AMOUNT")
        private long journalAmount;

        public Journal(String journalType, long accountId, long journalAmount) {
            this.journalType = journalType;
            this.accountId = accountId;
            this.journalAmount = journalAmount;
        }

        public Journal(String journalType, long accountId, long journalAmount, String lraId, String lraState) {
            this.journalType = journalType;
            this.accountId = accountId;
            this.lraId = lraId;
            this.lraState = lraState;
            this.journalAmount = journalAmount;
        }
    }
    ```

1. Create the Journal repository

  Create a new Java file in `src/main/java/com/example/account/repository` called `JournalRepository.java`. This should be an interface that extends `JpaRepository` and you will need to define a method to find journal entries by `accountId`. Your interface should look like this:

    ```java
    package com.example.account.repository;

    import java.util.List;

    import org.springframework.data.jpa.repository.JpaRepository;

    import com.example.account.model.Journal;

    public interface JournalRepository extends JpaRepository<Journal, Long> {
        List<Journal> findJournalByAccountId(long accountId);
    }
    ```

1. Update the `AccountController` constructor

  Update the constructor for `AccountController` so that both the repositories are injected.  You will need to create a variable to hold each.  Your updated constructor should look like this:

    ```java
    import com.example.repository.JournalRepository;
    
    // ...
    
    final AccountRepository accountRepository;
    final JournalRepository journalRepository;

    public AccountController(AccountRepository accountRepository, JournalRepository journalRepository) {
        this.accountRepository = accountRepository;
        this.journalRepository = journalRepository;
    }
    ```

1. Add new method to POST entries to the journal

  Add a new HTTP POST endpoint in the `AccountController.java` class. The method accepts a journal entry in the request body and saves it into the database. Your new method should look like this:

    ```java
    import com.example.model.Journal;
    
    // ...
    
    @PostMapping("/account/journal")
    public ResponseEntity<Journal> postSimpleJournalEntry(@RequestBody Journal journalEntry) {
        try {
            Journal _journalEntry = journalRepository.saveAndFlush(journalEntry);
            return new ResponseEntity<>(_journalEntry, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

1. Add new method to get journal entries

  Add a new HTTP GET endpoint in the `AccountController.java` class to get a list of journal entries for a given `accountId`. Your new method should look like this:

    ```java
    import com.example.account.repository.JournalRepository;

    @GetMapping("/account/{accountId}/journal")
    public List<Journal> getJournalEntriesForAccount(@PathVariable("accountId") long accountId) {
        return journalRepository.findJournalByAccountId(accountId);
    }
    ```

1. Add new method to update an existing journal entry

  Add a new HTTP POST endpoint to update and existing journal entry to a cleared deposit.  To do this, you set the `journalType` field to `DEPOSIT`.  Your method should accept the `journalId` as a path variable.  If the specified journal entry does not exist, return a 202 (Accepted) to indicate the message was received but there was nothing to do.  Returning a 404 (Not found) would cause an error and the message would get requeued and reprocessed, which we don't want.  Your new method should look like this:

    ```java
    @PostMapping("/account/journal/{journalId}/clear")
    public ResponseEntity<Journal> clearJournalEntry(@PathVariable long journalId) {
        try {
            Optional<Journal> data = journalRepository.findById(journalId);
            if (data.isPresent()) {
                Journal _journalEntry = data.get();
                _journalEntry.setJournalType("DEPOSIT");
                journalRepository.saveAndFlush(_journalEntry);
                return new ResponseEntity<Journal>(_journalEntry, HttpStatus.OK);
            } else {
                return new ResponseEntity<Journal>(new Journal(), HttpStatus.ACCEPTED);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```

1. Build a JAR file for deployment

  Run the following command to build the JAR file.  Note that you will need to skip tests now, since you updated the `application.yaml` and it no longer points to your local test database instance.

    ```shell
    $ mvn clean package -DskipTests
    ```

  The service is now ready to deploy to the backend.

1. Get the password for the `obaas-admin` user. The `obaas-admin` user is the equivalent of the admin or root user in the Oracle Backend for Spring Boot and Microservices backend.

  Execute the following command to get the password:

    ```shell
    $ kubectl get secret -n azn-server  oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

1. Prepare the backend for deployment

  The Oracle Backend for Spring Boot and Microservices admin service is not exposed outside the Kubernetes cluster by default. Oracle recommends using a **kubectl** port forwarding tunnel to establish a secure connection to the admin service.

  Start a tunnel (unless you already have the tunnel running from previous labs) using this command:

    ```shell
    $ kubectl -n obaas-admin port-forward svc/obaas-admin 8080
    ```

  Start the Oracle Backend for Spring Boot and Microservices CLI (*oractl*) using this command:

    ```shell
    $ oractl
     _   _           __    _    ___
    / \ |_)  _.  _. (_    /  |   |
    \_/ |_) (_| (_| __)   \_ |_ _|_
    ========================================================================================
      Application Name: Oracle Backend Platform :: Command Line Interface
      Application Version: (1.2.0)
      :: Spring Boot (v3.3.0) ::
      
      Ask for help:
      - Slack: https://oracledevs.slack.com/archives/C03ALDSV272 
      - email: obaas_ww@oracle.com

      oractl:>
    ```

  Connect to the Oracle Backend for Spring Boot and Microservices admin service using the `connect` command. Enter `obaas-admin` and the username and use the password you collected earlier.

    ```shell
    oractl:>connect
    ? username obaas-admin
    ? password *************
    Credentials successfully authenticated! obaas-admin -> welcome to OBaaS CLI.
    oractl:>
    ```

1. Deploy the account service

  You will now deploy your account service to the Oracle Backend for Spring Boot and Microservices using the CLI. Run this command to redeploy your service, make sure you provide the correct path to your JAR file. **Note** that this command may take 1-3 minutes to complete:

    ```shell
    oractl:> deploy --app-name application --service-name account --artifact-path /path/to/account-0.0.1-SNAPSHOT.jar --image-version 0.0.1
    uploading: account/target/account-0.0.1-SNAPSHOT.jarbuilding and pushing image...
    creating deployment and service... successfully deployed
    oractl:>
    ```

1. Verify the new endpoints in the account service

  In the next three commands, you need to provide the correct IP address for the API Gateway in your backend environment.  You can find the IP address using this command, you need the one listed in the **`EXTERNAL-IP`** column:

    ```shell
    $ kubectl -n ingress-nginx get service ingress-nginx-controller
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
    ```

  Test the create journal entry endpoint (make sure you use an `accountId` that exits in your database) with this command, use the IP address for your API Gateway.

    ```shell
    $ curl -i -X POST \
          -H 'Content-Type: application/json' \
          -d '{"journalType": "PENDING", "accountId": 2, "journalAmount": 100.00, "lraId": "0", "lraState": ""}' \
          http://[EXTERNAL-IP]/api/v1/account/journal
    HTTP/1.1 201
    Date: Wed, 31 May 2023 13:02:10 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"journalId":1,"journalType":"PENDING","accountId":2,"lraId":"0","lraState":"","journalAmount":100}
    ```

  Notice that the response contains a `journalId` which you will need in a later command, and that the `journalType` is `PENDING`.

  Test the get journal entries endpoint with this command, use the IP address for your API Gateway and the same `accountId` as in the previous step. Your output may be different:

    ```shell
    $ curl -i http://[EXTERNAL-IP]/api/v1/account/[accountId]/journal
    HTTP/1.1 200
    Date: Wed, 31 May 2023 13:03:22 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive
    [{"journalId":1,"journalType":"PENDING","accountId":2,"lraId":"0","lraState":null,"journalAmount":100}]
    ```

  Test the update/clear journal entry endpoint with this command, use the IP address for your API Gateway and the `journalId` from the first command's response:

    ```shell
    $ curl -i -X POST http://[EXTERNAL-IP]/api/v1/account/journal/[journalId]/clear
    HTTP/1.1 200
    Date: Wed, 31 May 2023 13:04:36 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"journalId":1,"journalType":"DEPOSIT","accountId":2,"lraId":"0","lraState":null,"journalAmount":100}
    ```

  That completes the updates for the Account service.

