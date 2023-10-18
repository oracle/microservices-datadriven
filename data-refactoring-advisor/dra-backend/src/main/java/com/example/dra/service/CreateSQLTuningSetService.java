// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

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
