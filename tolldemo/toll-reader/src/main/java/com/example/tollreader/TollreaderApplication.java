package com.example.tollreader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.event.EventListener;
import org.springframework.jms.annotation.EnableJms;

import com.example.tollreader.data.DataBean;

import lombok.extern.slf4j.Slf4j;

@EnableJms
@SpringBootApplication
@Slf4j
public class TollreaderApplication {

  private static ConfigurableApplicationContext context;

  public static void main(String[] args) {
    context = SpringApplication.run(TollreaderApplication.class, args);
    log.info("load the data...");
    DataBean dataBean = (DataBean) context.getBean("dataBean");
    dataBean.populateData();
  }

}
