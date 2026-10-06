// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class EventsConfigurationTest {
    @Test
    void unsupportedProtocolCannotSilentlySelectPlaintext() {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "SL");

        IllegalArgumentException error = assertThrows(IllegalArgumentException.class,
                configuration::okafkaAuth);

        assertEquals("OKAFKA_SECURITY_PROTOCOL must be SSL or PLAINTEXT", error.getMessage());
    }

    @Test
    void sslUsesWalletAndTnsAlias() throws Exception {
        EventsConfiguration configuration = new EventsConfiguration();
        ReflectionTestUtils.setField(configuration, "securityProtocol", "SSL");
        ReflectionTestUtils.setField(configuration, "walletDir", "/tmp/lab-wallet");
        ReflectionTestUtils.setField(configuration, "tnsAdmin", "mydb_tp");

        Properties properties = configuration.okafkaAuth();

        assertEquals("SSL", properties.getProperty("security.protocol"));
        assertEquals("/tmp/lab-wallet", properties.getProperty("oracle.net.tns_admin"));
        assertEquals("mydb_tp", properties.getProperty("tns.alias"));
    }
}
