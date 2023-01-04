// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.slow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
import org.springframework.cloud.netflix.hystrix.EnableHystrix;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.netflix.hystrix.contrib.javanica.annotation.HystrixProperty;
import com.netflix.hystrix.contrib.javanica.annotation.HystrixCommand;

@SpringBootApplication
@EnableEurekaClient
@RestController
@EnableHystrix
public class SlowApplication {

    
    public static void main(String[] args) {
        SpringApplication.run(SlowApplication.class, args);
    }

    @RequestMapping(value = "/fruit")
    @HystrixCommand(fallbackMethod = "fallbackFruit", commandProperties = {
        @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "1000")
     })
     public String whatFruit() {
        try {
            Thread.sleep(Math.round(Math.random() * 3000));
        } catch (InterruptedException ignore) {};
        return "banana";
    }

    public String fallbackFruit() {
        return "fallback fruit is apple";
    }
}
