// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.queuereader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.jms.annotation.EnableJms;

@EnableJms
@SpringBootApplication
@EnableFeignClients
public class QueueReaderApplication {

    public static void main(String[] args) {
        SpringApplication.run(QueueReaderApplication.class, args);
    }

}
