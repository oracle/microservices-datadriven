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


    //create table if not exists journal (
//        journal_id varchar2(128) not null,
//tag_id varchar2(64),
//license_plate varchar2(10),
//vehicle_type varchar2(10),
//toll_date date
//);

    @Override
    public int saveJournal(Journal journal) {
        log.info("Saving journal {}", journal);
        var newJournal = jdbcClient.sql("insert into journal(journal_id, tag_id, license_plate, vehicle_type, toll_date)")
                .params(List.of(journal.journalId(), journal.tagId(), journal.licensePlate(), journal.vehicleType(), journal.tollDate()))
                .update();
        return newJournal;
    }

    @Override
    public void deleteJournalById(Long id) {

    }
}
