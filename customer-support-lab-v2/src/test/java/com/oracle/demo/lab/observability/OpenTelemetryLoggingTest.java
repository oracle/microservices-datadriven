// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.observability;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.core.OutputStreamAppender;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.TraceFlags;
import io.opentelemetry.api.trace.TraceState;
import io.opentelemetry.context.Scope;
import io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender;
import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.logs.SdkLoggerProvider;
import io.opentelemetry.sdk.logs.data.LogRecordData;
import io.opentelemetry.sdk.logs.export.LogRecordExporter;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.logging.logback.StructuredLogEncoder;
import org.springframework.boot.opentelemetry.autoconfigure.OpenTelemetrySdkAutoConfiguration;
import org.springframework.boot.opentelemetry.autoconfigure.logging.OpenTelemetryLoggingAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

import java.util.Collection;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

class OpenTelemetryLoggingTest {
    @Test
    void logbackExportsApplicationLogsWithServiceAndTraceContext() {
        try (var context = new SpringApplicationBuilder(LoggingConfiguration.class)
                .web(WebApplicationType.NONE)
                .run("--spring.main.banner-mode=off", "--spring.main.log-startup-info=false")) {
            Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
            assertInstanceOf(OpenTelemetryAppender.class, root.getAppender("OTEL"));
            var console = assertInstanceOf(OutputStreamAppender.class, root.getAppender("CONSOLE"));
            assertInstanceOf(StructuredLogEncoder.class, console.getEncoder());
            var spanContext = SpanContext.create(
                    "0123456789abcdef0123456789abcdef", "0123456789abcdef",
                    TraceFlags.getSampled(), TraceState.getDefault());
            try (Scope ignored = Span.wrap(spanContext).makeCurrent()) {
                LoggerFactory.getLogger(getClass()).info("lab-log-export-verification");
            }
            var flushed = context.getBean(SdkLoggerProvider.class).forceFlush();
            flushed.join(5, TimeUnit.SECONDS);
            assertTrue(flushed.isSuccess());
            var record = context.getBean(CapturedLogs.class).records.stream()
                    .filter(log -> "lab-log-export-verification".equals(log.getBodyValue().asString()))
                    .findFirst().orElseThrow();
            assertEquals("customer-support-lab-v2",
                    record.getResource().getAttribute(AttributeKey.stringKey("service.name")));
            assertEquals(spanContext.getTraceId(), record.getSpanContext().getTraceId());
            assertEquals(spanContext.getSpanId(), record.getSpanContext().getSpanId());
        }
    }

    @Configuration(proxyBeanMethods = false)
    @Import(OpenTelemetryAppenderInitializer.class)
    @ImportAutoConfiguration({OpenTelemetrySdkAutoConfiguration.class,
            OpenTelemetryLoggingAutoConfiguration.class})
    static class LoggingConfiguration {
        @Bean
        CapturedLogs capturedLogs() {
            return new CapturedLogs();
        }
    }

    static class CapturedLogs implements LogRecordExporter {
        final List<LogRecordData> records = new CopyOnWriteArrayList<>();

        @Override
        public CompletableResultCode export(Collection<LogRecordData> batch) {
            records.addAll(batch);
            return CompletableResultCode.ofSuccess();
        }

        @Override
        public CompletableResultCode flush() {
            return CompletableResultCode.ofSuccess();
        }

        @Override
        public CompletableResultCode shutdown() {
            return CompletableResultCode.ofSuccess();
        }
    }
}
