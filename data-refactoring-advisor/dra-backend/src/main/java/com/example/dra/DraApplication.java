// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import com.example.dra.entity.Tables18NodesEntity;
import com.example.dra.service.CreateSQLTuningSetService;


@SpringBootApplication
public class DraApplication implements CommandLineRunner{

	@Autowired
    private JdbcTemplate jdbcTemplate;
	
	@Autowired
	CreateSQLTuningSetService createSQLTuningSetDao;

	public static void main(String[] args) {
		System.out.println("In main of DraApplication");
		SpringApplication.run(DraApplication.class, args);
	}
	
	public void run(String... args) throws Exception {
    	
    //	System.out.println("In run method of DataRefactoringAdvisorApplication");
    //	jdbcTemplate.query("SELECT * FROM TABLES_18_NODES", (RowMapper<Object>) (rs, i) -> new TABLES_18_NODES(rs.getString("TABLE_NAME")))
    //    .forEach(System.out::println);
    	
   // 	Tables18NodesEntity tables18Nodes =createSQLTuningSetDao.createSqlSet("abc");
    	
    //	System.out.println(tables18Nodes);
	}
}
