package osaga.travelagency;

import AQSaga.*;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.CallableStatement;
import java.sql.Connection;

import org.json.*;

import static java.lang.System.*;


public class TravelAgencyApplication {

	public static void main	(String[] args) throws Exception {
		setProperty("oracle.jdbc.fanEnabled", "false");
		new TravelAgencyApplication().bookTravel();
	}

	//very simple single requests (ie does not support concurrent requests)
	String flightStatus = "", hotelStatus = "", carStatus = "";

	public void bookTravel() throws Exception {
		//Get all values...
		String password = PromptUtil.getValueFromPromptSecure("Enter password", null);
		Path path = Paths.get(System.getProperty("user.dir"));
		String parentOfCurrentWorkingDir = "" + path.getParent();
		String TNS_ADMIN = PromptUtil.getValueFromPrompt("Enter TNS_ADMIN (unzipped wallet location)", parentOfCurrentWorkingDir + "/" + "wallet");
		String jdbcUrl = "jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=" + TNS_ADMIN;
		String user = "admin";
		out.println("TravelAgencyApplication jdbcUrl:" + jdbcUrl);
		String initiator = "TravelAgencyJava";
		boolean callAddParticipant =
				PromptUtil.getValueFromPrompt(
						"Is one-time setup call 'add_participant' needed for " + initiator + " ('y' if this has not been done previously, 'n' otherwise)?", "n").equalsIgnoreCase("y");
		if (callAddParticipant) {
			PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
			poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
			poolDataSource.setURL(jdbcUrl);
			poolDataSource.setUser(user);
			poolDataSource.setPassword(password);
			Connection conn = poolDataSource.getConnection();
			CallableStatement callableStatement = conn.prepareCall(
					"{call dbms_saga_adm.add_participant(  participant_name => ?,   " +
					"coordinator_name => 'TravelCoordinator' ,   dblink_to_broker => null ,   " +
					"mailbox_schema => 'admin' ,   broker_name => 'TEST' ,   callback_package => null ,   " +
					"dblink_to_participant => null)}");
			callableStatement.setString(1, initiator);
			callableStatement.execute();
			out.println("add_participant successfully called for initiator:" + initiator );
		}
		out.println("Adding listener for this saga initiator:" + initiator + "...");
		AQjmsSaga saga = new AQjmsSaga(jdbcUrl, "admin", password);
		TravelAgencyTestListener listener = new TravelAgencyTestListener();
		saga.setSagaMessageListener("ADMIN", initiator, listener);

		runSaga(initiator, saga);
		if (PromptUtil.getValueFromPrompt("Start another " + initiator + " saga? (y or n)", "y").equalsIgnoreCase("y"))
			runSaga(initiator, saga);
	}

	private void runSaga(String initiator, AQjmsSaga saga) throws Exception {
		out.println("Beginning saga...");
		String sagaId = saga.beginSaga(initiator);
		out.println("Saga begun sagaId:" + sagaId);

//		String coordinator = PromptUtil.getValueFromPrompt("Enter coordinator name", "TravelCoordinator");
		String coordinator = "TravelCoordinator";

		//Prompt for participants...
		boolean isAddHotel = PromptUtil.getBoolValueFromPrompt("add Hotel(Java) participant? (y or n)", "y");
		boolean isAddCar = PromptUtil.getBoolValueFromPrompt("add Car(Java) participant? (y or n)", "y");
		boolean isAddFlight = PromptUtil.getBoolValueFromPrompt("add Flight(Java) participant? (y or n)", "y");
		out.println("Enrolling participants... ");
		if (isAddFlight) {
			String payload = "[{\"flight\" : \"myflight\"}]";
			out.println("Enrolling Flight(Java) participant in sagaId:" + sagaId);
			saga.enrollParticipant(sagaId, "admin", initiator, "FlightJava", coordinator, payload);
            flightStatus = "waitingforreply";
		}
		if (isAddHotel) {
			String payload = "[{\"hotel\" : \"myhotel\"}]";
			out.println("Enrolling Hotel(Java) participant in sagaId:" + sagaId);
			saga.enrollParticipant(sagaId, "admin", initiator, "HotelJava", coordinator, payload);
			hotelStatus = "waitingforreply";
		}
		if (isAddCar) {
			String payload = "[{\"car\" : \"mycar\"}]";
			out.println("Enrolling Car(Java) participant in sagaId:" + sagaId);
			saga.enrollParticipant(sagaId, "admin", initiator, "CarJava", coordinator, payload);
			carStatus = "waitingforreply";
		}
		boolean isAllRepliesReceived = false;
		while (flightStatus.equals("waitingforreply") || hotelStatus.equals("waitingforreply") || carStatus.equals("waitingforreply")) {
			Thread.sleep(3 * 1000);
		}
		String commitOrRollback = PromptUtil.getValueFromPrompt("Commit or Rollback Saga? (c or r)", "r");
		if (commitOrRollback.equalsIgnoreCase("c")) {
			log("about to commit");
			saga.commitSaga(sagaId, initiator);
			log("finished commit");
			createParticipantStatesForSagaId(sagaId);
		} else {
			log("about to rollback");
			saga.rollbackSaga(sagaId, initiator);
			log("finished rollback");
			createParticipantStatesForSagaId(sagaId);
		}
	}

	private void createParticipantStatesForSagaId(String sagaId) {
		flightStatus = "";
		hotelStatus = "";
		carStatus = "";
	}


	public class TravelAgencyTestListener extends AQjmsSagaMessageListener{

		@Override
		public String request(String sagaId, String payload) {
			throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
		}

		@Override
		public void response(String sagaId, String payload) {
			out.println("Response received:" + payload);
			JSONObject obj = new JSONObject(payload);
			if (obj.getString("HotelJava") != null) hotelStatus = "replyReceived";
			else if (obj.getString("CarJava") != null) carStatus = "replyReceived";
			else if (obj.getString("FlightJava") != null) flightStatus = "replyReceived";
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
		}

	}


	void log (String msg) {
		out.println("TravelAgencyApplication.log msg:" + msg);
	}

}
