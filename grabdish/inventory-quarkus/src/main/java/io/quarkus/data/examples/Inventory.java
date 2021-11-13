/*
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.quarkus.data.examples;

public class Inventory {

    private String orderid;
    private String itemid;
    private String inventorylocation;
    private String suggestiveSale;

    public Inventory() {

    }

    public Inventory(String orderid, String itemid, String inventorylocation, String suggestiveSale) {
        this.orderid = orderid;
        this.itemid = itemid;
        this.inventorylocation = inventorylocation;
        this.suggestiveSale = suggestiveSale;
    }

    public String getOrderid() {
        return orderid;
    }

    public String getItemid() {
        return itemid;
    }

    public String getInventorylocation() {
        return inventorylocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }
}
