package com.example.tollreader;

import jakarta.jms.JMSException;
import jakarta.jms.Message;
import jakarta.jms.Session;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;
import java.security.SecureRandom;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessageCreator;

@EnableJms
@SpringBootApplication
public class TollreaderApplication implements CommandLineRunner {

	private static final SecureRandom random = new SecureRandom();
	private static final Integer minNumber = 10000;
	private static final Integer maxNumber = 99999;

	@Autowired
	private JmsTemplate jmsTemplate;

	private static <T extends Enum<?>> T randomEnum(Class<T> clazz) {
		int x = random.nextInt(clazz.getEnumConstants().length);
		return clazz.getEnumConstants()[x];
	}

	private void sendMessage(JsonObject tolldata) {
		// jmsTemplate.convertAndSend("TollGate", tolldata);
		jmsTemplate.send("TollGate", new MessageCreator() {

			@SuppressWarnings("null")
			@Override
			public Message createMessage(Session session) throws JMSException {
				return session.createTextMessage(tolldata.toString());
			}

		});
	}

	@Override
	public void run(String... args) throws Exception {
		// System.out.println("Args: " + args[0] + " " + args.length);
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
		LocalDateTime now = LocalDateTime.now();
		String dateTimeString = now.format(formatter);
		Integer sleepTime = 1000;
		Integer numRecords = 100000;
		if (args.length > 0 && !args[0].isBlank()) {
			sleepTime = Integer.parseInt(args[0]);
		}

		for (int i = 0; i < numRecords; i++) {
			Thread.sleep(sleepTime);

			Integer licNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer tagId = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer accountNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			String state = randomEnum(State.class).toString();
			String carType = randomEnum(CarType.class).toString();

			JsonObject data = Json.createObjectBuilder()
				.add("accountnumber", accountNumber) // This could be looked up in the DB from the tagId?
				.add("license-plate", state + "-" + licNumber.toString()) // This could be looked up in the DB from the tagId?
				.add("cartype", carType) // This could be looked up in the DB from the tagId?
				.add("tagid", tagId)
				.add("timestamp", dateTimeString)
				.build();

			System.out.println(data);
			sendMessage(data);

		}
	}

	public static void main(String[] args) {
		SpringApplication.run(TollreaderApplication.class, args);
	}

}
