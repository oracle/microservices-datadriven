package io.helidon.data.examples.aiml;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class FoodWinePairingRecommender {
	
	public String suggestSuitableWineForFood(String foodItem) {
		BufferedReader in = null;
		BufferedReader err = null;
		try {

			String currentDir = System.getProperty("user.dir");
			System.out.println("Current dir using System:" + currentDir);

			ProcessBuilder builder = new ProcessBuilder("python","foodwinepairing\\Wine Food Pairings.py", foodItem);
			
			Process rt = builder.start();
			int exitCode = rt.waitFor();
			System.out.println("Process exited with : " + exitCode);
			in = new BufferedReader(new InputStreamReader(rt.getInputStream()));
			err = new BufferedReader(new InputStreamReader(rt.getErrorStream()));

			System.out.println("Python file output:");
			String line;
			BufferedReader reader;
			if (exitCode != 0) {
				reader = err;
			} else {
				reader = in;
			}
			
			
			String recommendedWines = "";
			while ((line = reader.readLine()) != null) {
				System.out.println(line);
				if (line.startsWith("## Recommended Wines ## ")) {
					recommendedWines = line.split("## Recommended Wines ##")[1];
				}
			}
			System.out.println("recommendedWines : " + recommendedWines);
			return recommendedWines;
		} catch (IOException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				if (in != null) {
					in.close();
				} 
				if (err != null) {
					err.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return null;
		
	}

}
