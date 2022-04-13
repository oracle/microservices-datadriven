package com.cloudbank.springboot.accounts;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public interface AccountService {

    /**
     *
     * @return
     */
    Map<String, Object> getUserAndExternalAccounts();

    /**
     *
     * @return
     */
    List<Object> getUserAccounts();

    /**
     *
     * @param accountId
     * @return
     */
    Object getUserAccount(String accountId);
}
