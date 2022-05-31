package com.cloudbank.authservice.entity;

public class TransferRequestBody {
    private  String fromBank;
    private  int fromAccount;
    private  String toBank;
    private  int toAccount;
    private  int amount;

    public TransferRequestBody(String fromBank, int fromAccount, String toBank, int toAccount, int amount) {
        this.fromBank = fromBank;
        this.fromAccount = fromAccount;
        this.toBank = toBank;
        this.toAccount = toAccount;
        this.amount = amount;
    }

    public String getFromBank() {
        return fromBank;
    }

    public void setFromBank(String fromBank) {
        this.fromBank = fromBank;
    }

    public int getFromAccount() {
        return fromAccount;
    }

    public void setFromAccount(int fromAccount) {
        this.fromAccount = fromAccount;
    }

    public String getToBank() {
        return toBank;
    }

    public void setToBank(String toBank) {
        this.toBank = toBank;
    }

    public int getToAccount() {
        return toAccount;
    }

    public void setToAccount(int toAccount) {
        this.toAccount = toAccount;
    }

    public int getAmount() {
        return amount;
    }

    public void setAmount(int amount) {
        this.amount = amount;
    }

    @Override
    public String toString() {
        return "TransferInformation{" +
                "fromBank=" + fromBank +
                ", fromAccount=" + fromAccount +
                ", toBank=" + toBank +
                ", toAccount=" + toAccount +
                ", amount=" + amount +
                '}';
    }
}
