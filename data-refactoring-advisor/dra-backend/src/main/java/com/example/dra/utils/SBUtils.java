// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.utils;

import com.example.dra.bean.DatabaseDetails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

import org.springframework.beans.factory.annotation.Autowired;
@Configuration
public class SBUtils {

    @Autowired
    private Environment env;

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

    public DatabaseDetails setDatabaseDetails(DatabaseDetails databaseDetails) {
        System.out.println("App.props, hostname :: " + hostname);
        //System.out.println("Config  :: " + env.getProperty("spring.datasource.hostname"));
        databaseDetails.setHostname(hostname);
        databaseDetails.setPort(Integer.parseInt(port));
        databaseDetails.setServiceName(serviceName);
        databaseDetails.setUsername(username);
        databaseDetails.setPassword(password);
        return databaseDetails;
    }
}
