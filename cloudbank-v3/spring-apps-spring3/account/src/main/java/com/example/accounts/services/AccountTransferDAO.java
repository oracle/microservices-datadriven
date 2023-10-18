// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

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
@Slf4j
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
        System.out.println("AccountTransferDAO accountsRepository = " + accountRepository 
            + ", journalRepository = " + journalRepository);
    }

    public static AccountTransferDAO instance() {
        return singleton;
    }

    /**
     * Get status od LRA participant.
     * @param status Status code
     * @return Returns status code
     */
    public static String getStatusString(ParticipantStatus status) {
        switch (status) {
            case Compensated:
                return "Compensated";
            case Completed:
                return "Completed";
            case FailedToCompensate:
                return "Failed to Compensate";
            case FailedToComplete:
                return "Failed to Complete";
            case Active:
                return "Active";
            case Compensating:
                return "Compensating";
            case Completing:
                return "Completing";
            default:
                return "Unknown";
        }
    }

    /**
     * Get LRA Status from a string.
     * @param statusString Status
     * @return Participant Status
     */
    public static ParticipantStatus getStatusFromString(String statusString) {
        switch (statusString) {
            case "Compensated":
                return ParticipantStatus.Compensated;
            case "Completed":
                return ParticipantStatus.Completed;
            case "Failed to Compensate":
                return ParticipantStatus.FailedToCompensate;
            case "Failed to Complete":
                return ParticipantStatus.FailedToComplete;
            case "Active":
                return ParticipantStatus.Active;
            case "Compensating":
                return ParticipantStatus.Compensating;
            case "Completing":
                return ParticipantStatus.Completing;
            default:
                return null;
        }
    }

    public void saveAccount(Account account) {
        log.info("saveAccount account" + account.getAccountId() + " account" + account.getAccountBalance());
        accountRepository.save(account);
    }

    /**
     * TO-DO.
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

    /**
     * Set status for a Journal Entry.
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

    Account getAccountForJournal(Journal journal) throws Exception {
        Account account = accountRepository.findByAccountId(journal.getAccountId());
        if (account == null) {
            throw new Exception("Invalid accountName:" + journal.getAccountId());
        }
        return account;
    }

    Account getAccountForAccountId(long accountId) {
        Account account = accountRepository.findByAccountId(accountId);
        if (account == null) {
            return null;
        }
        return account;
    }

    Journal getJournalForLRAid(String lraId, String journalType) throws Exception {
        Journal journal = journalRepository.findJournalByLraIdAndJournalType(lraId, journalType);
        if (journal == null) {
            journalRepository.save(new Journal("unknown", -1, 0, lraId,
                    AccountTransferDAO.getStatusString(ParticipantStatus.FailedToComplete)));
            throw new Exception("Journal entry does not exist for lraId:" + lraId);
        }
        return journal;
    }

    public void saveJournal(Journal journal) {
        journalRepository.save(journal);
    }

}