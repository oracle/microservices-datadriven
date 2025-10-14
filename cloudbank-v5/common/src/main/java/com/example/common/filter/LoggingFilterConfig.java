// Copyright (c) 2025, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.common.filter;

import java.io.IOException;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.filter.CommonsRequestLoggingFilter;

@Slf4j
@Configuration
public class LoggingFilterConfig {

    /**
     * Create CommonsRequestLoggingFilter bean.
     * 
     * @return CommonsRequestLoggingFilter bean
     */
    @Bean
    public CommonsRequestLoggingFilter logFilter() {
        log.info("Log filter initialized");
        CommonsRequestLoggingFilter filter = new CommonsRequestLoggingFilter() {
            @Value("${request.logging.shouldLog}")
            private boolean shouldLog;

            @Override
            protected boolean shouldLog(HttpServletRequest request) {
                if (request.getRequestURI().contains("/actuator")) {
                    return false;
                }

                return shouldLog;
            }

            @Override
            protected void beforeRequest(HttpServletRequest request, String message) {
                logger.info(message);
            }

            @Override
            protected void afterRequest(HttpServletRequest request, String message) {
                logger.info(message);
            }

            @Override
            protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                    FilterChain filterChain)
                    throws ServletException, IOException {
                long startTime = System.currentTimeMillis();

                try {
                    super.doFilterInternal(request, response, filterChain);
                } finally {
                    long duration = System.currentTimeMillis() - startTime;
                    if (shouldLog(request)) {
                        logger.info(String.format("Response: Status={%s}, URI={%s}, Duration={%d}ms",
                                response.getStatus(),
                                request.getRequestURI(),
                                duration));

                        if (request.getAttribute("javax.servlet.error.exception") != null) {
                            logger.error("Exception during request processing",
                                    (Exception) request.getAttribute("javax.servlet.error.exception"));
                        }

                        if (request.getAttribute("jakarta.servlet.error.exception") != null) {
                            logger.error("Exception during request processing",
                                    (Exception) request.getAttribute("jakarta.servlet.error.exception"));
                        }
                    }

                }
            }

        };
        filter.setIncludeQueryString(true);
        filter.setIncludePayload(true);
        filter.setMaxPayloadLength(10000);
        filter.setIncludeHeaders(true);
        filter.setIncludeClientInfo(true);
        filter.setBeforeMessagePrefix("Request started => ");
        filter.setAfterMessagePrefix("Request ended => ");
        return filter;
    }
}