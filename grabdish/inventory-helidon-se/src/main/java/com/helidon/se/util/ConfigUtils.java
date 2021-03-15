/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.util;

import java.util.Objects;
import java.util.function.Consumer;

import org.slf4j.Logger;

import io.helidon.config.Config;
import io.helidon.config.ConfigSources;

public class ConfigUtils {

    public static Config buildConfig(String... args) {
        Config.Builder builder = Config.builder();
        if (Objects.nonNull(args) && args.length > 0) {
            builder.sources(ConfigSources.classpath(args[0]));
        }
        return builder.build();
    }

    public static void getBoolConfig(Config dbConfig, String name, Consumer<Boolean> cons) {
        Boolean param = dbConfig.get(name).asBoolean().orElseGet(() -> null);
        if (Objects.nonNull(param)) {
            cons.accept(param);
        }
    }

    public static String getLogLevel(Logger log) {
        if (log.isTraceEnabled()) {
            return "TRACE";
        } else if (log.isDebugEnabled()) {
            return "DEBUG";
        } else if (log.isInfoEnabled()) {
            return "INFO";
        } else if (log.isWarnEnabled()) {
            return "WARN";
        } else if (log.isErrorEnabled()) {
            return "ERROR";
        } else {
            return "Undefined";
        }
    }
}
