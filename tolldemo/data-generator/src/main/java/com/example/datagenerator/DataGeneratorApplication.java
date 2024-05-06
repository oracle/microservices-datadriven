// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.datagenerator;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
// import java.util.List;
import java.util.Random;
import java.util.UUID;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DataGeneratorApplication implements CommandLineRunner {

	private static final String outputFile = "target/load-data.sql";
	private static final String mensNamesFile = "src/main/resources/mens-names.txt";
	private static final String womensNamesFile = "src/main/resources/womens-names.txt";
	private static final String surnamesFile = "src/main/resources/surnames.txt";
	private static final String streetNamesFile = "src/main/resources/street-names.txt";
	private static final String zipcodesFile = "src/main/resources/nj-zipcodes-placenames.txt";
	private static final String imagesFile = "src/main/resources/input-files.txt";

	private static final Random rand = new Random();
	private static final int NUM_VEHICLES = 1_000_000;

	private static final String personSql = """
			insert into customer (customer_id, account_number, first_name, last_name, address, city, zipcode)
			values ('X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7');
			""";

	private static final String vehicleSql = """
			insert into vehicle (vehicle_id, customer_id, tag_id, state, license_plate, vehicle_type, image)
			values ('X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7');
			""";

	private static ArrayList<String> mensNames = new ArrayList<>();
	private static ArrayList<String> womensNames = new ArrayList<>();
	private static ArrayList<String> surnames = new ArrayList<>();
	private static ArrayList<String> streetNames = new ArrayList<>();
	private static ArrayList<Location> locations = new ArrayList<>();
	private static ArrayList<Image> images = new ArrayList<>();

	public static void main(String[] args) {
		SpringApplication.run(DataGeneratorApplication.class, args);
	}

	@Override
	public void run(String... args) {
	
		try (
			BufferedReader mensNamesReader = new BufferedReader(new FileReader(mensNamesFile));
			BufferedReader womensNamesReader = new BufferedReader(new FileReader(womensNamesFile));
			BufferedReader surnamesReader = new BufferedReader(new FileReader(surnamesFile));
			BufferedReader streetNamesReader = new BufferedReader(new FileReader(streetNamesFile));
			BufferedReader zipcodeReader = new BufferedReader(new FileReader(zipcodesFile));
			BufferedReader imagesReader = new BufferedReader(new FileReader(imagesFile));
		) {
			// read through the input file and set up the source data
			String line;
			while ((line = mensNamesReader.readLine()) != null) {
				mensNames.add(line);
			}

			while ((line = womensNamesReader.readLine()) != null) {
				womensNames.add(line);
			}

			while ((line = surnamesReader.readLine()) != null) {
				surnames.add(line);
			}

			while ((line = streetNamesReader.readLine()) != null) {
				streetNames.add(line);
			}

			while ((line = zipcodeReader.readLine()) != null) {
				String[] location = line.split("\t");
				String zipcode = location[0];
				String city = location[1];
				locations.add(new Location(zipcode, city));
			}

			while ((line = imagesReader.readLine()) != null) {
				String[] image = line.split("/");
				images.add(new Image(image[1], line));
			}

			System.out.println("Finished loading source data:");
			System.out.println("men's names: " + mensNames.size());
			System.out.println("women's names: " + womensNames.size());
			System.out.println("surnames: " + surnames.size());
			System.out.println("street names: " + streetNames.size());
			System.out.println("locations: " + locations.size());
			System.out.println("images: " + images.size());

		} catch (IOException ignore) {}

		try (
			BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile));
		) {
			// do the things
			for (int vehicleCount = 0; vehicleCount < NUM_VEHICLES; vehicleCount++) {

				// we want 1 to 3 vehicles per person
				 int vehiclesForThisPerson = rand.nextInt(3) + 1;

				// create a person
				boolean man = rand.nextBoolean();
				String firstName = (man ? mensNames.get(rand.nextInt(mensNames.size())) 
					: womensNames.get(rand.nextInt(womensNames.size())));
				String lastName = surnames.get(rand.nextInt(surnames.size()));
				String address = "";
				int k = rand.nextInt(4) + 1;
				for (int j = 0; j < k; j++) {
					address = address.concat(randomDigit());
				}
				address = address.concat(" ").concat(streetNames.get(rand.nextInt(streetNames.size())));
				Location l = locations.get(rand.nextInt(locations.size()));
				String city = l.city();
				String zipcode = l.zipcode();
				String accountNumber = randomDigit()
					.concat(randomDigit())
					.concat(randomDigit())
					.concat(randomLetter())
					.concat(randomDigit())
					.concat(randomDigit())
					.concat(randomDigit())
					.concat(randomDigit());
				String customerId = UUID.randomUUID().toString();

				writer.write(personSql.replace("X1", customerId)
					.replace("X2", accountNumber)
					.replace("X3", firstName)
					.replace("X4", lastName)
					.replace("X5", address)
					.replace("X6", city)
					.replace("X7", zipcode));

				// now create the vehicles for this person
				for (int j = 0; j < vehiclesForThisPerson; j++) {

					Vehicle v = generateVehicle();

					writer.write(vehicleSql.replace("X1", v.vehicleId())
						.replace("X2", customerId)
						.replace("X3", v.tagId())
						.replace("X4", v.state())
						.replace("X5", v.licensePlate)
						.replace("X6", v.vehicleType.toUpperCase())
						.replace("X7", v.photoFilename()));
					vehicleCount++;
				}

			}


		} catch (IOException ignore) {}
	}

	private Vehicle generateVehicle() {
		Image image = images.get(rand.nextInt(images.size()));
		String vehicleId = UUID.randomUUID().toString();
		String tagId = UUID.randomUUID().toString();
		String state = State.randomStateCode();
		String licensePlate = randomLetter()
			.concat(randomLetter())
			.concat(randomLetter())
			.concat(randomDigit())
			.concat(randomDigit())
			.concat(randomDigit());
		return new Vehicle(vehicleId, tagId, state, licensePlate, image.vehicleType, image.filename);
	}

	private String randomLetter() {
		char[] c =new char[1];
		c[0] = (char)(rand.nextInt(26) + 'A');
		return new String(c);
	}

	private String randomDigit() {
		char[] c = new char[1];
		c[0] = (char)(rand.nextInt(10) + '0');
		return new String(c);
	}

	private record Vehicle (String vehicleId, String tagId, String state, String licensePlate, String vehicleType, String photoFilename) {};
	private record Location (String zipcode, String city) {};
	private record Image (String vehicleType, String filename) {};

}
