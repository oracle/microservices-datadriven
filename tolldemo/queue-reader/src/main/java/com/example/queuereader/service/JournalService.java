package com.example.queuereader.service;

import com.example.queuereader.client.JournalClient;
//import lombok.RequiredArgsConstructor;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class JournalService {

    private final JournalClient journalClient;

    public void journal(JsonNode tollData) {
        journalClient.journal(tollData);
    }
}
