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