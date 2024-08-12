+++
archetype = "page"
title = "Create the Withdrawal service"
weight = 8
+++


Next, you need to implement the withdraw service, which will be the second participant in the transfer LRA.

1. Implement the **withdraw** service

  Create a new Java file called `WithdrawService.java` in `src/main/java/com/example/accounts/services`. This service is very similar to the deposit service, and no new concepts are introduced here. Here is the code for this service:

    ```java
    
    package com.example.accounts.services;

    import com.example.accounts.model.Account;
    import com.example.accounts.model.Journal;
    import com.oracle.microtx.springboot.lra.annotation.AfterLRA;
    import com.oracle.microtx.springboot.lra.annotation.Compensate;
    import com.oracle.microtx.springboot.lra.annotation.Complete;
    import com.oracle.microtx.springboot.lra.annotation.LRA;
    import com.oracle.microtx.springboot.lra.annotation.ParticipantStatus;
    import com.oracle.microtx.springboot.lra.annotation.Status;
    import lombok.extern.slf4j.Slf4j;
    import org.springframework.http.ResponseEntity;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.PutMapping;
    import org.springframework.web.bind.annotation.RequestHeader;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RequestParam;
    import org.springframework.web.bind.annotation.RestController;

    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_CONTEXT_HEADER;
    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_ENDED_CONTEXT_HEADER;
    import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_PARENT_CONTEXT_HEADER;


    @RestController
    @RequestMapping("/withdraw")
    @Slf4j
    public class WithdrawService {

        public static final String WITHDRAW = "WITHDRAW";

        /**
        * Reduce account balance by given amount and write journal entry re the same.
        * Both actions in same local tx
        */
        @PostMapping
        @LRA(value = LRA.Type.MANDATORY, end = false)
        public ResponseEntity<String> withdraw(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
                @RequestParam("accountId") long accountId,
                @RequestParam("amount") long withdrawAmount) {
            log.info("withdraw " + withdrawAmount + " in account:" + accountId + " (lraId:" + lraId + ")...");
            Account account = AccountTransferDAO.instance().getAccountForAccountId(accountId);
            if (account == null) {
                log.info("withdraw failed: account does not exist");
                AccountTransferDAO.instance().saveJournal(
                        new Journal(
                                WITHDRAW,
                                accountId,
                                0,
                                lraId,
                                AccountTransferDAO.getStatusString(ParticipantStatus.Active)));
                return ResponseEntity.ok("withdraw failed: account does not exist");
            }
            if (account.getAccountBalance() < withdrawAmount) {
                log.info("withdraw failed: insufficient funds");
                AccountTransferDAO.instance().saveJournal(
                        new Journal(
                                WITHDRAW,
                                accountId,
                                0,
                                lraId,
                                AccountTransferDAO.getStatusString(ParticipantStatus.Active)));
                return ResponseEntity.ok("withdraw failed: insufficient funds");
            }
            log.info("withdraw current balance:" + account.getAccountBalance() 
                + " new balance:" + (account.getAccountBalance() - withdrawAmount));
            account.setAccountBalance(account.getAccountBalance() - withdrawAmount);
            AccountTransferDAO.instance().saveAccount(account);
            AccountTransferDAO.instance().saveJournal(
                    new Journal(
                            WITHDRAW,
                            accountId,
                            withdrawAmount,
                            lraId,
                            AccountTransferDAO.getStatusString(ParticipantStatus.Active)));
            return ResponseEntity.ok("withdraw succeeded");
        }

        /**
        * Update LRA state. Do nothing else.
        */
        @PutMapping("/complete")
        @Complete
        public ResponseEntity<String> completeWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {
            log.info("withdraw complete called for LRA : " + lraId);
            Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, WITHDRAW);
            journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Completed));
            AccountTransferDAO.instance().saveJournal(journal);
            return ResponseEntity.ok(ParticipantStatus.Completed.name());
        }

        /**
        * Read the journal and increase the balance by the previous withdraw amount.
        * before the LRA
        */
        @PutMapping("/compensate")
        @Compensate
        public ResponseEntity<String> compensateWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) 
            throws Exception {
            log.info("Account withdraw compensate() called for LRA : " + lraId);
            Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, WITHDRAW);
            journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Compensating));
            Account account = AccountTransferDAO.instance().getAccountForAccountId(journal.getAccountId());
            if (account != null) {
                account.setAccountBalance(account.getAccountBalance() + journal.getJournalAmount());
                AccountTransferDAO.instance().saveAccount(account);
            }
            journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Compensated));
            AccountTransferDAO.instance().saveJournal(journal);
            return ResponseEntity.ok(ParticipantStatus.Compensated.name());
        }

        @Status
        public ResponseEntity<ParticipantStatus> status(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
                @RequestHeader(LRA_HTTP_PARENT_CONTEXT_HEADER) String parentLRA) throws Exception {
            return AccountTransferDAO.instance().status(lraId, WITHDRAW);
        }

        /**
        * Delete journal entry for LRA.
        */
        @PutMapping(value = "/after", consumes = "text/plain")
        @AfterLRA
        public ResponseEntity<String> afterLRA(@RequestHeader(LRA_HTTP_ENDED_CONTEXT_HEADER) String lraId, 
            String status) throws Exception {
            log.info("After LRA Called : " + lraId);
            AccountTransferDAO.instance().afterLRA(lraId, status, WITHDRAW);
            return ResponseEntity.ok("");
        }

    }
    ```  

   That completes the implementation of the deposit service, and with that you are also done with the modifications for the Account Spring Boot microservice application to allow it to participate int he LRA.  Next, you will create the Transfer Spring Boot microservice application.

