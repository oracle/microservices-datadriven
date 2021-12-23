/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

public class Inventory {

    private String travelagencyid;
    private String itemid;
    private String participantlocation;
    private String suggestiveSale;

    public Inventory() {

    }

    public Inventory(String travelagencyid, String itemid, String participantlocation, String suggestiveSale) {
        this.travelagencyid = travelagencyid;
        this.itemid = itemid;
        this.participantlocation = participantlocation;
        this.suggestiveSale = suggestiveSale;
    }

    public String getOrderid() {
        return travelagencyid;
    }

    public String getItemid() {
        return itemid;
    }

    public String getInventorylocation() {
        return participantlocation;
    }

    public String getSuggestiveSale() {
        return suggestiveSale;
    }
}
