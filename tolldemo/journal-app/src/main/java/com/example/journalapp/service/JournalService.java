package com.example.journalapp.service;

import com.example.journalapp.model.Journal;

import java.util.List;

public interface JournalService {

    List<Journal> getAllJournals();
    Journal getJournalById(Long id);
    int saveJournal(Journal journal);
    void deleteJournalById(Long id);

}
