package com.cloudbank.springboot.accounts;

import com.cloudbank.springboot.accounts.dto.ExternalAccountDTO;
import com.cloudbank.springboot.accounts.repository.AccountRepository;
import com.cloudbank.springboot.accounts.repository.ExternalAccountRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AccountServiceImpl implements AccountService {

    Logger logger = LoggerFactory.getLogger(AccountServiceImpl.class);

    @Autowired
    private ExternalAccountRepository externalAccountRepository;

    @Autowired
    private AccountRepository accountRepository;

    @Override
    public Map<String, Object> getUserAndExternalAccounts() {

        Map<String, Object> response = new HashMap<>();
        try {
            List<Object> userAccounts = new ArrayList<>(accountRepository.findAll());
            response.put("sources", userAccounts);

        } catch (Exception e) {
            logger.error(e.getMessage());
            response.put("sources", new ArrayList<>());
        }

        try {
            List<ExternalAccountDTO> externalAccounts = externalAccountRepository.findAllByActivated(1);
            response.put("destinations", externalAccounts);
        } catch (Exception e) {
            logger.error(e.getMessage());
            response.put("destinations", new ArrayList<>());
        }
        return response;
    }

    @Override
    public List<Object> getUserAccounts() {
        try {
            List<Object> response = new ArrayList<>(accountRepository.findAll());
            logger.debug("{} accounts retrieved.", response.size());
            return response;
        } catch (Exception e) {
            logger.error(e.getMessage());
        }
        return null;
    }

    @Override
    public Object getUserAccount(String accountId) {
        try {
            return accountRepository.findById(accountId);
        } catch (Exception e) {
            logger.error(e.getMessage());
        }
        return null;
    }
}
