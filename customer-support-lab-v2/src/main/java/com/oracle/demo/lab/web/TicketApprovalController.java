// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.oracle.demo.lab.web;

import com.oracle.demo.lab.model.TicketApproval;
import com.oracle.demo.lab.messaging.TicketReviewService;
import com.oracle.demo.lab.persistence.TicketApprovalStore;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
public class TicketApprovalController {
    private final TicketApprovalStore approvals;
    private final TicketReviewService reviews;

    public TicketApprovalController(TicketApprovalStore approvals, TicketReviewService reviews) {
        this.approvals = approvals;
        this.reviews = reviews;
    }

    @PostMapping("/tickets/{id}/approvals")
    public TicketApproval record(@PathVariable long id, @RequestBody TicketApproval.Request request) {
        try {
            return reviews.record(id, request);
        } catch (IllegalArgumentException error) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, error.getMessage());
        } catch (TicketApprovalStore.TicketNotFoundException error) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, error.getMessage());
        } catch (TicketApprovalStore.ApprovalConflictException error) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, error.getMessage());
        }
    }

    @GetMapping("/tickets/{id}/approvals")
    public List<TicketApproval> history(@PathVariable long id) {
        try {
            return approvals.history(id);
        } catch (TicketApprovalStore.TicketNotFoundException error) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, error.getMessage());
        }
    }
}
