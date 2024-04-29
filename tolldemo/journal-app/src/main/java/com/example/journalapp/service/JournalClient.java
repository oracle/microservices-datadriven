package com.example.journalapp.service;

import com.example.journalapp.model.JournalJDBC;
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
    public List<JournalJDBC> getAllJournals() {
        return List.of();
    }

    @Override
    public JournalJDBC getJournalById(Long id) {
        return null;
    }

    @Override
    public int saveJournal(JournalJDBC journal) {
        log.info("Saving journal {}", journal);
        var newJournal = jdbcClient.sql("insert into journal(journal_id, tag_id, license_plate, vehicle_type, toll_date)")
                .params("3", "3", "3", "3", "3")
                // .params(List.of(journal.journalId(), journal.tagId(), journal.licensePlate(), journal.vehicleType(), journal.tollDate()))
                .update();
        return newJournal;
    }

    @Override
    public void deleteJournalById(Long id) {

    }
}
