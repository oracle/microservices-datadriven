+++
archetype = "page"
title = "Implement business logic"
weight = 7
+++

In this secion, you will implement the deposit service's business logic.

The deposit service will be responsible for depositing funds into accounts. It will be an LRA participant, and so it will need to implement the LRA lifecycle actions like complete, compensate, and so on. A significant amount of the logic will be shared with the withdrawal service, so you will also create a separate class for that shared logic, following the Data Access Object pattern, to keep the business layer separate from the persistence layer.

1. Implement the business logic for the **deposit** method.

  This method should write a journal entry for the deposit, but should not update the account balance.  Here is the code for this method:

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
        Account account = AccountTransferDAO.instance().getAccountForAccountId(accountId);
        if (account == null) {
          log.info("deposit failed: account does not exist");
          AccountTransferDAO.instance().saveJournal(
            new Journal(
                DEPOSIT, 
                accountId, 
                0, 
                lraId,
                AccountTransferDAO.getStatusString(ParticipantStatus.Active)
            )
          );
          return ResponseEntity.ok("deposit failed: account does not exist");
        }
        AccountTransferDAO.instance().saveJournal(
          new Journal(
              DEPOSIT, 
              accountId, 
              depositAmount, 
              lraId,
              AccountTransferDAO.getStatusString(ParticipantStatus.Active)
          )
        );
        return ResponseEntity.ok("deposit succeeded");
    }
    
    ```

1. Implement the **complete** method

  This method should update the LRA status to **completing**, update the account balance, change the bank transaction (journal entry) status from pending to completed and the set the LRA status too **completed**.  Here is the code for this method:

    ```java
    
    /**
     * Increase balance amount as recorded in journal during deposit call.
     * Update LRA state to ParticipantStatus.Completed.
     */
    @PutMapping("/complete")
    @Complete
    public ResponseEntity<String> completeWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {
        log.info("deposit complete called for LRA : " + lraId);
    
        // get the journal and account...
        Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, DEPOSIT);
        Account account = AccountTransferDAO.instance().getAccountForJournal(journal);
    
        // set this LRA participant's status to completing...
        journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Completing));
    
        // update the account balance and journal entry...
        account.setAccountBalance(account.getAccountBalance() + journal.getJournalAmount());
        AccountTransferDAO.instance().saveAccount(account);
        journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Completed));
        AccountTransferDAO.instance().saveJournal(journal);
    
        // set this LRA participant's status to complete...
        return ResponseEntity.ok(ParticipantStatus.Completed.name());
    }
    ```  

1. Implement the **compensate** method

  This method should update both the deposit record in the journal and the LRA status too **compensated**.  Here is the code for this method:

    ```java
    
    /**
     * Update LRA state to ParticipantStatus.Compensated.
     */
    @PutMapping("/compensate")
    @Compensate
    public ResponseEntity<String> compensateWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) 
        throws Exception {
        log.info("deposit compensate called for LRA : " + lraId);

        Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, DEPOSIT);
        journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Compensated));
        AccountTransferDAO.instance().saveJournal(journal);
        return ResponseEntity.ok(ParticipantStatus.Compensated.name());
    }
    ```

1. Implement the **status** method

  This method returns the LRA status.  Here is the code for this method:

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

1. Implement the **after LRA** method

  This method should perform any steps necessary to finalize or clean up after the LRA.  In this case, all you need to do is update the status of the deposit entry in the journal.  Here is the code for this method:

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

   That completes the implementation of the deposit service.

