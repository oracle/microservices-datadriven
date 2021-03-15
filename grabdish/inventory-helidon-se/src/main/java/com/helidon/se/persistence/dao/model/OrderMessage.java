/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.dao.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class OrderMessage {

    private String orderid;
    private String itemid;
    private String deliverylocation;
    private String status;
    private String inventoryLocation;
    private String suggestiveSale;

    public OrderMessage(String orderid, String itemid, String deliverylocation) {
        this.orderid = orderid;
        this.itemid = itemid;
        this.deliverylocation = deliverylocation;
    }
}