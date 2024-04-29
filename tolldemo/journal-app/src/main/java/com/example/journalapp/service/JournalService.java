package com.example.journalapp.service;

import com.example.journalapp.model.JournalJDBC;

import java.util.List;

public interface JournalService {

    List<JournalJDBC> getAllJournals();
    JournalJDBC getJournalById(Long id);
    int saveJournal(JournalJDBC journal);
    void deleteJournalById(Long id);

}
