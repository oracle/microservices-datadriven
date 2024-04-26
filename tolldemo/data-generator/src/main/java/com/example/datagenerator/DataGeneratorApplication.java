package com.example.datagenerator;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

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

	private static final Random rand = new Random();

	private static final String personSql = """
			insert into customer (customer_id, account_number, first_name, last_name, address, city, zipcode)
			values ('X1', 'X2', 'X3', 'X4', 'X5', X6', 'X7')
			""";

	private static final String vehicleSql = """
			insert into vehicle (vehicle_id, customer_id, tag_id, state, license_plate, vehicle_type)
			values ('X1', 'X2', 'X3', 'X4', 'X5', 'X6')
			""";

	public static void main(String[] args) {
		SpringApplication.run(DataGeneratorApplication.class, args);
	}

	@Override
	public void run(String... args) {

		ArrayList<String> mensNames = new ArrayList<>();
		ArrayList<String> womensNames = new ArrayList<>();
		ArrayList<String> surnames = new ArrayList<>();
		ArrayList<String> streetNames = new ArrayList<>();
		ArrayList<Location> locations = new ArrayList<>();
	
		try (
			BufferedReader mensNamesReader = new BufferedReader(new FileReader(mensNamesFile));
			BufferedReader womensNamesReader = new BufferedReader(new FileReader(womensNamesFile));
			BufferedReader surnamesReader = new BufferedReader(new FileReader(surnamesFile));
			BufferedReader streetNamesReader = new BufferedReader(new FileReader(streetNamesFile));
			BufferedReader zipcodeReader = new BufferedReader(new FileReader(zipcodesFile));
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

			System.out.println("Finished loading source data:");
			System.out.println("men's names: " + mensNames.size());
			System.out.println("women's names: " + womensNames.size());
			System.out.println("surnames: " + surnames.size());
			System.out.println("street names: " + streetNames.size());
			System.out.println("locations: " + locations.size());

		} catch (IOException ignore) {}

		try (
			BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile));
		) {
			// do the things
		} catch (IOException ignore) {}
	}

	private record Location (String zipcode, String city) {};

}
