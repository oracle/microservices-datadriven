// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts.services;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_ENDED_CONTEXT_HEADER;
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_PARENT_CONTEXT_HEADER;

import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import lombok.extern.slf4j.Slf4j;

import org.eclipse.microprofile.lra.annotation.AfterLRA;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
import org.eclipse.microprofile.lra.annotation.ParticipantStatus;
import org.eclipse.microprofile.lra.annotation.Status;
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;
import org.springframework.stereotype.Component;

import com.example.accounts.model.Account;
import com.example.accounts.model.Journal;

@RequestScoped
@Path("/deposit")
@Component
@Slf4j
public class DepositService {

    private final static String DEPOSIT = "DEPOSIT";

    /**
     * Write journal entry re deposit amount.
     * Do not increase actual bank account amount
     */
    @POST
    @Path("/deposit")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.MANDATORY, end = false)
    public Response deposit(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId,
                            @QueryParam("accountId") long accountId,
                            @QueryParam("amount") long depositAmount) {
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
            return Response.ok("deposit failed: account does not exist").build();
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
        return Response.ok("deposit succeeded").build();
    }

    /**
     * Increase balance amount as recorded in journal during deposit call.
     * Update LRA state to ParticipantStatus.Completed.
     */
    @PUT
    @Path("/complete")
    @Produces(MediaType.APPLICATION_JSON)
    @Complete
    public Response completeWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {
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
        return Response.ok(ParticipantStatus.Completed.name()).build();
    }

    /**
     * Update LRA state to ParticipantStatus.Compensated.
     */
    @PUT
    @Path("/compensate")
    @Produces(MediaType.APPLICATION_JSON)
    @Compensate
    public Response compensateWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) throws Exception {
        log.info("deposit compensate called for LRA : " + lraId);
        Journal journal = AccountTransferDAO.instance().getJournalForLRAid(lraId, DEPOSIT);
        journal.setLraState(AccountTransferDAO.getStatusString(ParticipantStatus.Compensated));
        AccountTransferDAO.instance().saveJournal(journal);
        return Response.ok(ParticipantStatus.Compensated.name()).build();
    }

    /**
     * Return status
     */
    @GET
    @Path("/status")
    @Produces(MediaType.TEXT_PLAIN)
    @Status
    public Response status(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId,
                           @HeaderParam(LRA_HTTP_PARENT_CONTEXT_HEADER) String parentLRA) throws Exception {
        return AccountTransferDAO.instance().status(lraId, DEPOSIT);
    }

    /**
     * Delete journal entry for LRA
     */
    @PUT
    @Path("/after")
    @AfterLRA
    @Consumes(MediaType.TEXT_PLAIN)
    public Response afterLRA(@HeaderParam(LRA_HTTP_ENDED_CONTEXT_HEADER) String lraId, String status) throws Exception {
        log.info("After LRA Called : " + lraId);
        AccountTransferDAO.instance().afterLRA(lraId, status, DEPOSIT);
        return Response.ok().build();
    }

}