// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.persistence;

import java.nio.ByteBuffer;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.UUID;

/** Binds Java UUID values to Oracle RAW(16) and reads them back. */
final class JdbcUuidConverter {
    private static final int UUID_BYTES = 16;

    private JdbcUuidConverter() {
    }

    static byte[] toBytes(UUID uuid) {
        return ByteBuffer.allocate(UUID_BYTES)
                .putLong(uuid.getMostSignificantBits())
                .putLong(uuid.getLeastSignificantBits())
                .array();
    }

    static UUID fromBytes(byte[] raw) {
        if (raw == null || raw.length != UUID_BYTES) {
            throw new IllegalArgumentException("Expected exactly 16 UUID bytes");
        }
        ByteBuffer bytes = ByteBuffer.wrap(raw);
        return new UUID(bytes.getLong(), bytes.getLong());
    }

    static void bind(PreparedStatement statement, int index, UUID value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.VARBINARY);
        } else {
            statement.setBytes(index, toBytes(value));
        }
    }

    static UUID read(ResultSet result, String column) throws SQLException {
        byte[] raw = result.getBytes(column);
        return raw == null ? null : fromBytes(raw);
    }
}
