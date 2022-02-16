package com.oracle;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;
import java.sql.SQLException;

public class DataSourceSample {

	final static String DB_URL = "jdbc:oracle:thin:@aqdatabase_tp?TNS_ADMIN=/home/mayank_tay/oracleAQ/wallet";
	final static String username = "javaUser";

	
	public static void main(String args[]) throws SQLException, ClassNotFoundException {
		
		PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
	       ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
	       ds.setURL(DB_URL);
	       ds.setUser(username);
		
		try (OracleConnection connection = (OracleConnection) ds.getConnection()) {
			// Get the JDBC driver name and version
			DatabaseMetaData dbmd = connection.getMetaData();
			System.out.println("Driver Name: " + dbmd.getDriverName());
			System.out.println("Driver Version: " + dbmd.getDriverVersion());
			// Print some connection properties
			System.out.println("Default Row Prefetch Value is: " + connection.getDefaultRowPrefetch());
			System.out.println("Database Username is: " + connection.getUserName());
			System.out.println();
		}
	}

}