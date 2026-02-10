package com.example.observability;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.logs.Logger;
import io.opentelemetry.api.logs.Severity;
import io.opentelemetry.context.Context;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;

/**
 * Custom JUL Handler that bridges java.util.logging to OpenTelemetry.
 * Uses Context.current() to capture trace context for log-trace correlation.
 */
public class OpenTelemetryJULHandler extends Handler {
    private final Logger otelLogger;
    
    // Define attribute keys for exception details
    private static final AttributeKey<String> EXCEPTION_TYPE = AttributeKey.stringKey("exception.type");
    private static final AttributeKey<String> EXCEPTION_MESSAGE = AttributeKey.stringKey("exception.message");

    public OpenTelemetryJULHandler() {
        // Assumes Helidon has already initialized GlobalOpenTelemetry
        this.otelLogger = GlobalOpenTelemetry.get()
            .getLogsBridge()
            .get("customer-helidon");
    }

    @Override
    public void publish(LogRecord record) {
        if (!isLoggable(record)) {
            return;
        }

        // CRITICAL: Capture the current Context (Trace ID / Span ID)
        // This links the log to the active trace
        Context currentContext = Context.current();

        var logBuilder = otelLogger.logRecordBuilder()
            .setContext(currentContext) // <--- THIS IS THE KEY
            .setBody(formatMessage(record))
            .setSeverity(mapLevel(record.getLevel()))
            .setSeverityText(record.getLevel().getName())
            .setTimestamp(java.time.Instant.ofEpochMilli(record.getMillis()));

        if (record.getThrown() != null) {
            logBuilder.setAttribute(EXCEPTION_TYPE, record.getThrown().getClass().getName());
            logBuilder.setAttribute(EXCEPTION_MESSAGE, record.getThrown().getMessage());
        }

        logBuilder.emit();
    }

    private String formatMessage(LogRecord record) {
        return record.getMessage();
    }

    private Severity mapLevel(Level level) {
        int value = level.intValue();
        if (value >= Level.SEVERE.intValue()) return Severity.ERROR;
        if (value >= Level.WARNING.intValue()) return Severity.WARN;
        if (value >= Level.INFO.intValue()) return Severity.INFO;
        if (value >= Level.CONFIG.intValue()) return Severity.DEBUG;
        return Severity.TRACE;
    }

    @Override
    public void flush() {
        // No buffering needed
    }

    @Override
    public void close() {
        // No resources to close
    }
}
