// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.journalapp.controller;

import com.example.journalapp.model.Journal;
import com.example.journalapp.repository.JournalRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@Slf4j
@RequestMapping("api/v1")
public class JournalController {

    final JournalRepository journalRepository;

    public JournalController(JournalRepository journalRepository) {
        this.journalRepository = journalRepository;
    }

    // http POST :8080/api/v1/journal tagId=tagid accountNumber=acctnum licensePlate=licplate vehicleType=vtype tollDate=tdate tollCost=1
    @PostMapping("/journal")
    public ResponseEntity<Journal> createAccount(@RequestBody Journal journal) {
        log.info("Creating journal {}", journal);
        try {
            Journal newJournal = journalRepository.saveAndFlush(journal);
            URI location = ServletUriComponentsBuilder
                    .fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(newJournal.getJournalId())
                    .toUri();
            log.info("Successfully created journal {}", location);
            return ResponseEntity.created(location).build();
        } catch (Exception e) {
            return new ResponseEntity<>(journal, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
