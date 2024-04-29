package com.example.journalapp.service;

import com.example.journalapp.model.Journal;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@Slf4j
public class JournalClient implements JournalService {

    private final JdbcClient jdbcClient;

    public JournalClient(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    @Override
    public List<Journal> getAllJournals() {
        return List.of();
    }

    @Override
    public Journal getJournalById(Long id) {
        return null;
    }

    @Override
    public int saveJournal(Journal journal) {
        log.info("Saving journal {}", journal);
        var newJournal = jdbcClient.sql("insert into journal(tagId, licensePlate, vehicleType, date)")
                .params(List.of(journal.tagId(), journal.licensePlate(), journal.date()))
                .update();
        return newJournal;
    }

    @Override
    public void deleteJournalById(Long id) {

    }
}
