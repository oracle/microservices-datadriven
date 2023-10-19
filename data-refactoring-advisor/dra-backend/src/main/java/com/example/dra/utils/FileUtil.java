// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.utils;

import com.example.dra.bean.DatabaseDetails;
import com.example.dra.service.impl.CreateSQLTuningSetServiceImpl;
import com.example.dra.service.impl.DRAUtilsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

@Component
public class FileUtil {

    @Autowired
    DRAUtilsImpl draUtilsImpl;

    @Autowired
    ResourceLoader resourceLoader;

    //@Value("classpath:workload-simulate-queries.sql")
    //Resource resource;
    //@Value("${dra.load.sts.sql.file.path}")
    //String sqlFilePath;

    public List<String> readLoadStsSimulateFile(String sqlFilePath){
        List<String> lines = new ArrayList<>();
        try {
            System.out.println("sqlFilePath :: " + sqlFilePath);
            File file = new File(sqlFilePath);
            System.out.println("File Path :: " + file.getPath());
            lines = Files.readAllLines(Path.of(file.getPath()));
            lines.removeIf(s -> s.startsWith("--")); // Remove SQL Comments
            lines.removeIf(s -> s.isEmpty()); // Remove Empty lines
            System.out.println("Number of Queries :: "+lines.size());
        } catch (IOException e) {
            throw new RuntimeException(e);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return lines;
    }
    public static void main(String[] args) {
        List<String> lines = new FileUtil().readLoadStsSimulateFile("");
        for (String line : lines) {
            System.out.println("--- "+line);
        }

        DatabaseDetails databaseDetails = new FileUtil().getDummyDatabaseDetailsObj();
        new CreateSQLTuningSetServiceImpl().executeQueries(databaseDetails, lines);
    }

    private DatabaseDetails getDummyDatabaseDetailsObj() {
        DatabaseDetails databaseDetails = new DatabaseDetails();
        databaseDetails.setUrl(draUtilsImpl.formDbConnectionStr(databaseDetails));
        databaseDetails.setDatabaseName("medicalrecordsdb");
        databaseDetails.setPort(1511);
        databaseDetails.setHostname("adb.us-ashburn-1.oraclecloud.com");
        databaseDetails.setUsername("ADMIN");
        databaseDetails.setServiceName("xxx_medicalrecordsdb_high.adb.oraclecloud.com");
        return databaseDetails;
    }
}
