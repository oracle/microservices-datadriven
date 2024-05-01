// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.service;

import com.example.queuereader.client.JournalClient;
//import lombok.RequiredArgsConstructor;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class JournalService {

    private final JournalClient journalClient;

    public void journal(JsonNode tollData) {
        log.info("Journal data: {}", tollData);
        journalClient.journal(tollData);
    }
}
