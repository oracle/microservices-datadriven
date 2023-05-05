// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.creditscore.controller;

import org.springframework.web.bind.annotation.*;

import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class CreditScoreController {

    @GetMapping("/creditscore")
    public Map<String, String> sayHello() {
        int max = 900;
        int min = 500;
        SecureRandom secureRandom = new SecureRandom();
        HashMap<String, String> map = new HashMap<>();
        map.put("Credit Score", String.valueOf(secureRandom.nextInt(max - min) + min));
        map.put("Date", String.valueOf(java.time.LocalDate.now()));
        return map;
    }
}