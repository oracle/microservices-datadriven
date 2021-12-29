/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import javax.json.bind.annotation.JsonbProperty;

public class OrderDetail {

    @JsonbProperty("travelagencyId")
    private String travelagencyId;
    @JsonbProperty(nillable = true) // todo nillable is not necessary
    private String itemId;
    @JsonbProperty(nillable = true)
    private String suggestiveSaleItem = "";
    @JsonbProperty(nillable = true)
    private String suggestiveSale = "";
    @JsonbProperty
    private String participantLocationItem = "";
    @JsonbProperty
    private String participantLocation = "none";
    @JsonbProperty
    private String shippingEstimate = "none";
    @JsonbProperty
    private String shippingEstimateItem = "";
    @JsonbProperty
    private String travelagencyStatus = "none";
    @JsonbProperty
    private String deliveryLocation = "none";


    public String toString() {
        String returnString = "";
        returnString+="<br> travelagencyId = " + travelagencyId;
        returnString+="<br>  suggestiveSale = " + suggestiveSale;
        returnString+="<br>  participantLocation = " + participantLocation;
        returnString+="<br>  travelagencyStatus = " + travelagencyStatus;
        returnString+="<br>  deliveryLocation = " + deliveryLocation;
        return returnString;
    }

    public String getOrderId() {
        return travelagencyId;
    }

    public void setOrderId(String travelagencyId) {
        this.travelagencyId = travelagencyId;
    }

    public String getItemId() {
        return itemId;
    }

    public void setItemId(String itemId) {
        this.itemId = itemId;
    }

    public String getSuggestiveSaleItem() {
        return suggestiveSaleItem;
    }

    public void setSuggestiveSaleItem(String suggestiveSaleItem) {
        this.suggestiveSaleItem = suggestiveSaleItem;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }

    public void setSuggestiveSale(String suggestiveSale) {
        this.suggestiveSale = suggestiveSale;
    }

    public String getInventoryLocationItem() {
        return participantLocationItem;
    }

    public void setInventoryLocationItem(String participantLocationItem) {
        this.participantLocationItem = participantLocationItem;
    }

    public String getInventoryLocation() {
        return participantLocation;
    }

    public void setInventoryLocation(String participantLocation) {
        this.participantLocation = participantLocation;
    }

    public String getShippingEstimate() {
        return shippingEstimate;
    }

    public void setShippingEstimate(String shippingEstimate) {
        this.shippingEstimate = shippingEstimate;
    }

    public String getShippingEstimateItem() {
        return shippingEstimateItem;
    }

    public void setShippingEstimateItem(String shippingEstimateItem) {
        this.shippingEstimateItem = shippingEstimateItem;
    }

    public String getOrderStatus() {
        return travelagencyStatus;
    }

    public void setOrderStatus(String travelagencyStatus) {
        this.travelagencyStatus = travelagencyStatus;
    }

    public void setDeliveryLocation(String deliverylocation) {
        this.deliveryLocation = deliverylocation;
    }

    public String getDeliveryLocation() {
        return deliveryLocation;
    }

}

