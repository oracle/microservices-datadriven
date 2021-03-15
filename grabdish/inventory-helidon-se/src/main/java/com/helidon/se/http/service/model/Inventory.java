/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.http.service.model;

import java.sql.ResultSet;
import java.sql.SQLException;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class Inventory {

    private String inventoryId;
    private String inventorylocation;
    private Integer inventorycount;

    public Inventory(ResultSet res) throws SQLException {
        this.inventoryId = res.getString(1);
        this.inventorylocation = res.getString(2);
        this.inventorycount = res.getInt(3);
    }

}
