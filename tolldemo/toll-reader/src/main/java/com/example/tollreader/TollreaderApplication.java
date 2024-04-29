package com.example.tollreader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jms.annotation.EnableJms;

@EnableJms
@SpringBootApplication
public class TollreaderApplication {

  public static void main(String[] args) {
    SpringApplication.run(TollreaderApplication.class, args);
  }

}
