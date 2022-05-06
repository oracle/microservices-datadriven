package com.cloudbank.springboot.transfers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import oracle.jdbc.internal.OraclePreparedStatement;
import oracle.jms.*;

import javax.jms.*;
import java.lang.IllegalStateException;
import java.sql.*;
import java.sql.Connection;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class TransferController {


    static PoolDataSource atpInventoryPDB ;
    static String inventoryuser = "INVENTORYUSER";
    static String inventorypw;
    static final String orderQueueName =   System.getenv("orderqueuename");
    static final String inventoryQueueName =  System.getenv("inventoryqueuename");
    static final String queueOwner =   System.getenv("queueowner");
    static final String inventoryUser =  System.getenv("oracle.ucp.jdbc.PoolDataSource.inventorypdb.user");
    static final String inventoryPW =  System.getenv("dbpassword");
    static final String inventoryURL =  System.getenv("oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL");

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
        TopicConnection tconn = t_cf.createTopicConnection("bankauser", "Welcome12345");
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic orderEvents = ((AQjmsSession) tsess).getTopic("AQUSER", "BANKAQUEUE");
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
        TopicConnection tconn = t_cf.createTopicConnection("bankbuser", "Welcome12345");
        TopicSession tsess = tconn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        tconn.start();
        Topic orderEvents = ((AQjmsSession) tsess).getTopic("AQUSER", "BANKAQUEUE");
        TopicReceiver receiver = ((AQjmsSession) tsess).createTopicReceiver(orderEvents, "bankb_service", null);
        TextMessage tm = (TextMessage) (receiver.receive(-1));
tsess.commit();
        System.out.println("________________________________dequeue complete tm:" + tm);
    }

    private PoolDataSource getPoolDataSource()  throws Exception {
        if(atpInventoryPDB!=null) return atpInventoryPDB;
        atpInventoryPDB = PoolDataSourceFactory.getPoolDataSource();
        atpInventoryPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        atpInventoryPDB.setURL("jdbc:oracle:thin:@gd49301311_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_gd49301311");
        atpInventoryPDB.setUser("bankbuser");
        atpInventoryPDB.setPassword("Welcome12345");
        System.out.println("bank atpInventoryPDB:" + atpInventoryPDB);
        return atpInventoryPDB;
    }
}
