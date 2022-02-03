package com.oracle;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;

public class DataSourceSample {  
  // The recommended format of a connection URL is the long format with the
  // connection descriptor.
  final static String DB_URL= "jdbc:oracle:thin:@aqdatabase_tp?TNS_ADMIN=/Users/mayanktayal/Code/Database/Wallet_aqdatabase";
  final static String DB_USER = "admin";
  final static String DB_PASSWORD = "MayankTayal1234";

  public static void main(String args[]) throws SQLException, ClassNotFoundException {

    OracleDataSource ods = new OracleDataSource();
    ods.setURL(DB_URL); 
    ods.setPassword(DB_PASSWORD);
    ods.setUser(DB_USER);
  
    try (OracleConnection connection = (OracleConnection) ods.getConnection()) {
      // Get the JDBC driver name and version 
      DatabaseMetaData dbmd = connection.getMetaData();       
      System.out.println("Driver Name: " + dbmd.getDriverName());
      System.out.println("Driver Version: " + dbmd.getDriverVersion());
      // Print some connection properties
      System.out.println("Default Row Prefetch Value is: " + 
         connection.getDefaultRowPrefetch());
      System.out.println("Database Username is: " + connection.getUserName());
      System.out.println();
      // Perform a database operation 
     // printEmployees(connection);
    }   
  }
 /*
  * Displays first_name and last_name from the employees table.
  */
  public static void printEmployees(Connection connection) throws SQLException {
    // Statement and ResultSet are AutoCloseable and closed automatically. 
    try (Statement statement = connection.createStatement()) {      
      try (ResultSet resultSet = statement
          .executeQuery("select first_name, last_name from employees")) {
        System.out.println("FIRST_NAME" + "  " + "LAST_NAME");
        System.out.println("---------------------");
        while (resultSet.next())
          System.out.println(resultSet.getString(1) + " "
              + resultSet.getString(2) + " ");       
      }
    }   
  } 
}