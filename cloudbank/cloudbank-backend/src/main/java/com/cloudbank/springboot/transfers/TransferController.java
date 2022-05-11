package com.cloudbank.springboot.transfers;

import org.springframework.web.bind.annotation.RestController;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import oracle.jms.*;

import javax.jms.*;

import org.springframework.web.bind.annotation.GetMapping;
@RestController
public class TransferController {


    static PoolDataSource atpInventoryPDB ;
    static final String bankaqueueschema =  "aquser";
    static final String bankaqueuename =  "BANKAQUEUE";
    static final String bankasubscribername =  "bankb_service";
    static final String bankauser =   System.getenv("bankauser");
    static final String bankapw =  System.getenv("bankapw");
    static final String bankaurl =   System.getenv("bankaurl");

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
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

    public void enqueue() throws Exception {
        PoolDataSource atpInventoryPDB = getPoolDataSource();
        try (Connection connection  = atpInventoryPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("bank connection:" + connection);
        }
        TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpInventoryPDB);
        TopicConnection tconn = t_cf.createTopicConnection(bankauser, bankapw);
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic orderEvents = ((AQjmsSession) tsess).getTopic(bankaqueueschema, bankaqueuename);
        TopicPublisher publisher = tsess.createPublisher(orderEvents);
        TextMessage inventoryMessage = tsess.createTextMessage();
        inventoryMessage.setText("somemessagetext");
        publisher.send(orderEvents, inventoryMessage, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
tsess.commit();
        System.out.println("________________________________enqueue complete");
    }
    public void dequeue() throws Exception {
        PoolDataSource atpInventoryPDB = getPoolDataSource();
        try (Connection connection  = atpInventoryPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("bank connection:" + connection);
        }
        TopicConnectionFactory t_cf = AQjmsFactory.getTopicConnectionFactory(atpInventoryPDB);
        TopicConnection tconn = t_cf.createTopicConnection(bankauser, bankapw);
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic orderEvents = ((AQjmsSession) tsess).getTopic(bankaqueueschema, bankaqueuename);
        TopicReceiver receiver = ((AQjmsSession) tsess).createTopicReceiver(orderEvents, bankasubscribername, null);
        TextMessage tm = (TextMessage) (receiver.receive(-1));
tsess.commit();
        System.out.println("________________________________dequeue complete tm:" + tm);
    }

    private PoolDataSource getPoolDataSource()  throws Exception {
        if(atpInventoryPDB!=null) return atpInventoryPDB;
        atpInventoryPDB = PoolDataSourceFactory.getPoolDataSource();
        atpInventoryPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        atpInventoryPDB.setURL(bankaurl);
//        atpInventoryPDB.setURL("jdbc:oracle:thin:@gd49301311_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_gd49301311");
        atpInventoryPDB.setUser(bankauser);
        atpInventoryPDB.setPassword(bankapw);
        System.out.println("bank atpInventoryPDB:" + atpInventoryPDB);
        return atpInventoryPDB;
    }
}
