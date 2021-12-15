package com.springboot.travelagency.model;

public class Inventory {

    private String travelagencyid;
    private String itemid;
    private String travelagencylocation;
    private String suggestiveSale;

    public Inventory() {

    }

    public Inventory(String travelagencyid, String itemid, String travelagencylocation, String suggestiveSale) {
        this.travelagencyid = travelagencyid;
        this.itemid = itemid;
        this.travelagencylocation = travelagencylocation;
        this.suggestiveSale = suggestiveSale;
    }

    public String getOrderid() {
        return travelagencyid;
    }

    public String getItemid() {
        return itemid;
    }

    public String getInventorylocation() {
        return travelagencylocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }
}
