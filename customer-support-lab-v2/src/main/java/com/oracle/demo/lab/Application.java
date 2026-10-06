// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab;

import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.spring.otel.TracingConfigurator;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.core.task.SimpleAsyncTaskExecutor;
import org.springframework.jdbc.core.RowMapper;

@SpringBootApplication
// The Oracle JDBC OTel configurator lives outside this application's component scan.
@Import(TracingConfigurator.class)
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@Bean("applicationTaskExecutor")
	SimpleAsyncTaskExecutor applicationTaskExecutor() {
		return new SimpleAsyncTaskExecutor("app-");
	}

	@Bean
	public RowMapper<SupportTicket> supportTicketRowMapper() {
		return (rs, rowNum) -> new SupportTicket(rs);
    }
}
