package osaga.springboot.travelparticipant;

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
		String initiator = "TravelAgencyJava5";
		AQjmsSaga saga = new AQjmsSaga("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1", "admin", "Welcome12345");
		TravelAgencyTestListener listener = new TravelAgencyTestListener();
		System.out.println("TravelAgencyApplication.beginAndEnroll setSagaMessageListener...");
		saga.setSagaMessageListener("ADMIN", initiator, listener);
		System.out.println("TravelAgencyApplication.beginAndEnroll beginSaga... initiator/sender:" + initiator);
		String sagaId = saga.beginSaga(initiator);
		System.out.println(sagaId);
		String payload = "[{\"car\" : \"toyota2\"}]";
		System.out.println("TravelAgencyApplication.beginAndEnroll enrollParticipant CarJava...");
		saga.enrollParticipant(sagaId, "admin", initiator, "CarJava", "TravelCoordinator", payload);
		System.in.read();
			System.in.read();
		//saga.rollbackSaga("D24480320F484F10E053E698F80AECAB", "TRAVELAGENCY");
	}

	public class TravelAgencyTestListener extends AQjmsSagaMessageListener{

		@Override
		public String request(String sagaId, String payload) {
			throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
		}

		@Override
		public void response(String sagaId, String payload) {
			System.err.println(payload);
			System.out.println("Got re!");
		}

		@Override
		public void beforeCommit(String sagaId) {
			System.out.println("Before Commit Called");
		}

		@Override
		public void afterCommit(String sagaId) {
			System.out.println("After Commit Called");
		}

		@Override
		public void beforeRollback(String sagaId) {
			System.out.println("before rb");
		}

		@Override
		public void afterRollback(String sagaId) {
			System.out.println("after rb");
		}

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

	public static void main0(String args[]) {
		String username = "admin";
		String password = "test";
		String url = "jdbc:oracle:thin:@//slc17qxb.us.oracle.com:1581/cdb1_pdb2.regress.rdbms.dev.us.oracle.com";
		String url1 = "jdbc:oracle:thin:@//slc17qxb.us.oracle.com:1581/cdb1_pdb3.regress.rdbms.dev.us.oracle.com";
		// Travelagency java
		try {
			AQjmsSaga saga = new AQjmsSaga(url, username, password);
			MainTestListener listener = new MainTestListener();
			saga.setSagaMessageListener("ADMIN", "TRAVELAGENCY", listener);
			String sagaId = saga.beginSaga("TRAVELAGENCY");
			System.out.println(sagaId);
			String payload = "[{\"flight\" : \"United\"}]";
			saga.enrollParticipant(sagaId, "ADMIN", "TRAVELAGENCY", "AIRLINE", "TACOORDINATOR", payload);
			//saga.rollbackSaga("D24480320F484F10E053E698F80AECAB", "TRAVELAGENCY");
			try {
				System.in.read();
				System.in.read();
				//saga.rollbackSaga("D1C241C10B916B0DE053E698F80A889C", "TRAVELAGENCY");
			} catch (IOException ex) {
				Logger.getLogger(MainTest.class.getName()).log(Level.SEVERE, null, ex);
			}

		} catch (JMSException ex) {
			Logger.getLogger(MainTest.class.getName()).log(Level.SEVERE, null, ex);
		}

// Airline Java
//        try {
//            AQjmsSaga saga = new AQjmsSaga(url1, username, password);
//            MainTestListener1 listener = new MainTestListener1();
//            saga.setSagaMessageListener("ADMIN", "AIRLINE", listener);
//            System.in.read();
//            System.in.read();
//        } catch (JMSException ex) {
//            Logger.getLogger(MainTest.class.getName()).log(Level.SEVERE, null, ex);
//        } catch (IOException ex) {
//            Logger.getLogger(MainTest.class.getName()).log(Level.SEVERE, null, ex);
//        }

}
