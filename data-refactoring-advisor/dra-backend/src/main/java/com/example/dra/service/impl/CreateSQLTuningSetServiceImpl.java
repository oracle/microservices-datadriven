// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.service.impl;

import com.example.dra.bean.DatabaseDetails;
import com.example.dra.dto.Tables18NodesDto;
import com.example.dra.entity.Tables18NodesEntity;
import com.example.dra.repository.Tables18NodesRepository;
import com.example.dra.service.CreateSQLTuningSetService;
import com.example.dra.utils.FileUtil;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.Resource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class CreateSQLTuningSetServiceImpl implements CreateSQLTuningSetService {

	@Autowired
	DRAUtilsImpl draUtilsImpl;

	@Autowired
	GraphConstructorServiceImpl graphConstructorServiceImpl;
	@Resource
	Tables18NodesRepository tables18NodesRepository;

	@Autowired
    private JdbcTemplate jdbcTemplate;
	
	private SimpleJdbcCall simpleJdbcCall;

	@Value("${spring.datasource.hostname}")
	String hostname;
	@Value("${spring.datasource.port}")
	String port;
	@Value("${spring.datasource.service.name}")
	String serviceName;
	@Value("${spring.datasource.username}")
	String username;
	@Value("${spring.datasource.password}")
	String password;

	@Value("${dra.load.sts.sql.file.path}")
	String sqlFilePath;

	//Logger logger = LoggerFactory.getLogger(CreateSQLTuningSetServiceImpl.class);
	
	private static final String SQL_STORED_PROC = ""
            + " CREATE OR REPLACE PROCEDURE get_book_by_id2 "
            + " ("
            + "  table_name OUT TABLES_18_NODES.TABLE_NAME%TYPE,"
            + " ) AS"
            + " BEGIN"
            + "  SELECT TABLE_NAME INTO table_name from TABLES_18_NODES;"
            + " END;";
	
	//private static final String SQL_STORED_PROC_STS = "CALL DBMS_SQLTUNE.create_sqlset(sqlset_name => '6STS')";

	@Override
	public Tables18NodesEntity createSqlSet(String sqlSetName) {
		
		jdbcTemplate.setResultsMapCaseInsensitive(true);
		
	//	System.out.println("Creating Store Procedures and Function...");
     //   jdbcTemplate.execute(SQL_STORED_PROC);

     //   simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate).withProcedureName("get_book_by_id");
        
		 System.out.println("Creating SQL SET Procedure");
		 //jdbcTemplate.execute(SQL_STORED_PROC_STS);
        
		return null;
	}
	
	public void start() {
		Tables18NodesEntity test = createSqlSet("anc");
	}
	
    @PostConstruct
    void init() {
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate).withProcedureName("get_book_by_id");
    }

	@Override
	public List<Tables18NodesDto> getTableName() {

		List<Tables18NodesDto> tables18NodesDtos = new ArrayList<>();
		Tables18NodesDto tables18NodesDto = new Tables18NodesDto();
		tables18NodesDto.setTable_name("table1");
		tables18NodesDtos.add(tables18NodesDto);
		tables18NodesDto = new Tables18NodesDto();
		tables18NodesDto.setTable_name("table2");
		tables18NodesDtos.add(tables18NodesDto);

		List<Tables18NodesEntity> tables18NodesEntities = tables18NodesRepository.findAll();

		for(Tables18NodesEntity tables18NodesEntity : tables18NodesEntities){
			System.out.println("Table Name :: " + tables18NodesEntity.getTableName());
		}


		return tables18NodesDtos;
	}

	@Override
	public String createSQLTuningSet(DatabaseDetails databaseDetails) {

		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		//System.out.println(dbUrlConnectionStr);

		Connection connection = null;
		CallableStatement callableStatement = null;
		boolean result = true;
		try {
			// Establishing a connection to the database
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			// Creating a CallableStatement for invoking DBMS_SQLTUNE
			String SQL_STORED_PROC_STS = "CALL DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => '"+databaseDetails.getSqlSetName()+"')";
			callableStatement = connection.prepareCall(SQL_STORED_PROC_STS);
			result = callableStatement.execute();
			System.out.println("result :: " + result);

		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: "+e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (callableStatement != null) {
					callableStatement.close();
				}
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}

		if(!result) {
			return "SQL Tuning Set '"+ databaseDetails.getSqlSetName() +"' Created";
		} else {
			return "Error in Creating SQL Tuning Set '"+databaseDetails.getSqlSetName()+"'";
		}
	}

	@Override
	public String dropSQLTuningSet(DatabaseDetails databaseDetails) {

		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		//System.out.println(dbUrlConnectionStr);

		Connection connection = null;
		CallableStatement callableStatement = null;
		boolean result = false;
		try {
			// Establishing a connection to the database
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			// Creating a CallableStatement for invoking DBMS_SQLTUNE
			String SQL_STORED_PROC_STS = "CALL DBMS_SQLTUNE.DROP_SQLSET(sqlset_name => '"+databaseDetails.getSqlSetName()+"')";
			callableStatement = connection.prepareCall(SQL_STORED_PROC_STS);
			result = callableStatement.execute();
			System.out.println("result :: " + result);

		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: "+e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (callableStatement != null) {
					callableStatement.close();
				}
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}

		if(!result) {
			return "STS '"+ databaseDetails.getSqlSetName() +"' Dropped";
		} else {
			return "Error in Dropping STS '"+databaseDetails.getSqlSetName()+"'";
		}
	}



	@Override
	public String loadSQLTuningSet(DatabaseDetails databaseDetails) {
		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		Connection connection = null;
		String resultLoadSts = "";
		try {
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			String resultExecute = executeQueries(databaseDetails,null);
			System.out.println("Is Queries Quecuted? " + resultExecute);
			boolean isLoadSTSSuccess = LoadSQLTuningSet(databaseDetails);
			if(isLoadSTSSuccess) {
				resultLoadSts = "SQL Tuning Set '"+ databaseDetails.getSqlSetName() +"' Loaded Successfully";
			} else {
				resultLoadSts = "Error in Loading SQL Tuning Set '"+databaseDetails.getSqlSetName()+"'";
			}
			return resultLoadSts;
		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: "+e.getErrorCode());
			e.printStackTrace();
		} finally {
			try {
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}

		return resultLoadSts;
	}



	public String executeQueries(DatabaseDetails databaseDetails, List<String> queries) {
		System.out.println("Executing Queries for Load STS");
		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		Connection connection = null;
		try {
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			Statement s = connection.createStatement();
			for (String query : queries) {
				//System.out.println("Executing Query : " + query);
				s.executeQuery(query);
			}
		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: "+e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return "Queries Executed";
	}

	public boolean LoadSQLTuningSet(DatabaseDetails databaseDetails) {
		boolean isLoadSTSSuccess = true;
		System.out.println("IN LoadSQLTuningSet");
		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		//System.out.println(dbUrlConnectionStr);

		String LOAD_STS_PROC = "declare\n" +
				"mycur dbms_sqltune.sqlset_cursor;\n" +
				"begin\n" +
				"open mycur for\n" +
				"select value (P)\n" +
				"from table" +
				"(dbms_sqltune.select_cursor_cache('parsing_schema_name =upper(''"+databaseDetails.getUsername()+"'') " +
				"and sql_text not like ''%OPT_DYN%'' and sql_text not like ''%NODES%'' and sql_text not like ''%EDGES%''', null, null, null, null,1, null, 'ALL', 'NO_RECURSIVE_SQL')) P;\n" +
				"dbms_sqltune.load_sqlset(sqlset_name => '"+databaseDetails.getSqlSetName()+"', " +
				"populate_cursor => mycur," +
				"sqlset_owner => '"+databaseDetails.getUsername()+"');\n" +
				"end;\n";

		System.out.println("Load STS Query :: "+ LOAD_STS_PROC);
		Connection connection = null;
		CallableStatement callableStatement = null;
		try {
			// Establishing a connection to the database
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());

			// Creating a CallableStatement for invoking DBMS_SQLTUNE
			callableStatement = connection.prepareCall(LOAD_STS_PROC);
			isLoadSTSSuccess = callableStatement.execute();
		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: "+e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (callableStatement != null) {
					callableStatement.close();
				}
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return !isLoadSTSSuccess;

	}

	@Override
	public String collectSQLTuningSet(DatabaseDetails databaseDetails) {
		System.out.println("-----------------------------------------------");
		System.out.println("Input Details of COLLECT SQL TUNING SET API ");
		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		System.out.println("databaseDetails :: " + databaseDetails.toString());
		System.out.println("DB Connection String :: "+dbUrlConnectionStr);
		System.out.println("Username :: "+ databaseDetails.getUsername());
		System.out.println("Password :: "+ databaseDetails.getPassword());
		System.out.println("SQL Tuning Set :: "+ databaseDetails.getSqlSetName());
		System.out.println("-----------------------------------------------");

		Connection connection = null;
		CallableStatement callableStatement = null;
		boolean result = true;
		boolean isLoadSTSSuccess = true;
		try {
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			String SQL_STORED_PROC_STS = "CALL DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => '" + databaseDetails.getSqlSetName() + "')";
			callableStatement = connection.prepareCall(SQL_STORED_PROC_STS);
			result = callableStatement.execute();
			System.out.println("result :: " + result);
			if (!result) {
				List<String> queries = new FileUtil().readLoadStsSimulateFile(sqlFilePath);
				String resultExecute = executeQueries(databaseDetails, queries);
				System.out.println(resultExecute);

				isLoadSTSSuccess = LoadSQLTuningSet(databaseDetails);
				System.out.println(isLoadSTSSuccess);

				graphConstructorServiceImpl.constructGraph(databaseDetails);

			}
		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: " + e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (callableStatement != null) {
					callableStatement.close();
				}
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		if (!result) {
			return "Collected SQL Tuning Set for '" + databaseDetails.getSqlSetName() + "' ";
		} else {
			return "Error in Collecting SQL Tuning Set '" + databaseDetails.getSqlSetName() + "'";
		}
	}

	@Override
	public List<String> getSQLTuningSetList(DatabaseDetails databaseDetails) {
		databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
		System.out.println("-----------------------------------------------");
		System.out.println("Input Details of GET SQL TUNING SET LIST API ");
		String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
		System.out.println("DB Connection String :: "+dbUrlConnectionStr);
		System.out.println("Username :: "+ databaseDetails.getUsername());
		System.out.println("-----------------------------------------------");
		String getSQLTuningSetListQuery = "SELECT ID, NAME, OWNER FROM DBA_SQLSET_DEFINITIONS WHERE ID > 264";
		Connection connection = null;
		List<String> sqlTuningSets = new ArrayList<>();
		try {
			// Establishing a connection to the database
			connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
			Statement s = connection.createStatement();
			ResultSet resultSet = s.executeQuery(getSQLTuningSetListQuery);
			while (resultSet.next()) {
				// Retrieve column values from the current row
				sqlTuningSets.add(resultSet.getString("NAME"));
			}
			System.out.println("Number of SQL Tuning Sets :: " + sqlTuningSets.size());
			return sqlTuningSets;
		} catch (SQLException e) {
			System.out.println("SQLException, Error Code :: " + e.getErrorCode());
			e.printStackTrace();
		} finally {
			// Closing the resources
			try {
				if (connection != null) {
					connection.close();
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return sqlTuningSets;
	}



}
