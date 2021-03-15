/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import com.helidon.se.http.service.model.Inventory;

import lombok.extern.slf4j.Slf4j;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;

@Slf4j
public class InventoryDao {

    private static final String GET_BY_ID = "select * from inventory where inventoryid = ?";
    private static final String DECREMENT_BY_ID = "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";

    public InventoryDao() {
    }

    public Inventory get(OracleConnection conn, String id) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement) conn.prepareStatement(GET_BY_ID)) {
            st.setString(1, id);
            ResultSet res = st.executeQuery();
            if (res.next()) {
                return new Inventory(res);
            } else {
                return null;
            }
        }
    }

    public String decrement(OracleConnection conn, String id) throws SQLException {
        try (OraclePreparedStatement st = (OraclePreparedStatement) conn.prepareStatement(DECREMENT_BY_ID)) {
            st.setString(1, id);
            st.registerReturnParameter(2, Types.VARCHAR);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String location = res.getString(1);
                log.debug("Decremented inventory id {} location {}", id, location);
                return location;
            } else {
                return "inventorydoesnotexist";
            }
        }
    }
}
