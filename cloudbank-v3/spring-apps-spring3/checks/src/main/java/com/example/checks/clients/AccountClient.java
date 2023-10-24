// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.checks.clients;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

// @FeignClient("accounts")
@FeignClient("account")
public interface AccountClient {

    @PostMapping("/api/v1/account/journal")
    void journal(@RequestBody Journal journal);

    @PostMapping("/api/v1/account/journal/{journalId}/clear")
    void clear(@PathVariable long journalId);

}