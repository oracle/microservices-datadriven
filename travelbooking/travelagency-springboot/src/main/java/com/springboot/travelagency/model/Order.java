package com.springboot.travelagency.model;

import java.io.Serializable;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Order implements Serializable {
    private String travelagencyid;
    private String itemid;
    private String deliverylocation;
    @JsonProperty(required = false)
    private String status;
    @JsonProperty(required = false)
    private String travelagencyLocation;
    @JsonProperty(required = false)
    private String suggestiveSale;

    public Order() {
    }

    public Order(String travelagencyId, String itemId, String deliverylocation) {
        this.travelagencyid = travelagencyId;
        this.itemid = itemId;
        this.deliverylocation = deliverylocation;
    }

    public Order(String travelagencyId, String itemId, String deliverylocation,
                 String status, String travelagencyLocation, String suggestiveSale) {
        this.travelagencyid = travelagencyId;
        this.itemid = itemId;
        this.deliverylocation = deliverylocation;
        this.status = status;
        this.travelagencyLocation = travelagencyLocation;
        this.suggestiveSale = suggestiveSale;
    }

    public String getOrderid() {
        return travelagencyid;
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
        return travelagencyLocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }

    public String toString() {
        String returnString = "";
        returnString+="<br> travelagencyId = " + travelagencyid;
        returnString+="<br> itemid = " + itemid;
        returnString+="<br>  suggestiveSale = " + suggestiveSale;
        returnString+="<br>  travelagencyLocation = " + travelagencyLocation;
        returnString+="<br>  travelagencyStatus = " + status;
        returnString+="<br>  deliveryLocation = " + deliverylocation;
        return returnString;
    }
}

