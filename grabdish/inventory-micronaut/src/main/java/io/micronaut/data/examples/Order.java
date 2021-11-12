/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.micronaut.data.examples;

import io.micronaut.core.annotation.Introspected;
//import com.fasterxml.jackson.annotation.JsonProperty;

@Introspected
public class Order {
    private String orderid = "";
    private String itemid = "";
    private String deliverylocation = "";
//    @JsonbProperty(nillable = true)
    private String status = "";
//    @JsonbProperty(nillable = true)
    private String inventoryLocation = "";
//    @JsonbProperty(nillable = true)
    private String suggestiveSale = "";

    public Order() {
    }

    public Order(String orderId, String itemId, String deliverylocation) {
        this.orderid = orderId;
        this.itemid = itemId;
        this.deliverylocation = deliverylocation;
    }

    public Order(String orderId, String itemId, String deliverylocation,
                 String status, String inventoryLocation, String suggestiveSale) {
        this.orderid = orderId;
        this.itemid = itemId;
        this.deliverylocation = deliverylocation;
        this.status = status;
        this.inventoryLocation = inventoryLocation;
        this.suggestiveSale = suggestiveSale;
    }

    public String getOrderid() {
        return orderid;
    }

    public String getItemid() {
        return itemid;
    }

    public String getDeliverylocation() {
        return deliverylocation;
    }

    public String getStatus() {
        return status;
    }

    public String getInventoryLocation() {
        return inventoryLocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }

    public String toString() {
        String returnString = "";
        returnString+="<br> orderId = " + orderid;
        returnString+="<br> itemid = " + itemid;
        returnString+="<br>  suggestiveSale = " + suggestiveSale;
        returnString+="<br>  inventoryLocation = " + inventoryLocation;
        returnString+="<br>  orderStatus = " + status;
        returnString+="<br>  deliveryLocation = " + deliverylocation;
        return returnString;
    }
}
