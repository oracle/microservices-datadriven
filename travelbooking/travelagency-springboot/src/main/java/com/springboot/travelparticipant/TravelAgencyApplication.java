package com.springboot.travelparticipant;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;
import AQSaga.*;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import javax.jms.*;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

@Configuration
@EnableAutoConfiguration
@ComponentScan
@SpringBootApplication
public class TravelAgencyApplication {


	/**
	before starting do...
	 exec dbms_saga_adm.add_broker(broker_name => 'TEST');

	 -- If coordinator is co-located with broker,
	 --dblink_to_broker should be NULL or equal to the dblink_to_participant/coordinator.
	 exec dbms_saga_adm.add_coordinator(
	 coordinator_name => 'TravelCoordinator',
	 dblink_to_broker => null,
	 mailbox_schema => 'admin',
	 broker_name => 'TEST',
	 dblink_to_coordinator => 'travelagencyadminlink');

	 exec dbms_saga_adm.add_coordinator( coordinator_name => 'TravelCoordinator',  dblink_to_broker => null,   mailbox_schema => 'admin',  broker_name => 'TEST',  dblink_to_coordinator => 'travelagencyadminlink');





	 and also wanted to confirm that for JMS the callback should be null, so eg
	 exec dbms_saga_adm.add_participant(participant_name=> 'TravelAgency' , dblink_to_broker=> null,mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> null);
	 and
	 exec dbms_saga_adm.add_participant(participant_name=> 'Car' , dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin',broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink');
	 */



	public static void main(String[] args) throws Exception {
//		ConfigurableApplicationContext context = SpringApplication.run(TravelAgencyApplicaiton.class, args);
		System.setProperty("oracle.jdbc.fanEnabled", "false");
		new TravelAgencyApplication().beginAndEnroll();
	}


	public void beginAndEnroll() throws Exception {
		AQjmsSaga saga = new AQjmsSaga("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1", "admin", "Welcome12345");
		MainTestListener listener = new MainTestListener();
		System.out.println("TravelAgencyApplication.beginAndEnroll setSagaMessageListener...");
		saga.setSagaMessageListener("ADMIN", "TravelAgencyJava2", listener);
		System.out.println("TravelAgencyApplication.beginAndEnroll beginSaga...");
		String sagaId = saga.beginSaga("TravelAgencyJava2");
		System.out.println(sagaId);
		String payload = "[{\"car\" : \"toyota2\"}]";
		System.out.println("TravelAgencyApplication.beginAndEnroll enrollParticipant CarPLSQL...");
		saga.enrollParticipant(sagaId, "admin", "TravelAgencyJava2", "CarJava", "TravelCoordinator", payload);

		System.in.read();
			System.in.read();
		//saga.rollbackSaga("D24480320F484F10E053E698F80AECAB", "TRAVELAGENCY");
	}

	public void send() throws Exception {
		OracleDataSource ds = new OracleDataSource();
		ds.setUser("admin");
		ds.setPassword("Welcome12345");
		ds.setURL("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1");
		System.out.println("TravelParticipant.main ds.getConnection():" + ds.getConnection());
		TopicSession session = null;
		try {
			TopicConnectionFactory q_cf = AQjmsFactory.getTopicConnectionFactory(ds);
			TopicConnection q_conn = q_cf.createTopicConnection();
			session = q_conn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
			OracleConnection jdbcConnection = ((OracleConnection)((AQjmsSession) session).getDBConnection());
			Topic topic = ((AQjmsSession) session).getTopic("ADMIN", "TESTQUEUE");
			System.out.println("updateDataAndSendEvent topic:" + topic);
			TextMessage objmsg = session.createTextMessage();
			TopicPublisher publisher = session.createPublisher(topic);
			objmsg.setText("teststring");
//			objmsg.setJMSPriority(2);
			System.out.println("about to publish");
            publisher.publish(topic, objmsg);
//            publisher.publish(topic, objmsg, DeliveryMode.PERSISTENT,2, AQjmsConstants.EXPIRATION_NEVER);
			session.commit();
		} catch (Exception e) {
			System.out.println("updateDataAndSendEvent failed with exception:" + e);
			if (session != null) {
				try {
					session.rollback();
				} catch (JMSException e1) {
					System.out.println("updateDataAndSendEvent session.rollback() failed:" + e1);
				} finally {
					throw e;
				}
			}
			throw e;
		} finally {
			if (session != null) session.close();
		}
	}

}
