// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.events;

import java.util.HexFormat;
import java.util.UUID;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class JdbcUuidConverterTest {
    @Test
    void usesCanonicalUuidByteOrder() {
        UUID uuid = UUID.fromString("123e4567-e89b-12d3-a456-426614174000");
        byte[] raw = HexFormat.of().parseHex("123E4567E89B12D3A456426614174000");

        assertArrayEquals(raw, JdbcUuidConverter.toBytes(uuid));
        assertEquals(uuid, JdbcUuidConverter.fromBytes(raw));
    }

    @Test
    void rejectsIncorrectLengthValues() {
        assertThrows(IllegalArgumentException.class, () -> JdbcUuidConverter.fromBytes(new byte[15]));
    }

    @Test
    void bindsAndReadsRawBytesWithoutJdbcStrings() throws Exception {
        UUID uuid = UUID.fromString("123e4567-e89b-12d3-a456-426614174000");
        byte[] raw = JdbcUuidConverter.toBytes(uuid);
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet result = mock(ResultSet.class);
        when(result.getBytes("event_id")).thenReturn(raw);

        JdbcUuidConverter.bind(statement, 1, uuid);
        JdbcUuidConverter.bind(statement, 2, null);

        verify(statement).setBytes(1, raw);
        verify(statement).setNull(2, Types.VARBINARY);
        assertEquals(uuid, JdbcUuidConverter.read(result, "event_id"));
    }
}
