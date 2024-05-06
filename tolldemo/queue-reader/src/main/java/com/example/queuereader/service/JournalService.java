// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.service;

import org.springframework.stereotype.Service;

import com.example.queuereader.client.JournalClient;
//import lombok.RequiredArgsConstructor;
import com.fasterxml.jackson.databind.JsonNode;

import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.Timer;
import io.micrometer.prometheus.PrometheusMeterRegistry;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class JournalService {

    private Timer timer;

    public JournalService(PrometheusMeterRegistry registry, JournalClient journalClient) {
        this.journalClient = journalClient;
        timer = registry.timer("journal", Tags.empty());
    }
 
    private final JournalClient journalClient;

    public void journal(JsonNode tollData) {
        Timer.Sample sample = Timer.start();
        log.info("Journal data: {}", tollData);
        journalClient.journal(tollData);
        timer.record(() -> sample.stop(timer) / 1_000);

    }
}
