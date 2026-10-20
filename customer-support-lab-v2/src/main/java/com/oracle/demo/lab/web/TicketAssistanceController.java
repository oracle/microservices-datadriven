// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import com.oracle.demo.lab.ai.TicketAssistance;
import com.oracle.demo.lab.ai.TicketAssistanceStore;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class TicketAssistanceController {
    private final TicketAssistanceStore assistanceStore;

    public TicketAssistanceController(TicketAssistanceStore assistanceStore) {
        this.assistanceStore = assistanceStore;
    }

    @GetMapping("/tickets/{id}/assistance")
    public TicketAssistance getAssistance(@PathVariable long id) {
        return assistanceStore.findByTicketId(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Ticket assistance is not available yet"));
    }
}
