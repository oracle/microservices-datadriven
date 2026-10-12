// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import java.util.List;
import java.util.UUID;

import com.oracle.demo.lab.messaging.TicketEventProducer;
import com.oracle.demo.lab.model.FailedTicketEvent;
import com.oracle.demo.lab.persistence.TicketEventOutcomeStore;
import com.oracle.demo.lab.model.TicketWorkEvent;
import com.oracle.demo.lab.model.SupportTicket;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@Profile("events")
public class EventsController {

    private final TicketEventProducer ticketEventProducer;
    private final TicketEventOutcomeStore outcomeStore;

    public EventsController(TicketEventProducer ticketEventProducer,
                            TicketEventOutcomeStore outcomeStore) {
        this.ticketEventProducer = ticketEventProducer;
        this.outcomeStore = outcomeStore;
    }

    @PostMapping("/tickets")
    public SupportTicket createTicket(@RequestBody SupportTicket ticket,
                                      @RequestHeader(name = "X-Correlation-ID", required = false) UUID correlationId) {
        ticketEventProducer.produce(ticket, correlationId);
        return ticket;
    }

    @GetMapping("/ticket-events/failures")
    public List<FailedTicketEvent> getFailedEvents() {
        return outcomeStore.findFailed();
    }

    @PostMapping("/ticket-events/failures/{eventId}/replay")
    public ResponseEntity<TicketWorkEvent> replay(@PathVariable UUID eventId) {
        try {
            return ResponseEntity.accepted().body(ticketEventProducer.replay(eventId));
        } catch (TicketEventProducer.FailedEventNotFoundException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
        } catch (IllegalStateException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        }
    }
}
