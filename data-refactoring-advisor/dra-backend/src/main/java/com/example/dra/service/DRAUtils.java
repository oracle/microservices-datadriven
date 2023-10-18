package com.example.dra.service;

import com.example.dra.bean.DatabaseDetails;

public interface DRAUtils {

    public DatabaseDetails setDatabaseDetails(DatabaseDetails databaseDetails);

    public String formDbConnectionStr(DatabaseDetails databaseDetails);
}
