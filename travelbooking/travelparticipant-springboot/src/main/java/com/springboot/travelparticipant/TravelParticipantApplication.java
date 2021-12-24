package com.springboot.travelparticipant;

import AQSaga.AQjmsSaga;
import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.*;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import javax.jms.*;

@Configuration
@EnableAutoConfiguration
@ComponentScan
@SpringBootApplication
public class TravelParticipantApplication {

	public static void main(String[] args) throws Exception {
//		ConfigurableApplicationContext context = SpringApplication.run(TravelParticipant.class, args);
		System.setProperty("oracle.jdbc.fanEnabled", "false");
		new TravelParticipantApplication().participate();
	}

	public void participate() throws Exception {
            AQjmsSaga aqjmsSaga = new AQjmsSaga("jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1", "admin", "Welcome12345");
		System.out.println("TravelParticipantApplication.participate aqjmsSaga:" + aqjmsSaga);
        MainTestListener1 listener = new MainTestListener1();
		System.out.println("TravelParticipantApplication.participate listener:" + listener);
		System.out.println("TravelParticipantApplication.participate setSagaMessageListener...");
		aqjmsSaga.setSagaMessageListener("ADMIN", "CarJava", listener, true);
		System.in.read();
		System.in.read();
	}


	private class TravelParticipantMessageListener implements MessageListener {

		@Override
		public void onMessage(Message message) {
			System.out.println("TravelParticipantMessageListener.onMessage message:" +  message);
		}
	}
}
