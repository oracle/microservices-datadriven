package com.cloudbank.springboot.transfers;

/**
 * Transfer message sent between banks (as opposed to TransferInformation which is the rest request and bank representation of transfer)
 */
public class TransferMessage {
    String transferid;
    int bankaccount;

    int transferamount;
    boolean transfersuccess;

    /**
     * For request
     * @param transferid
     * @param bankaccount
     * @param transferamount
     */
    public TransferMessage(String transferid, int bankaccount, int transferamount) {
        this.transferid = transferid;
        this.bankaccount = bankaccount;
        this.transferamount = transferamount;
    }

    /**
     * For response
     * @param transferid
     * @param transfersuccess
     */
    public TransferMessage(String transferid,  boolean transfersuccess) {
        this.transferid = transferid;
        this.transfersuccess = transfersuccess;
    }

    @Override
    public String toString() {
        return "TransferMessage{" +
                "transferid='" + transferid + '\'' +
                ", bankaccount=" + bankaccount +
                ", transferamount=" + transferamount +
                ", transfersuccess=" + transfersuccess +
                '}';
    }

    public TransferMessage() {
    }

    public TransferMessage(String transferid, int bankaccount, int transferamount, boolean transfersuccess) {
        this.transferid = transferid;
        this.bankaccount = bankaccount;
        this.transferamount = transferamount;
        this.transfersuccess = transfersuccess;
    }

    public boolean isTransfersuccess() {
        return transfersuccess;
    }

    public void setTransfersuccess(boolean transfersuccess) {
        this.transfersuccess = transfersuccess;
    }



    public String getTransferid() {
        return transferid;
    }

    public void setTransferid(String transferid) {
        this.transferid = transferid;
    }

    public int getBankaccount() {
        return bankaccount;
    }

    public void setBankaccount(int bankaccount) {
        this.bankaccount = bankaccount;
    }

    public int getTransferamount() {
        return transferamount;
    }

    public void setTransferamount(int transferamount) {
        this.transferamount = transferamount;
    }

}
