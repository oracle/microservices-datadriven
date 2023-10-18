package com.example.dra.service;

import com.example.dra.bean.DatabaseDetails;
import com.example.dra.dto.Tables18NodesDto;
import com.example.dra.entity.Tables18NodesEntity;

import java.util.List;

public interface CreateSQLTuningSetService {

	public Tables18NodesEntity createSqlSet(String sqlSetName);

	public List<Tables18NodesDto> getTableName();


	String createSQLTuningSet(DatabaseDetails databaseDetails);

	String loadSQLTuningSet(DatabaseDetails databaseDetails);

	String dropSQLTuningSet(DatabaseDetails databaseDetails);

	String collectSQLTuningSet(DatabaseDetails databaseDetails);

	List<String> getSQLTuningSetList(DatabaseDetails databaseDetails);

}
