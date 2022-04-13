package com.cloudbank.springboot.accounts.repository;

import com.cloudbank.springboot.accounts.dto.AccountDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.transaction.Transactional;

@EnableJpaRepositories
@Repository
@Transactional
@EnableTransactionManagement
public interface AccountRepository extends JpaRepository<AccountDTO, String> { }
