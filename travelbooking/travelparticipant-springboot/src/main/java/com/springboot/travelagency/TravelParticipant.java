package com.springboot.travelagency;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.core.JmsTemplate;

import javax.jms.*;
import javax.sql.DataSource;
import java.sql.SQLException;

@Configuration
@EnableAutoConfiguration
@ComponentScan
@SpringBootApplication
public class TravelParticipant {

	public static void main(String[] args) throws Exception {
//		ConfigurableApplicationContext context = SpringApplication.run(TravelParticipant.class, args);
		new TravelParticipant().listen();
	}
	public  void listen() throws Exception {
		OracleDataSource ds = new OracleDataSource();
		ds.setUser("hoteladmin");
		ds.setPassword("Welcome12345");
		ds.setURL("jdbc:oracle:thin:@teqtest2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_TEQTest2");
		System.out.println("TravelParticipant.main ds.getConnection():" + ds.getConnection());
		QueueConnectionFactory qcfact = AQjmsFactory.getQueueConnectionFactory(ds);
		QueueSession qsess = null;
		QueueConnection qconn = null;
		AQjmsConsumer consumer = null;
		boolean done = false;
		while (!done) {
//			if (qconn == null || qsess == null || dbConnection == null || dbConnection.isClosed()) {
				qconn = qcfact.createQueueConnection("hoteladmin", "Welcome12345");
				qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
//				qconn.start();
				Queue queue = ((AQjmsSession) qsess).getQueue("hoteladmin", "hotelqueue");
				consumer = (AQjmsConsumer) qsess.createConsumer(queue);
				consumer.setMessageListener(new TravelParticipantMessageListener());
				qconn.start();
//			}
			TextMessage message = (TextMessage) (consumer.receive(-1));
			System.out.println("message received:" + message);
			if (qsess != null) qsess.commit();

		}


	}

	private class TravelParticipantMessageListener implements MessageListener {

		@Override
		public void onMessage(Message message) {

		}
	}
}
