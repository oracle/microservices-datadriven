package osaga.springboot.travelparticipant;

import AQSaga.AQjmsSaga;
import AQSaga.AQjmsSagaMessageListener;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

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
		TravelParticipantSagaMessageListener listener = new TravelParticipantSagaMessageListener();
		System.out.println("TravelParticipantApplication.participate listener:" + listener);
		System.out.println("TravelParticipantApplication.participate setSagaMessageListener...");
		aqjmsSaga.setSagaMessageListener("ADMIN", "CarJava", listener, true);
		System.in.read();
		System.in.read();
	}



	public class TravelParticipantSagaMessageListener extends AQjmsSagaMessageListener {

		//in-memory
		int tickets = 2;

		@Override
		public String request(String sagaId, String payload) {
			System.out.println("Tickets remaining : " + --tickets);
			String response = "";
			if(tickets >= 0)
				return "[{\"result\":\"success\"}]";
			else
				return "[{\"result\":\"failure\"}]";
		}

		@Override
		public void response(String sagaId, String payload) {
			System.err.println(payload);
			System.out.println("Got resp!");
		}

		@Override
		public void beforeCommit(String sagaId) {
			System.out.println("bc Called");
		}

		@Override
		public void afterCommit(String sagaId) {
			System.out.println("ac Called");
		}

		@Override
		public void beforeRollback(String sagaId) {
			System.out.println("before rb");
			tickets++;
			System.out.println("Total Tickets : " + tickets);
		}

		@Override
		public void afterRollback(String sagaId) {
			System.out.println("after rb");
		}

	}

}
