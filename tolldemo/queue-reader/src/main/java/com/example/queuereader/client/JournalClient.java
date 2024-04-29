package com.example.queuereader.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient("")
public class JournalClient {
//    @PostMapping("/api/v1/journal")
//    void journal(@RequestBody Journal journal);
}
