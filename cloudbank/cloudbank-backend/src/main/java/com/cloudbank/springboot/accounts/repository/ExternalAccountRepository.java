package com.cloudbank.springboot.accounts.repository;

import com.cloudbank.springboot.accounts.dto.ExternalAccountDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.transaction.Transactional;
import java.util.List;

@EnableJpaRepositories
@Repository
@Transactional
@EnableTransactionManagement
public interface ExternalAccountRepository extends JpaRepository<ExternalAccountDTO, String> {

    List<ExternalAccountDTO> findAllByActivated(int activated);

}
