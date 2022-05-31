package com.cloudbank.springboot.transfers;

import oracle.jdbc.OraclePreparedStatement;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import org.json.JSONObject;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;

import oracle.jms.*;

import javax.jms.*;

import org.springframework.web.bind.annotation.GetMapping;
@RestController
public class TransferController {

    PoolDataSource atpBankPDB ;
    final String localbankqueueschema =  System.getenv("localbankqueueschema");
    final String localbankqueuename =  System.getenv("localbankqueuename");
    final String remotebankqueueschema =  System.getenv("remotebankqueueschema");
    final String remotebankqueuename =  System.getenv("remotebankqueuename");
    final String banksubscribername =  System.getenv("banksubscribername");
    final String bankdbuser =   System.getenv("bankdbuser");
    final String bankdbpw =  System.getenv("bankdbpw");

    final String bankdburl =   System.getenv("bankdburl");
    //transfer id is currently just the currentTimeMillis and not persisted
    private Map<String, TransferInformation> transferLedger = new HashMap<>();

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }
//   curl -X POST -H "Content-type: application/json" -d  "{\"frombank\" : \"banka\" , \"fromaccount\" : \"123\", \"tobank\" : \"bankb\", \"toaccount\" : \"456\",  \"amount\" : \"100\"}"  "http://banka.msdataworkshop:8080/transferfunds"
    @PostMapping(value ="/transferfunds",
            consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE},
            produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
    public TransferOutcome transferfunds(@RequestBody TransferInformation transferInformation) throws Exception {
        String transferId = "" +  System.currentTimeMillis();
        System.out.println("TransferController.enqueue transferInformation:" + transferInformation + " transferId:" + transferId);
        transferLedger.put(transferId, transferInformation);
        adjustBalanceAndEnqueueTransfer(transferId, transferInformation);
        return new TransferOutcome("success");
    }

    /**
     * This handles both messages for both
     * Transfer request (if this is the 2nd bank in the transfer process):
     *  will adjust the account balance
     *  and send it's message reply to the 1st bank via message
     * and
     * Transfer response (if this is the 1st/initiating bank in the transfer process):
     *  will adjust it's balance if it is to rollback/compensate
     *  and set the status of the overall transfer for return to the (Rest) client that called it
     * @throws Exception
     */
    @EventListener(ApplicationReadyEvent.class)
    public void listenForMessages() throws Exception {
        PoolDataSource atpBankPDB = getPoolDataSource();
        while(true) {
            TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpBankPDB);
            TopicConnection tconn = t_cf.createTopicConnection(bankdbuser, bankdbpw);
            TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
            tconn.start();
            Topic bankEvents = ((AQjmsSession) tsess).getTopic(remotebankqueueschema, remotebankqueuename);
            TopicReceiver receiver = ((AQjmsSession) tsess).createTopicReceiver(bankEvents, banksubscribername, null);
            System.out.println("________________________________listening for message:" + this);
            TextMessage tm = (TextMessage) (receiver.receive(-1));
            System.out.println("________________________________received message:" + tm.getText());
            TransferMessage transferMessage = JsonUtils.read(tm.getText(), TransferMessage.class);
            String transferId = transferMessage.getTransferid();
//            JSONObject jsonObject = new JSONObject(tm);
//            String transferId = jsonObject.getString("transferid");
//            int transferAmount = jsonObject.getInt("transferamount");
//            TransferMessage transferMessage =
//                    new TransferMessage(transferId,jsonObject.getInt("bankaccount"),transferAmount);
            //todo the following assumptions is very wrong as transferLedger is not persisted currently thus it's possible to treat this as 2nd bank rather than 1st
            if (transferLedger.containsKey(transferId)) {
                if (transferMessage.isTransfersuccess()) {
                    System.out.println("Transfer success for transferId:" + transferId);
                } else {
                    System.out.println("Transfer failed for transferId:" + transferId + " rolling back/compensating balance");
                    // todo roll back/compensate balance
                }
                //todo update transferLedger with outcome
            } else {
                adjustBalance(transferMessage.getTransferamount(), transferMessage.getBankaccount(), (AQjmsSession) tsess);
                Topic bankReplyEvents = ((AQjmsSession) tsess).getTopic(localbankqueueschema, localbankqueuename);
                TopicPublisher publisher = tsess.createPublisher(bankReplyEvents);
                TextMessage transferReplyMessage = tsess.createTextMessage();
                String jsonString = JsonUtils.writeValueAsString(new TransferMessage(transferId, true));
                transferReplyMessage.setText(jsonString);
                publisher.send(bankReplyEvents, transferReplyMessage, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
            }
            tsess.commit(); //todo handle rollback
            System.out.println("________________________________listening for message complete:" + this);
        }
    }

    /**
     * Adjust this 1st/local bank account's balance and send a transfer message to the 2nd/remote bank account
     * @param transferId
     * @param transferInformation
     * @throws Exception
     */
    public void adjustBalanceAndEnqueueTransfer(String transferId, TransferInformation transferInformation) throws Exception {
        PoolDataSource atpBankPDB = getPoolDataSource();
        TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpBankPDB);
        TopicConnection tconn = t_cf.createTopicConnection(bankdbuser, bankdbpw);
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        adjustBalance(transferInformation.getAmount(), transferInformation.getFromAccount(), (AQjmsSession) tsess);
        Topic bankEvents = ((AQjmsSession) tsess).getTopic(localbankqueueschema, localbankqueuename);
        TopicPublisher publisher = tsess.createPublisher(bankEvents);
        TextMessage transferMessage = tsess.createTextMessage();
        String jsonString = JsonUtils.writeValueAsString(new TransferMessage(transferId, transferInformation.getToAccount(), transferInformation.getAmount()));
        transferMessage.setText(jsonString);
        publisher.send(bankEvents, transferMessage, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
        tsess.commit(); //todo handle rollback
        System.out.println("________________________________enqueue of transfer request complete:" + jsonString + " this:" + this);
    }

    private void adjustBalance(int amount, int account, AQjmsSession tsess) throws Exception {
        final String UPDATE_BALANCE =
                "update accounts set accountvalue = accountvalue + ? where accountid = ? and accountvalue > 0 returning accountvalue into ?";
        try (OraclePreparedStatement st =  (OraclePreparedStatement) tsess.getDBConnection().prepareStatement(UPDATE_BALANCE)) {
            st.setInt(1, -amount);
            st.setInt(2, account);
            st.registerReturnParameter(3, Types.INTEGER);
            int i = st.executeUpdate();
            System.out.println("adjustBalance complete amount = " + amount + ", account = " + account);
            //todo something wrong where I'm not getting account value return....
            ResultSet res = st.getReturnResultSet();
            if (res.next()) {
//                int accountBalance = res.getInt(3);
//                System.out.println("Account balance is:" + accountBalance + "for account:" + account);
            } else {
//                System.out.println("No account (balance) found for account:" + account + " i:" + i);
            }
        }
    }

    private PoolDataSource getPoolDataSource()  throws Exception {
        if(atpBankPDB!=null) return atpBankPDB;
        atpBankPDB = PoolDataSourceFactory.getPoolDataSource();
        atpBankPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        atpBankPDB.setURL(bankdburl);
//        atpBankPDB.setURL("jdbc:oracle:thin:@gd49301311_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_gd49301311");
        atpBankPDB.setUser(bankdbuser);
        atpBankPDB.setPassword(bankdbpw);
        System.out.println("bank atpBankPDB:" + atpBankPDB);
        return atpBankPDB;
    }

    @Override
    public String toString() {
        return "TransferController{" +
                "localbankqueueschema='" + localbankqueueschema + '\'' +
                ", localbankqueuename='" + localbankqueuename + '\'' +
                ", remotebankqueueschema='" + remotebankqueueschema + '\'' +
                ", remotebankqueuename='" + remotebankqueuename + '\'' +
                ", banksubscribername='" + banksubscribername + '\'' +
                ", bankdbuser='" + bankdbuser + '\'' +
                ", bankdburl='" + bankdburl + '\'' +
                '}';
    }














    //here to end is for basic enq/deq test
    public void enqueue() throws Exception {
        PoolDataSource atpBankPDB = getPoolDataSource();
        try (Connection connection  = atpBankPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("bank connection:" + connection);
        }
        TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpBankPDB);
        TopicConnection tconn = t_cf.createTopicConnection(bankdbuser, bankdbpw);
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic bankEvents = ((AQjmsSession) tsess).getTopic(localbankqueueschema, localbankqueuename);
        TopicPublisher publisher = tsess.createPublisher(bankEvents);
        TextMessage transferMessage = tsess.createTextMessage();
        transferMessage.setText("somemessagetext");
        publisher.send(bankEvents, transferMessage, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
tsess.commit();
        System.out.println("________________________________enqueue complete");
    }
    public void dequeue() throws Exception {
        PoolDataSource atpBankPDB = getPoolDataSource();
        try (Connection connection  = atpBankPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("bank connection:" + connection);
        }
        TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpBankPDB);
        TopicConnection tconn = t_cf.createTopicConnection(bankdbuser, bankdbpw);
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic bankEvents = ((AQjmsSession) tsess).getTopic(remotebankqueueschema, remotebankqueuename);
        TopicReceiver receiver = ((AQjmsSession) tsess).createTopicReceiver(bankEvents, banksubscribername, null);
        TextMessage tm = (TextMessage) (receiver.receive(-1));
tsess.commit();
        System.out.println("________________________________dequeue complete tm:" + tm);
    }


    @GetMapping("/enqueue")
    public Test testenqueue() throws Exception {
        System.out.println("TransferController.enqueue");
        enqueue();
        return new Test("enqueue complete");
    }
    @GetMapping("/dequeue")
    public Test testdequeue() throws Exception {
        System.out.println("TransferController.dequeue");
        dequeue();
        return new Test("dequeue complete");
    }

    public class Test {
        private final String content;

        public Test(String content) {
            this.content = content;
        }

        public String getContent() {
            return content;
        }
    }
}
