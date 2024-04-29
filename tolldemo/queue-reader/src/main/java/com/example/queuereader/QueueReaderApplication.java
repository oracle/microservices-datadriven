package com.example.queuereader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jms.annotation.EnableJms;

@EnableJms
@SpringBootApplication
public class QueueReaderApplication {

    public static void main(String[] args) {
        SpringApplication.run(QueueReaderApplication.class, args);
    }

}
