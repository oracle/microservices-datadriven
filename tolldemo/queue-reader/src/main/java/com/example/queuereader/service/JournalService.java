// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.JournalClient;
//import lombok.RequiredArgsConstructor;
import com.fasterxml.jackson.databind.JsonNode;

import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class JournalService {

    public JournalService(MeterRegistry registry, JournalClient journalClient) {
        this.journalClient = journalClient;
        registry.timer("journal", Tags.empty());
    }
 
    private final JournalClient journalClient;

    @Timed(value = "journal")
    public void journal(JsonNode tollData) {
        log.info("Journal data: {}", tollData);
        journalClient.journal(tollData);
    }
}
