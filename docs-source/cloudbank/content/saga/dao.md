+++
archetype = "page"
title = "Create a Data Access Object"
weight = 6
+++

The Data Access Object pattern is considered a best practice, and it allows separation of business logic from the persistence layer. In this task, you will create an Account Data Access Object (DAO) that hides the complexity of the persistence layer logic from the business layer services. Additionally, it establishes methods that can be reused by each business layer service that needs to operate on accounts - in this module there will be two such services - deposit and withdraw.

1. Create the DAO class

  Create a new Java file called `AccountTransferDAO.java` in `src/main/java/com/example/accounts/services`.  This class will contain common data access methods that are needed by multiple participants.  You will implement this class using the singleton pattern so that there will only be one instance of this class.

  Here is the code to set up the class and implement the singleton pattern:

    ```java
    package com.example.accounts.services;

    import com.example.accounts.model.Account;
    import com.example.accounts.model.Journal;
    import com.example.accounts.repository.AccountRepository;
    import com.example.accounts.repository.JournalRepository;
    import com.oracle.microtx.springboot.lra.annotation.ParticipantStatus;

    import lombok.extern.slf4j.Slf4j;

    import org.springframework.http.ResponseEntity;
    import org.springframework.stereotype.Component;

    @Component
    public class AccountTransferDAO {

        private static AccountTransferDAO singleton;
        final AccountRepository accountRepository;
        final JournalRepository journalRepository;

        /**
        * Initialize account and journal repository.
        * @param accountRepository Account Repository
        * @param journalRepository Journal Repository
        */
        public AccountTransferDAO(AccountRepository accountRepository, JournalRepository journalRepository) {
            this.accountRepository = accountRepository;
            this.journalRepository = journalRepository;
            singleton = this;
            log.info("AccountTransferDAO accountsRepository = " + accountRepository 
                + ", journalRepository = " + journalRepository);
        }

        public static AccountTransferDAO instance() {
            return singleton;
        }

    }
    ```

1. Create a method to get the LRA status as a String

  Create a `getStatusString` method which can be used to get a String representation of the LRA participant status.

    ```java
    /**
     * Get status od LRA participant.
     * @param status Status code
     * @return Returns status code
     */
    public static String getStatusString(ParticipantStatus status) {
        return switch (status) {
            case Compensated -> "Compensated";
            case Completed -> "Completed";
            case FailedToCompensate -> "Failed to Compensate";
            case FailedToComplete -> "Failed to Complete";
            case Active -> "Active";
            case Compensating -> "Compensating";
            case Completing -> "Completing";
            default -> "Unknown";
        };
    }
    ```

1. Create a method to get the LRA status from a String

  Create a `getStatusFromString` method to convert back from the String to the enum.

    ```java
    /**
     * Get LRA Status from a string.
     * @param statusString Status
     * @return Participant Status
     */
    public static ParticipantStatus getStatusFromString(String statusString) {
        return switch (statusString) {
            case "Compensated" -> ParticipantStatus.Compensated;
            case "Completed" -> ParticipantStatus.Completed;
            case "Failed to Compensate" -> ParticipantStatus.FailedToCompensate;
            case "Failed to Complete" -> ParticipantStatus.FailedToComplete;
            case "Active" -> ParticipantStatus.Active;
            case "Compensating" -> ParticipantStatus.Compensating;
            case "Completing" -> ParticipantStatus.Completing;
            default -> null;
        };
    }
    ```

1. Create a method to save an account

  Create a method to save an account in the account repository.

    ```java
    public void saveAccount(Account account) {
        log.info("saveAccount account" + account.getAccountId() + " account" + account.getAccountBalance());
        accountRepository.save(account);
    }
    ```

  Create a method to return the correct HTTP Status Code for an LRA status.

    ```java
    
    /**
     * Return the correct HTTP Status Code for an LRA status
     * @param lraId LRA Id
     * @param journalType Journal Type
     * @return Participant Status
     * @throws Exception Exception
     */
    public ResponseEntity<ParticipantStatus> status(String lraId, String journalType) throws Exception {
        Journal journal = getJournalForLRAid(lraId, journalType);
        if (AccountTransferDAO.getStatusFromString(journal.getLraState()).equals(ParticipantStatus.Compensated)) {
            return ResponseEntity.ok(ParticipantStatus.Compensated);
        } else {
            return ResponseEntity.ok(ParticipantStatus.Completed);
        }
    }
    
    ```

1. Create a method to update the LRA status in the journal

  Create a method to update the LRA status in the journal table during the "after LRA" phase.

    ```java
    /**
     * Update the LRA status in the journal table during the "after LRA" phase.
     * @param lraId LRA Id
     * @param status Status
     * @param journalType Journal Type
     * @throws Exception Exception
     */
    public void afterLRA(String lraId, String status, String journalType) throws Exception {
        Journal journal = getJournalForLRAid(lraId, journalType);
        journal.setLraState(status);
        journalRepository.save(journal);
    }
    ```

1. Create methods to manage accounts

  Create a method to get the account for a given account ID.

    ```java
    Account getAccountForAccountId(long accountId) {
        Account account = accountRepository.findByAccountId(accountId);
        if (account == null)
            return null;
        return account;
    }
    ```

  Create a method to get the account that is related to a journal entry.

    ```java
    Account getAccountForJournal(Journal journal) throws Exception {
        Account account = accountRepository.findByAccountId(journal.getAccountId());
        if (account == null) throw new Exception("Invalid accountName:" + journal.getAccountId());
        return account;
    }
    ```

  Update `AccountRepository.java` in `src/main/java/com/example/accounts/repositories` to add these extra JPA methods.  Your updated file should look like this:

    ```java
    package com.example.accounts.repository;

    import java.util.List;

    import org.springframework.data.jpa.repository.JpaRepository;

    import com.example.accounts.model.Account;

    public interface AccountRepository extends JpaRepository<Account, Long> {   
        List<Account> findByAccountCustomerId(String customerId); 
        List<Account> findAccountsByAccountNameContains (String accountName);
        Account findByAccountId(long accountId);
    }
    ```

1. Create methods to manage the journal

  Back in the `AccountTransferDAO`, create a method to get the journal entry for a given LRA.

    ```java
    
    Journal getJournalForLRAid(String lraId, String journalType) throws Exception {
        Journal journal = journalRepository.findJournalByLraIdAndJournalType(lraId, journalType);
        if (journal == null) {
            journalRepository.save(new Journal("unknown", -1, 0, lraId,
                    AccountTransferDAO.getStatusString(ParticipantStatus.FailedToComplete)));
            throw new Exception("Journal entry does not exist for lraId:" + lraId);
        }
        return journal;
    }
    ```

  Create a method to save a journal entry.

    ```java
    public void saveJournal(Journal journal) {
        journalRepository.save(journal);
    }
    
    ```

   This completes the Data Access Object, now you can start implementing the actual business logic for the services.

