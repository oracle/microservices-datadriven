// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.labelgenerator;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LabelGeneratorApplication implements CommandLineRunner {

	private static final String outputFile = "target/cars.jsonl";
	private static final String inputFile = "src/main/resources/input-files.txt";

	public static void main(String[] args) {
		SpringApplication.run(LabelGeneratorApplication.class, args);
	}

	@Override
	public void run(String... args) {
		// do the things

		// open input and output files
		try (
			BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile));
			BufferedReader reader = new BufferedReader(new FileReader(inputFile))
		) {

			// write header to output
			writer.write(header);

			// iterate through input a line at a time
			String line;
			while ((line = reader.readLine()) != null) {
				// for each line, write out record, substitute path and type
				String type = line.split("/")[1];
				writer.write(record.replace("XX_PATH_XX", line).replace("XX_TYPE_XX", type));
			}
		    	
		} catch (IOException e) {
			// ignore
		}

	}

	private static final String header = """
			{
				"labelsSet": [{ "name": "type" }],
				"annotationFormat": "SINGLE_LABEL",
				"datasetFormatDetails": { "formatType": "TEXT" }
			}
			""";

	private static final String record = """
			{
				"sourceDetails": { "path": "XX_PATH_XX" },
				"annotations": [
				  {
					"entities": [
					  {
						"entityType": "GENERIC",
						"labels": [{ "type": "XX_TYPE_XX" }]
					  }
					]
				  }
			   ]
			}
			""";

}
