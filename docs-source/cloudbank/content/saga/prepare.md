+++
archetype = "page"
title = "Prepare the Account service"
weight = 4
+++

You will update the Account service that you built in the previous module to add some new endpoints to perform deposits and withdrawals.  These new endpoints will be LRA participants.

1. Add new dependencies to the Maven POM

  Open the `pom.xml` in your `accounts` project and add these new dependency to the list. It will add support for the LRA client libraries.

    ```xml
      
      <dependency>
        <groupId>com.oracle.microtx.lra</groupId>
        <artifactId>microtx-lra-spring-boot-starter</artifactId>
        <version>23.4.2</version>
      </dependency>
      
      ```

1. Update the Spring Boot application configuration file

  Update your Account service's Spring Boot configuration file, `application.yaml` in `src/main/resources`. Add a new `lra` section with the URL for the LRA coordinator. The URL shown here is for the Oracle Transaction Manager for Microservices that was installed as part of the Oracle Backend for Spring Boot and Microservices. **Note**: This URL is from the point of view of a service running it the same Kubernetes cluster.  

    ```yaml
    
      microtx:
        lra:
          coordinator-url: ${MP_LRA_COORDINATOR_URL}
          propagation-active: true
          headers-propagation-prefix: "{x-b3-, oracle-tmm-, authorization, refresh-}"   
    
    ```  

1. Check the Journal repository and model

  Create a new Java file called Journal.java in src/main/com/example/accounts/model to define the model for the journal table. There are no new concepts in this class, so here is the code:

    ```java
    package com.example.accounts.model;

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

  Open the file called `JournalRepository.java` in `src/main/java/com/example/accounts/repository` and add one JPA method `findJournalByLraIdAndJournalType()` to the interface. Here is the code:

    ```java
    package com.example.accounts.repository;

    import java.util.List;

    import org.springframework.data.jpa.repository.JpaRepository;

    import com.example.accounts.model.Journal;

    public interface JournalRepository extends JpaRepository<Journal, Long> {
      List<Journal> findJournalByAccountId(long accountId);
        
      Journal findJournalByLraIdAndJournalType(String lraId, String journalType);
    }
    ```

  That completes the JPA configuration.
