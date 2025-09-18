package com.oracle.demo.lab.web;

import java.util.List;

import com.oracle.demo.lab.events.TicketEventProducer;
import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketStore;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@Profile("events")
public class EventsController {

    private final TicketEventProducer ticketEventProducer;
    private final TicketStore ticketStore;

    public EventsController(TicketEventProducer ticketEventProducer, TicketStore ticketStore) {
        this.ticketEventProducer = ticketEventProducer;
        this.ticketStore = ticketStore;
    }

    @GetMapping("/tickets")
    public List<SupportTicket> getAllTickets() {
        return ticketStore.getAllTickets();
    }

    @GetMapping("/tickets/{id}")
    public SupportTicket getTicket(@PathVariable long id) {
        return ticketStore.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @PostMapping("/tickets")
    public SupportTicket createTicket(@RequestBody SupportTicket ticket) {
        Long id = ticketEventProducer.produce(ticket);
        return ticketStore.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR));
    }

    @DeleteMapping("/tickets")
    public ResponseEntity<?> deleteAll() {
        ticketStore.deleteAll();
        return ResponseEntity.noContent().build();
    }
}
