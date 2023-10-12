// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts.services;

import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_CONTEXT_HEADER;
import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_ENDED_CONTEXT_HEADER;
import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_PARENT_CONTEXT_HEADER;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.accounts.model.Account;
import com.example.accounts.model.Journal;
import com.oracle.microtx.springboot.lra.annotation.AfterLRA;
import com.oracle.microtx.springboot.lra.annotation.Compensate;
import com.oracle.microtx.springboot.lra.annotation.Complete;
import com.oracle.microtx.springboot.lra.annotation.LRA;
import com.oracle.microtx.springboot.lra.annotation.ParticipantStatus;
import com.oracle.microtx.springboot.lra.annotation.Status;

import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/deposit")
@Slf4j
public class DepositService {

    private final static String DEPOSIT = "DEPOSIT";

    /**
     * Write journal entry re deposit amount.
     * Do not increase actual bank account amount
     */
    @PostMapping
    @LRA(value = LRA.Type.MANDATORY, end = false)
    public ResponseEntity<String> deposit(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
                            @RequestParam("accountId") long accountId,
                            @RequestParam("amount") long depositAmount) {
        log.info("...deposit " + depositAmount + " in account:" + accountId +
                " (lraId:" + lraId + ") finished (in pending state)");
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

    /**
     * Update LRA state to ParticipantStatus.Compensated.
     */
    @PutMapping("/compensate")
    @Compensate
    public ResponseEntity<String> compensateWork(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {
        log.info("deposit compensate called for LRA : " + lraId);
        Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, DEPOSIT);
        journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Compensated));
        AccountTransferDAO.instance().saveJournal(journal);
        return ResponseEntity.ok(ParticipantStatus.Compensated.name());
    }

    /**
     * Return status
     */
    @GetMapping(value = "/status", produces = "text/plain")
    @Status
    public ResponseEntity<ParticipantStatus> status(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId,
                           @RequestHeader(LRA_HTTP_PARENT_CONTEXT_HEADER) String parentLRA) throws Exception {
        return AccountTransferDAO.instance().status(lraId, DEPOSIT);
    }

    /**
     * Delete journal entry for LRA
     */
    @PutMapping(value = "/after", consumes = "text/plain")
    @AfterLRA
    public ResponseEntity<String> afterLRA(@RequestHeader(LRA_HTTP_ENDED_CONTEXT_HEADER) String lraId, String status) throws Exception {
        log.info("After LRA Called : " + lraId);
        AccountTransferDAO.instance().afterLRA(lraId, status, DEPOSIT);
        return ResponseEntity.ok("");
    }

}