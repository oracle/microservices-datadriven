/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import javax.json.bind.annotation.JsonbProperty;

public class Order {
    private String travelagencyid;
    private String itemid;
    private String deliverylocation;
    @JsonbProperty(nillable = true)
    private String status;
    @JsonbProperty(nillable = true)
    private String participantLocation;
    @JsonbProperty(nillable = true)
    private String suggestiveSale;

    public Order() {
    }

    // travelagencydetail is the cache object and travelagency is the JSON message and DB object so we have this mapping at least for now...
    public Order(OrderDetail travelagencyDetail) {
        this(travelagencyDetail.getOrderId(), travelagencyDetail.getItemId(), travelagencyDetail.getDeliveryLocation(),
                travelagencyDetail.getOrderStatus(), travelagencyDetail.getInventoryLocation(), travelagencyDetail.getSuggestiveSale());
    }

    public Order(String travelagencyId, String itemId, String deliverylocation,
                 String status, String participantLocation, String suggestiveSale) {
        this.travelagencyid = travelagencyId;
        this.itemid = itemId;
        this.deliverylocation = deliverylocation;
        this.status = status;
        this.participantLocation = participantLocation;
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

    public void setOrderid(String travelagencyid) {
        this.travelagencyid = travelagencyid;
    }

    public void setItemid(String itemid) {
        this.itemid = itemid;
    }

    public void setDeliverylocation(String deliverylocation) {
        this.deliverylocation = deliverylocation;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setInventoryLocation(String participantLocation) {
        this.participantLocation = participantLocation;
    }

    public void setSuggestiveSale(String suggestiveSale) {
        this.suggestiveSale = suggestiveSale;
    }

    public String getStatus() {
        return status;
    }

    public String getInventoryLocation() {
        return participantLocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }

    public String toString() {
        String returnString = "";
        returnString+="<br> travelagencyId = " + travelagencyid;
        returnString+="<br> itemid = " + itemid;
        returnString+="<br>  suggestiveSale = " + suggestiveSale;
        returnString+="<br>  participantLocation = " + participantLocation;
        returnString+="<br>  travelagencyStatus = " + status;
        returnString+="<br>  deliveryLocation = " + deliverylocation;
        return returnString;
    }
}
