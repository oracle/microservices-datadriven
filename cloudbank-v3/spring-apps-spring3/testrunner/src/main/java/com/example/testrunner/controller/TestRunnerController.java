// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.testrunner.controller;

import com.example.testrunner.model.CheckDeposit;
import com.example.testrunner.model.Clearance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/testrunner")
public class TestRunnerController {

    @Autowired
    private JmsTemplate jmsTemplate;

    @PostMapping("/deposit")
    public ResponseEntity<CheckDeposit> depositCheck(@RequestBody CheckDeposit deposit) {
        jmsTemplate.convertAndSend("deposits", deposit);
        return new ResponseEntity<CheckDeposit>(deposit, HttpStatus.CREATED);
    }

    @PostMapping("/clear")
    public ResponseEntity<Clearance> clearCheck(@RequestBody Clearance clearance) {
        jmsTemplate.convertAndSend("clearances", clearance);
        return new ResponseEntity<Clearance>(clearance, HttpStatus.CREATED);
    }
}