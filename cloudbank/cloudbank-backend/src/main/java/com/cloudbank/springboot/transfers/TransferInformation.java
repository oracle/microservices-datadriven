package com.cloudbank.springboot.transfers;

/**
 * Rest request and bank representation of transfer (as opposed to TransferMessage which is the transfer message sent between banks)
 */
public class TransferInformation {
        private  String frombank;
        private  int fromaccount;
        private  String tobank;
        private  int toaccount;
        private  int amount;

        public TransferInformation(String frombank, int fromaccount, String tobank, int toaccount, int amount) {
        this.frombank = frombank;
        this.fromaccount = fromaccount;
        this.tobank = tobank;
        this.toaccount = toaccount;
        this.amount = amount;
    }


        public String getFrombank() {
        return frombank;
    }

        public void setFrombank(String frombank) {
        this.frombank = frombank;
    }

        public int getFromaccount() {
        return fromaccount;
    }

        public void setFromaccount(int fromaccount) {
        this.fromaccount = fromaccount;
    }

        public String getTobank() {
        return tobank;
    }

        public void setTobank(String tobank) {
        this.tobank = tobank;
    }

        public int getToaccount() {
        return toaccount;
    }

        public void setToaccount(int toaccount) {
        this.toaccount = toaccount;
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
                "frombank=" + frombank +
                ", fromaccount=" + fromaccount +
                ", tobank=" + tobank +
                ", toaccount=" + toaccount +
                ", amount=" + amount +
                '}';
    }
}
