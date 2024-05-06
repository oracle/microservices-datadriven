// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader.client;

import com.fasterxml.jackson.databind.JsonNode;

import io.micrometer.core.annotation.Timed;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "journal", url = "http://journal-app:8080")
public interface JournalClient {

    @PostMapping("/api/v1/journal")
    void journal(@RequestBody JsonNode tollData);
}
