package com.example.journalapp.repository;

import com.example.journalapp.model.Journal;
//import com.example.journalapp.model.JournalJDBC;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JournalRepository extends JpaRepository<Journal, Long> {
}
