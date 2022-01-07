package osaga.springboot.travelparticipant;

import AQSaga.*;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import java.io.*;
import java.util.Arrays;

import static java.lang.System.*;


@Configuration
@EnableAutoConfiguration
@ComponentScan
@SpringBootApplication
public class TravelAgencyApplication {


	public static void main(String[] args) throws Exception {
		setProperty("oracle.jdbc.fanEnabled", "false");
		new TravelAgencyApplication().beginAndEnroll();
	}

	public void beginAndEnroll() throws Exception {

		char password[] = null;
		try {
			password = PasswordField.getPassword(in, "Enter your password: ");
		} catch(IOException ioe) {
			ioe.printStackTrace();
		}
		if(password == null ) {
			out.println("No password entered");
		} else {
			out.println("The password entered is: "+String.valueOf(password));
		}

		String initiator = "TravelAgencyJava";
		AQjmsSaga saga = new AQjmsSaga("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1", "admin", "Welcome12345");
		TravelAgencyTestListener listener = new TravelAgencyTestListener();
		out.println("TravelAgencyApplication.beginAndEnroll setSagaMessageListener...");
		saga.setSagaMessageListener("ADMIN", initiator, listener);
		out.println("TravelAgencyApplication.beginAndEnroll beginSaga... initiator/sender:" + initiator);
		String sagaId = saga.beginSaga(initiator);
		String payload = "[{\"car\" : \"toyota2\"}]";
		out.println("TravelAgencyApplication.beginAndEnroll enrollParticipant CarJava... sagaId:" + sagaId);
		saga.enrollParticipant(sagaId, "admin", initiator, "CarJava", "TravelCoordinator", payload);
		//todo wait/poll for all replies
		in.read();
		out.println("hit enter again to rollback ");
		in.read();
		log("about to rollback");
		saga.rollbackSaga(sagaId, initiator);
		log("finished rollback");
		in.read();
		in.read();
	}

	void log (String msg) {
		out.println("TravelAgencyApplication.log msg:" + msg);
	}

	public class TravelAgencyTestListener extends AQjmsSagaMessageListener{

		@Override
		public String request(String sagaId, String payload) {
			throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
		}

		@Override
		public void response(String sagaId, String payload) {
			err.println(payload);
			out.println("Got re!");
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
			out.println("before rb");
		}

		@Override
		public void afterRollback(String sagaId) {
			out.println("after rb");
		}

	}


	static class MaskingThread extends Thread {
		private volatile boolean stop;
		private char echochar = '*';

   public MaskingThread(String prompt) {
			out.print(prompt);
		}

		public void run() {

			int priority = Thread.currentThread().getPriority();
			Thread.currentThread().setPriority(Thread.MAX_PRIORITY);

			try {
				stop = true;
				while(stop) {
					out.print("\010" + echochar);
					try {
						// attempt masking at this rate
						Thread.currentThread().sleep(1);
					}catch (InterruptedException iex) {
						Thread.currentThread().interrupt();
						return;
					}
				}
			} finally { // restore the original priority
				Thread.currentThread().setPriority(priority);
			}
		}

		public void stopMasking() {
			this.stop = false;
		}
	}


	public static class PasswordField {

		public static final char[] getPassword(InputStream in, String prompt) throws IOException {
			MaskingThread maskingthread = new MaskingThread(prompt);
			Thread thread = new Thread(maskingthread);
			thread.start();

			char[] lineBuffer;
			char[] buf;
			int i;

			buf = lineBuffer = new char[128];

			int room = buf.length;
			int offset = 0;
			int c;

			loop:   while (true) {
				switch (c = in.read()) {
					case -1:
					case '\n':
						break loop;

					case '\r':
						int c2 = in.read();
						if ((c2 != '\n') && (c2 != -1)) {
							if (!(in instanceof PushbackInputStream)) {
								in = new PushbackInputStream(in);
							}
							((PushbackInputStream)in).unread(c2);
						} else {
							break loop;
						}

					default:
						if (--room < 0) {
							buf = new char[offset + 128];
							room = buf.length - offset - 1;
							arraycopy(lineBuffer, 0, buf, 0, offset);
							Arrays.fill(lineBuffer, ' ');
							lineBuffer = buf;
						}
						buf[offset++] = (char) c;
						break;
				}
			}
			maskingthread.stopMasking();
			if (offset == 0) {
				return null;
			}
			char[] ret = new char[offset];
			arraycopy(buf, 0, ret, 0, offset);
			Arrays.fill(buf, ' ');
			return ret;
		}
	}




}
