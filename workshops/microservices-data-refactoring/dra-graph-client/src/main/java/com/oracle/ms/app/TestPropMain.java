package com.oracle.ms.app;

public class TestPropMain {

	public static void main(String[] args) {
		/*
		 * FileProperties properties = new FileProperties();
		 * System.out.println(properties.readProperty("tenant"));
		 * 
		 */
		int maxIterations = 1;
		
		try {
			if (args.length > 0) {
				maxIterations = Integer.parseInt(args[0]);
			}
		} catch (ArrayIndexOutOfBoundsException aiex) {
			aiex.printStackTrace();
		}
		
		System.out.println(maxIterations);
	}
}
