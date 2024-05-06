// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.tollreader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.jms.annotation.EnableJms;
import com.example.tollreader.data.DataBean;
import lombok.extern.slf4j.Slf4j;

@EnableJms
@SpringBootApplication
@Slf4j
@EnableDiscoveryClient
public class TollreaderApplication {

  private static ConfigurableApplicationContext context;

  public static void main(String[] args) {
    context = SpringApplication.run(TollreaderApplication.class, args);
    log.info("load the data...");
    DataBean dataBean = (DataBean) context.getBean("dataBean");
    dataBean.populateData();
  }

}
