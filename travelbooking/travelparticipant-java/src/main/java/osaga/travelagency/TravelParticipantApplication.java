package osaga.travelagency;

import AQSaga.AQjmsSaga;
import AQSaga.AQjmsSagaMessageListener;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.CallableStatement;
import java.sql.Connection;

import static java.lang.System.out;

public class TravelParticipantApplication {

	static {
		System.setProperty("oracle.jdbc.fanEnabled", "false");
	}
	String participant;

	public static void main(String[] args) throws Exception {
		new TravelParticipantApplication().participate();
	}

	public void participate() throws Exception {
		//Get all values...
		String password = PromptUtil.getValueFromPromptSecure("Enter password", null);
		Path path = Paths.get(System.getProperty("user.dir"));
		String parentOfCurrentWorkingDir = "" + path.getParent();
		String TNS_ADMIN = PromptUtil.getValueFromPrompt("Enter TNS_ADMIN (unzipped wallet location)", parentOfCurrentWorkingDir + "/" + "wallet");
		String jdbcUrl = "jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=" + TNS_ADMIN;
		String user = "admin";
		out.println("TravelParticipantApplication jdbcUrl:" + jdbcUrl);

		participant = PromptUtil.getValueFromPrompt("Enter participant type (1) HotelJava, (2) CarJava, or (3) FlightJava", "1");
		if (participant.equalsIgnoreCase("2")) participant = "CarJava";
		else if (participant.equalsIgnoreCase("3")) participant = "FlightJava";
		else participant = "HotelJava";
		boolean callAddParticipant =
				PromptUtil.getValueFromPrompt(
						"Is one-time setup call 'add_participant' needed for " + participant + " ('y' if this has not been done previously, 'n' otherwise)?", "n").equalsIgnoreCase("y");
		if (callAddParticipant) {
			PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
			poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
			poolDataSource.setURL(jdbcUrl);
			poolDataSource.setUser(user);
			poolDataSource.setPassword(password);
			Connection conn = poolDataSource.getConnection();
			CallableStatement callableStatement = conn.prepareCall(
					"{call dbms_saga_adm.add_participant(participant_name=> ? ,  " +
					"dblink_to_broker=> 'travelagencyadminlink',mailbox_schema=> 'admin'," +
					"broker_name=> 'TEST', callback_package => null , dblink_to_participant=> 'participantadminlink')}");
			callableStatement.setString(1, participant);
			callableStatement.execute();
			out.println("add_participant call successful for participant:" + participant + "...");
		}
		out.println("Adding listener for this saga participant:" + participant + "...");
		AQjmsSaga saga = new AQjmsSaga(jdbcUrl, user, password);
		TravelParticipantSagaMessageListener listener = new TravelParticipantSagaMessageListener();
		saga.setSagaMessageListener("ADMIN", participant, listener);

		while(true) Thread.sleep(1000 * 10);
	}

	public class TravelParticipantSagaMessageListener extends AQjmsSagaMessageListener {

		//in-memory
		int tickets = 2;

		@Override
		public String request(String sagaId, String payload) {
			System.out.println("request called sagaId = " + sagaId + ", payload = " + payload);
			System.out.println("Tickets remaining : " + --tickets);
			if(tickets >= 0)
				return "{\"" + participant + "\":\"success\"}";
			else
				return "{\"" + participant + "\":\"failed\"}";
		}

		@Override
		public void response(String sagaId, String payload) {
			System.out.println("response called sagaId = " + sagaId + ", payload = " + payload);
		}

		@Override
		public void beforeCommit(String sagaId) {
			out.println("Before Commit Called");
		}

		@Override
		public void afterCommit(String sagaId) {
			out.println("After Commit Called");
		}

		@Override
		public void beforeRollback(String sagaId) {
			out.println("Before Rollback Called");
		}

		@Override
		public void afterRollback(String sagaId) {
			out.println("After Rollback Called");
			tickets++;
			System.out.println("Total Tickets : " + tickets);
		}

	}

}
