package com.example.tollreader;

import jakarta.json.Json;
import jakarta.json.JsonObject;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;
import java.security.SecureRandom;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TollreaderApplication implements CommandLineRunner {

	private static final SecureRandom random = new SecureRandom();
	private static final Integer minNumber = 10000;
	private static final Integer maxNumber = 99999;

	private static <T extends Enum<?>> T randomEnum(Class<T> clazz) {
		int x = random.nextInt(clazz.getEnumConstants().length);
		return clazz.getEnumConstants()[x];
	}

	public static void main(String[] args) {
		SpringApplication.run(TollreaderApplication.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

		for (int i = 0; i < 10; i++) {
			Thread.sleep(1000);

			LocalDateTime now = LocalDateTime.now();
			String dateTimeString = now.format(formatter);
			Integer licNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer tagId = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer accountNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			String state = randomEnum(State.class).toString();
			String carType = randomEnum(CarType.class).toString();
			// System.out.println(now);

			JsonObject data = Json.createObjectBuilder()
			.add("accountnumber", accountNumber) // This could be looked up in the DB from the tagId?
			.add("license-plate", state + "-" + licNumber.toString()) // This could be looked up in the DB from the tagId?
			.add("cartype", carType) // This could be looked up in the DB from the tagId?
			.add("tagid", tagId)
			.add("timestamp", dateTimeString)
			.build();

			System.out.println(data);

		}

	}

}
