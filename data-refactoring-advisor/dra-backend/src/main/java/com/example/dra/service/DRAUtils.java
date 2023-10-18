// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.service;

import com.example.dra.bean.DatabaseDetails;

public interface DRAUtils {

    public DatabaseDetails setDatabaseDetails(DatabaseDetails databaseDetails);

    public String formDbConnectionStr(DatabaseDetails databaseDetails);
}
