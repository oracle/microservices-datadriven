package com.example.journalapp.controller;

import com.example.journalapp.model.Journal;
import com.example.journalapp.service.JournalService;
import lombok.extern.slf4j.Slf4j;
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

    private final JournalService journalService;

    public JournalController(JournalService journalService) {
        this.journalService = journalService;
    }

//    curl -i POST http://localhost:8080/api/v1/journal -H 'Content-Type: application/json' \
//    -d '{"tagId": "tagid", "licensePlate": "licplate", "vehicleType": "vtype", "date": "date"}'
    @PostMapping("/journal")
    ResponseEntity<?> createJournal(@RequestBody Journal journal) {
        log.info("Creating journal {}", journal);
        var retValue = journalService.saveJournal(journal);
        if (retValue == 1) {
            URI location = ServletUriComponentsBuilder
                    .fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(journal.journalId())
                    .toUri();
            log.info("Successfully created journal {}", location);
            return ResponseEntity.created(location).build();
        } else {
            return ResponseEntity.noContent().build();
        }
    }
}
