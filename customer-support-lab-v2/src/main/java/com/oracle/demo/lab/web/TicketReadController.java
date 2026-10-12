// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.web;

import com.oracle.demo.lab.model.SupportTicket;
import com.oracle.demo.lab.persistence.TicketReadRouter;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Profile("events")
public class TicketReadController {
    private final TicketReadRouter reads;

    public TicketReadController(TicketReadRouter reads) {
        this.reads = reads;
    }

    @GetMapping("/tickets")
    public ResponseEntity<List<SupportTicket>> getAllTickets(
            @RequestParam(name = "readPath", required = false) String readPath) {
        var result = reads.all(readPath);
        return ResponseEntity.ok().header("X-Read-Path", result.path()).body(result.value());
    }

    @GetMapping("/tickets/{id}")
    public ResponseEntity<SupportTicket> getTicket(@PathVariable long id,
            @RequestParam(name = "readPath", required = false) String readPath) {
        var result = reads.byId(id, readPath);
        return result.value()
                .map(ticket -> ResponseEntity.ok().header("X-Read-Path", result.path()).body(ticket))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .header("X-Read-Path", result.path()).build());
    }
}
