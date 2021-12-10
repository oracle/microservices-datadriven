package com.springboot.inventory.model;

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
