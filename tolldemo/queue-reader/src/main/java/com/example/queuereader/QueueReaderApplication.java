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
